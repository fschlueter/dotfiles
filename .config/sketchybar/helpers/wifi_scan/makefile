# Builds bin/WifiScan.app (ad-hoc signed). Run by items*/widgets/wifi.lua at bar start.
APP = bin/WifiScan.app

$(APP)/Contents/MacOS/wifi_scan: main.swift Info.plist
	mkdir -p $(APP)/Contents/MacOS
	cp Info.plist $(APP)/Contents/Info.plist
	swiftc -O -o $@ main.swift -framework CoreWLAN -framework CoreLocation
	codesign --force --sign - $(APP)
