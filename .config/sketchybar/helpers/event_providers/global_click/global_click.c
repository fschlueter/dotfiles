// Triggers a sketchybar event on every mouse click anywhere on screen, so
// popups can close when the user clicks elsewhere.
// Usage: global_click "<event-name>"
// Event variables: x, y (global points, top-left origin), button (left/right/
// other) and on_bar (1 if the click hit a sketchybar window: the bar, an item
// or a popup; 0 otherwise).
#include <ApplicationServices/ApplicationServices.h>
#include "../sketchybar.h"

static char g_event[256];

// Whether the topmost on-screen window under `point` belongs to sketchybar.
static bool hits_sketchybar(CGPoint point) {
  CFArrayRef windows = CGWindowListCopyWindowInfo(
      kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
      kCGNullWindowID);
  if (!windows) return false;

  bool hit = false;
  CFIndex count = CFArrayGetCount(windows);
  for (CFIndex i = 0; i < count; i++) {
    CFDictionaryRef window = CFArrayGetValueAtIndex(windows, i);
    CFDictionaryRef bounds_ref = CFDictionaryGetValue(window, kCGWindowBounds);
    CGRect bounds;
    if (!bounds_ref || !CGRectMakeWithDictionaryRepresentation(bounds_ref, &bounds)) continue;
    if (!CGRectContainsPoint(bounds, point)) continue;

    // The list is ordered front to back: the first window containing the
    // point is the one clicked.
    CFStringRef owner = CFDictionaryGetValue(window, kCGWindowOwnerName);
    char name[256] = { 0 };
    if (owner) CFStringGetCString(owner, name, sizeof(name), kCFStringEncodingUTF8);
    hit = strcmp(name, "sketchybar") == 0;
    break;
  }
  CFRelease(windows);
  return hit;
}

static CGEventRef on_click(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void* info) {
  if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
    CGEventTapEnable(*(CFMachPortRef*)info, true);
    return event;
  }

  CGPoint point = CGEventGetLocation(event);
  const char* button = type == kCGEventLeftMouseDown ? "left"
                     : type == kCGEventRightMouseDown ? "right" : "other";
  char message[512];
  snprintf(message, sizeof(message), "--trigger '%s' x='%d' y='%d' button='%s' on_bar='%d'",
           g_event, (int)point.x, (int)point.y, button, hits_sketchybar(point) ? 1 : 0);
  sketchybar(message);
  return event;
}

int main(int argc, char** argv) {
  if (argc < 2) {
    printf("Usage: %s \"<event-name>\"\n", argv[0]);
    exit(1);
  }
  snprintf(g_event, sizeof(g_event), "%s", argv[1]);

  char add[512];
  snprintf(add, sizeof(add), "--add event '%s'", g_event);
  sketchybar(add);

  static CFMachPortRef tap;
  CGEventMask mask = CGEventMaskBit(kCGEventLeftMouseDown)
                   | CGEventMaskBit(kCGEventRightMouseDown)
                   | CGEventMaskBit(kCGEventOtherMouseDown);
  tap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap,
                         kCGEventTapOptionListenOnly, mask, on_click, &tap);
  if (!tap) {
    fprintf(stderr, "global_click: could not create the event tap (permission?)\n");
    return 1;
  }

  CFRunLoopSourceRef source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0);
  CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
  CGEventTapEnable(tap, true);
  CFRunLoopRun();
  return 0;
}
