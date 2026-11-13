// Prefix mode like the old herdr TUI: ctrl-s (keys.json) opens this popup,
// the next key runs a command, Esc or ctrl-s again cancels.
// Logs each key to ~/cowork/scratchpad/prefix/events.log while that folder exists.

import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { run, props, closeOverlay, openOverlay, theme, spaces, panes, exec, home } from "herdr";

// Shifted digits on US and German layouts, for keyboards that report the typed character
const SHIFT_DIGITS = { "!": 1, "@": 2, "#": 3, "$": 4, "%": 5, "^": 6, "&": 7, "*": 8, "(": 9,
  '"': 2, "§": 3, "/": 7, ")": 9 };

const worktree = (action, width, height) => () => openOverlay({
  mod: "worktree", kind: "dialog", width, height,
  props: { space: spaces().find((s) => s.active)?.id, folder: panes().find((p) => p.focused)?.cwd, action },
});

// [key, label, action]; key is the plain key, or "shift-<key>"
const BINDINGS = [
  ["c", "new tab", () => run("tab.new", {})],
  ["n", "next tab", () => run("tab.next", {})],
  ["p", "previous tab", () => run("tab.prev", {})],
  ["shift-t", "rename tab", () => run("tab.rename", {})],
  ["shift-x", "close tab", () => run("tab.close", {})],
  ["v", "split right", () => run("pane.split", { direction: "right" })],
  ["-", "split down", () => run("pane.split", { direction: "down" })],
  ["h", "pane left", () => run("pane.go", { direction: "left" })],
  ["j", "pane down", () => run("pane.go", { direction: "down" })],
  ["k", "pane up", () => run("pane.go", { direction: "up" })],
  ["l", "pane right", () => run("pane.go", { direction: "right" })],
  ["x", "close pane", () => run("pane.close", {})],
  ["z", "zoom pane", () => run("pane.zoom", {})],
  ["shift-n", "new space", () => run("space.new", {})],
  ["shift-w", "rename space", () => run("space.rename", {})],
  ["shift-d", "close space", () => run("space.close", {})],
  ["shift-g", "new worktree", worktree("new", 460, 280)],
  ["w", "space picker", () => run("mod.open", { name: "picker" })],
  ["g", "commands", () => run("app.palette", {})],
  ["b", "sidebar", () => run("layout.toggle", { id: "sidebar" })],
  ["s", "settings", () => run("app.settings", {})],
  ["?", "keys help", () => run("app.help", {})],
];
const ALIASES = { minus: "-", left: "h", down: "j", up: "k", right: "l", "shift-/": "?", "shift-ß": "?" };

function log(line) {
  const dir = `${home()}/cowork/scratchpad/prefix`;
  exec("/bin/sh", ["-c", '[ -d "$1" ] && printf "%s\\n" "$2" >> "$1/events.log"; true', "sh", dir,
    `${new Date().toISOString()} ${line}`]).catch(() => {});
}

export default class Prefix extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
  }

  // Returns the action for a key event, or null
  lookup(e) {
    const shift = e.modifiers.shift;
    const digit = /^[1-9]$/.test(e.key) ? Number(e.key) : SHIFT_DIGITS[e.key_char ?? e.key];
    if (digit && (shift || !/^[1-9]$/.test(e.key)))
      return () => run("space.select", { index: digit });
    if (digit) return () => run("tab.select", { index: digit });
    let name = (shift ? "shift-" : "") + e.key;
    name = ALIASES[name] ?? name;
    if (e.key_char === "?") name = "?";
    return BINDINGS.find(([k]) => k === name)?.[2] ?? null;
  }

  render(cx) {
    const t = theme();
    const label = (k) => k.replace("shift-", "⇧");
    return v_flex()
      .id("prefix")
      .track_focus(this.handle)
      .on_key_down((e, cx) => {
        cx.stop_propagation();
        // Bare modifier presses (shift held before the key) are not a choice yet
        if (["shift", "control", "alt", "platform", "function"].includes(e.key)) return;
        const action = e.key === "escape" || e.keystroke === "ctrl-s" ? null : this.lookup(e);
        log(`keystroke=${e.keystroke} key=${e.key} key_char=${e.key_char ?? ""} -> ${action ? "run" : "cancel"}`);
        closeOverlay(props().overlay);
        if (action) action();
      })
      .size_full()
      .p(14)
      .gap(8)
      .rounded(8)
      .bg(t.popover)
      .text_size(12)
      .child(h_flex().child(div().flex_1().font_semibold().text_color(t.accent).child("prefix"))
        .child(div().text_color(t.dim).child("Esc cancels")))
      .child(h_flex().flex_wrap().gap(6).children([
        ...BINDINGS.map(([k, what]) => h_flex().w(150).gap(6)
          .child(div().w(28).text_color(t.foreground).child(label(k)))
          .child(div().text_color(t.muted).child(what))),
        h_flex().w(150).gap(6).child(div().w(28).text_color(t.foreground).child("1-9"))
          .child(div().text_color(t.muted).child("tab N")),
        h_flex().w(150).gap(6).child(div().w(28).text_color(t.foreground).child("⇧1-9"))
          .child(div().text_color(t.muted).child("space N")),
      ]));
  }
}
