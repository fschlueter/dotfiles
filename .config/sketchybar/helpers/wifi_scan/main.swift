// wifi_scan: current SSID and nearby Wi-Fi networks for the sketchybar Wi-Fi popup.
// See README.md (why an app bundle, Location Services, launching through `open`).
//
// Output, tab separated:
//   current\t<ssid>                                   (empty when not connected)
//   net\t<ssid>\t<rssi dBm>\t<secure 0|1>\t<saved 0|1>  (one per SSID, strongest first)
// Flags: --current  skip the scan (it takes ~3 s)
//        --authorize  ask for Location Services permission, print the status, exit
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

if CommandLine.arguments.contains("--authorize") {
  let auth = Auth()
  auth.request()
  // CLAuthorizationStatus: 0 not determined, 1 restricted, 2 denied, 3 authorized
  print("location authorization status: \(auth.manager.authorizationStatus.rawValue)")
  exit(0)
}

guard let iface = CWWiFiClient.shared().interface() else { exit(1) }
// ssid() is nil without permission and when not connected
print("current\t\(iface.ssid() ?? "")")
if CommandLine.arguments.contains("--current") { exit(0) }

let profiles = iface.configuration()?.networkProfiles.array as? [CWNetworkProfile] ?? []
let saved = Set(profiles.compactMap { $0.ssid })
let networks = (try? iface.scanForNetworks(withSSID: nil)) ?? []

// One entry per SSID (several access points / bands share one), keeping the strongest.
var best: [String: CWNetwork] = [:]
for n in networks {
  guard let ssid = n.ssid, !ssid.isEmpty else { continue }
  if let b = best[ssid], b.rssiValue >= n.rssiValue { continue }
  best[ssid] = n
}
for n in best.values.sorted(by: { $0.rssiValue > $1.rssiValue }) {
  let ssid = n.ssid!
  let secure = n.supportsSecurity(.none) ? 0 : 1
  print("net\t\(ssid)\t\(n.rssiValue)\t\(secure)\t\(saved.contains(ssid) ? 1 : 0)")
}
