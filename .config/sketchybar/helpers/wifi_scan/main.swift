// wifi_scan: Wi-Fi state for the sketchybar Wi-Fi item.
// See README.md (why an app bundle, Location Services, launching through `open`).
//
// Flags:
//   --watch <sketchybar> <pid>  stay running; on every change of power, SSID or signal level run
//                               `<sketchybar> --trigger wifi_state STATE=on|off SSID=<ssid> RSSI=<dBm>
//                               LEVEL=<0-4>` (SSID empty, LEVEL 0 when not connected); exit when
//                               process <pid> exits. Debug log: see log() below.
//   --authorize                 ask for Location Services permission, print the status, exit
//   (none)                      print the current state once, tab separated: <state>\t<ssid>\t<rssi>
import CoreLocation
import CoreWLAN
import Foundation

final class Auth: NSObject, CLLocationManagerDelegate {
  let manager = CLLocationManager()
  var done = false

  // Shows the permission dialog if not decided yet and waits (max. 60 s) for the answer.
  func request() {
    manager.delegate = self
    guard manager.authorizationStatus == .notDetermined else { return }
    manager.requestWhenInUseAuthorization()
    let deadline = Date().addingTimeInterval(60)
    while !done && Date() < deadline {
      RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }
  }

  func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
    if m.authorizationStatus != .notDetermined { done = true }
  }
}

struct State: Equatable {
  var on: Bool
  var ssid: String  // empty when not connected (or without permission)
  var rssi: Int

  static func current() -> State {
    guard let iface = CWWiFiClient.shared().interface() else {
      return State(on: false, ssid: "", rssi: 0)
    }
    let ssid = iface.ssid() ?? ""
    return State(on: iface.powerOn(), ssid: ssid, rssi: ssid.isEmpty ? 0 : iface.rssiValue())
  }

  // Signal bars 0-4; only a change of level is reported.
  var level: Int {
    if ssid.isEmpty { return 0 }
    return rssi >= -55 ? 4 : rssi >= -67 ? 3 : rssi >= -75 ? 2 : 1
  }

  func same(_ o: State) -> Bool { on == o.on && ssid == o.ssid && level == o.level }
}

// Debug log, written only while ~/cowork/scratchpad/sketchybar-wifi/ exists.
let logURL = FileManager.default.homeDirectoryForCurrentUser
  .appendingPathComponent("cowork/scratchpad/sketchybar-wifi/events.log")
func log(_ msg: String) {
  guard FileManager.default.fileExists(atPath: logURL.deletingLastPathComponent().path) else { return }
  let line = "\(Date()) \(msg)\n".data(using: .utf8)!
  if let h = try? FileHandle(forWritingTo: logURL) {
    h.seekToEndOfFile(); h.write(line); h.closeFile()
  } else {
    try? line.write(to: logURL)
  }
}

final class Watcher: NSObject, CWEventDelegate {
  let client = CWWiFiClient.shared()
  let bar: String
  let queue = DispatchQueue(label: "wifi_scan.watch")
  var last: State?

  init(bar: String) {
    self.bar = bar
    super.init()
    client.delegate = self
    for e: CWEventType in [.powerDidChange, .ssidDidChange, .linkDidChange, .linkQualityDidChange] {
      do { try client.startMonitoringEvent(with: e) } catch { log("monitor \(e.rawValue) failed: \(error)") }
    }
    log("watching, bar=\(bar)")
    // linkQualityDidChange was never delivered on macOS 26: read the signal every 10 s
    // (in-process, sketchybar only hears about level changes).
    Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in self?.update() }
    update()
  }

  // CoreWLAN calls the delegate on its own threads: serialize.
  func update() {
    queue.async {
      let s = State.current()
      if let l = self.last, l.same(s) { return }
      log("state on=\(s.on) ssid=\(s.ssid) rssi=\(s.rssi) level=\(s.level)")
      self.last = s
      let p = Process()
      p.executableURL = URL(fileURLWithPath: self.bar)
      p.arguments = ["--trigger", "wifi_state", "STATE=\(s.on ? "on" : "off")", "SSID=\(s.ssid)", "RSSI=\(s.rssi)", "LEVEL=\(s.level)"]
      do { try p.run(); p.waitUntilExit(); log("trigger exit \(p.terminationStatus)") } catch { log("trigger failed: \(error)") }
    }
  }

  func powerStateDidChangeForWiFiInterface(withName interfaceName: String) { log("event \(#function)"); update() }
  func ssidDidChangeForWiFiInterface(withName interfaceName: String) { log("event \(#function)"); update() }
  func linkDidChangeForWiFiInterface(withName interfaceName: String) { log("event \(#function)"); update() }
  func linkQualityDidChangeForWiFiInterface(withName interfaceName: String, rssi: Int, transmitRate: Double) { log("event linkQuality \(rssi)"); update() }
}

let args = CommandLine.arguments

if args.contains("--authorize") {
  let auth = Auth()
  auth.request()
  // CLAuthorizationStatus: 0 not determined, 1 restricted, 2 denied, 3 authorized
  print("location authorization status: \(auth.manager.authorizationStatus.rawValue)")
  exit(0)
}

if let i = args.firstIndex(of: "--watch") {
  guard i + 2 < args.count, let pid = Int32(args[i + 2]), kill(pid, 0) == 0 else {
    FileHandle.standardError.write("usage: wifi_scan --watch <sketchybar> <pid of a running process>\n".data(using: .utf8)!)
    exit(2)
  }
  let watcher = Watcher(bar: args[i + 1])
  let exitSource = DispatchSource.makeProcessSource(identifier: pid, eventMask: .exit, queue: .main)
  exitSource.setEventHandler { exit(0) }
  exitSource.resume()
  withExtendedLifetime((watcher, exitSource)) { RunLoop.main.run() }
}

let s = State.current()
print("\(s.on ? "on" : "off")\t\(s.ssid)\t\(s.rssi)")
