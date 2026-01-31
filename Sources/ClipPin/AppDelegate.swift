import Cocoa
import SwiftUI
import ClipPinCore

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Use NSImage(named:) to automatically handle @2x resolution
            if let iconImage = NSImage(named: "MenuBarIcon") {
                iconImage.isTemplate = true
                button.image = iconImage
            } else {
                // Fallback
                button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipPin")
            }
            button.action = #selector(togglePopover(_:))
        }
        
        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400) // Match MenuView frame
        popover.behavior = .transient
        // Use MenuView
        popover.contentViewController = NSHostingController(rootView: MenuView())
        
        // Listen for preference changes from Core
        NotificationCenter.default.addObserver(self, selector: #selector(preferencesChanged(_:)), name: .clipPinPreferencesChanged, object: nil)
    }
    
    @objc func preferencesChanged(_ notification: Notification) {
        if let isPaused = notification.userInfo?["isPaused"] as? Bool {
            updateIcon(isPaused: isPaused)
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                closePopover(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                // Bring app to front so the popover is active
                NSApp.activate(ignoringOtherApps: true)
                
                // Monitor for clicks outside
                eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                    self?.closePopover(nil)
                }
            }
        }
    }
    
    @objc func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        // Remove monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    var aboutWindow: NSWindow?
    
    func updateIcon(isPaused: Bool) {
        if let button = statusItem.button {
            // Just use alpha for paused state with custom icon
            button.alphaValue = isPaused ? 0.5 : 1.0
        }
    }
    
    @objc func openAboutWindow() {
        if aboutWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 220),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered, defer: false
            )
            window.center()
            window.title = "About ClipPin"
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.contentView = NSHostingView(rootView: AboutView())
            window.isReleasedWhenClosed = false // Delegate handles it
            
            self.aboutWindow = window
        }
        
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
