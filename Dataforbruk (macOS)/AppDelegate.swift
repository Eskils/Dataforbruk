//
//  AppDelegate.swift
//  TMDataViewNIB
//
//  Created by Eskil Sviggum on 11/01/2022.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    
    var popover: NSPopover!
    var statusItem: NSStatusItem!
    var reachability = try? Reachability()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        appManager = AppManager()
        
        // Creating popover with ContentView
        let size = NSSize(width: 350, height: 582)
        let view = ContentView().frame(width: size.width, height: size.height)
        popover = NSPopover()
        popover.contentSize = size
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: view)
        
        // Creating status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(named: "DataUsage")!
        button.action = #selector(didPressStatusItem(_:))
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.systemDidGoToSleep(_:)), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.systemDidWakeUp(_:)), name: NSWorkspace.didWakeNotification, object: nil)
    }
    
    @objc func didPressStatusItem(_ sender: Any) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            guard let button = statusItem.button else { return }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.becomeKey()
        }
    }
    
    @objc func systemDidGoToSleep(_ sender: Any) {
        appManager.systemIsSleeping = true
    }
    
    @objc func systemDidWakeUp(_ sender: Any) {
        appManager.systemIsSleeping = false
        
        //TODO: Very ugly — should be cleaned up at some point
        if let reachability = reachability {
            let timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { timer in
                timer.invalidate()
                reachability.stopNotifier()
            }
            reachability.whenReachable = { _ in
                reachability.stopNotifier()
                timer.invalidate()
                self.fetchAfterWake()
            }
            do {
                try reachability.startNotifier()
            } catch {
                print(error)
                fetchAfterWake()
            }
        } else {
            fetchAfterWake()
        }
        
    }
    
    func fetchAfterWake() {
        if let lastFetchDate = appManager.lastUpdate {
            let date = Date()
            if lastFetchDate.distance(to: date) > appManager.interval {
                appManager.reinitTimer()
                appManager.fetchUsage()
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didWakeNotification, object: nil)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

