// Prints the bounding rectangle "x,y,w,h" (points, main display) of all visible sketchybar
// windows: the bar, its items and any open popup. Used by barshot.sh.
// Run: swift bar_rect.swift
import CoreGraphics
import Foundation

let display = CGDisplayBounds(CGMainDisplayID())
let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []

var union = CGRect.null
for window in info {
    guard window[kCGWindowOwnerName as String] as? String == "sketchybar",
          let dict = window[kCGWindowBounds as String] as? NSDictionary,
          let bounds = CGRect(dictionaryRepresentation: dict) else { continue }
    // hidden items are parked far off screen; the bar overhangs the edges
    let visible = bounds.intersection(display)
    if !visible.isNull && visible.width > 0 && visible.height > 0 { union = union.union(visible) }
}

guard !union.isNull else {
    FileHandle.standardError.write("bar_rect: no visible sketchybar window\n".data(using: .utf8)!)
    exit(1)
}
print("\(Int(union.minX)),\(Int(union.minY)),\(Int(union.width.rounded(.up))),\(Int(union.height.rounded(.up)))")
