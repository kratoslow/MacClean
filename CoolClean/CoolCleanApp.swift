//
//  CoolCleanApp.swift
//  CoolClean
//
//  A beautiful macOS utility for cleaning up your disk 😎
//

import SwiftUI
import StoreKit

@main
struct CoolCleanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var storeManager = StoreManager.shared
    @StateObject private var fileScanner = FileScanner.shared
    @StateObject private var bookmarkManager = BookmarkManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storeManager)
                .environmentObject(fileScanner)
                .environmentObject(bookmarkManager)
                .frame(minWidth: 1000, minHeight: 700)
                .frame(idealWidth: 1200, idealHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        
        MenuBarExtra {
            MenuBarView()
                .environmentObject(storeManager)
                .environmentObject(fileScanner)
                .environmentObject(bookmarkManager)
        } label: {
            MenuBarIcon()
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        // App is sandboxed - folder access is granted per-folder via the Open Panel
        // No need to request Full Disk Access
        
        // Hidden debug shortcut: Control+Shift+R to reset free scans
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Control + Shift + R
            if event.modifierFlags.contains([.control, .shift]) && event.charactersIgnoringModifiers == "r" {
                Task { @MainActor in
                    StoreManager.shared.resetFreeScans()
                }
                return nil // Consume the event
            }
            return event
        }
        
        // Ensure app is a regular foreground app
        NSApp.setActivationPolicy(.regular)
        
        // Activate immediately
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Capture the main window reference and bring app to foreground after window is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.mainWindow = NSApplication.shared.windows.first(where: { $0.level == .normal })
            
            // Activate again and bring window to front
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let window = self.mainWindow {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up security-scoped resource access
        Task { @MainActor in
            BookmarkManager.shared.stopAccessingAll()
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When dock icon is clicked or app is reopened, show the main window
        showMainWindow()
        return true
    }
    
    @objc func showMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Try to find and show the main window
        if let window = mainWindow, window.isVisible == false {
            window.makeKeyAndOrderFront(nil)
        } else if let window = NSApplication.shared.windows.first(where: { $0.level == .normal }) {
            window.makeKeyAndOrderFront(nil)
            mainWindow = window
        } else {
            // No window exists, create a new one by unhiding
            NSApp.unhide(nil)
        }
    }
}

struct MenuBarIcon: View {
    @State private var usedPercentage: Double = 0
    
    var body: some View {
        Image(systemName: iconName)
            .symbolRenderingMode(.hierarchical)
            .onAppear {
                updateStorageInfo()
            }
    }
    
    var iconName: String {
        if usedPercentage > 90 {
            return "externaldrive.fill.badge.exclamationmark"
        } else if usedPercentage > 70 {
            return "externaldrive.fill.badge.minus"
        } else {
            return "externaldrive.fill.badge.checkmark"
        }
    }
    
    func updateStorageInfo() {
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
           let totalSize = attributes[.systemSize] as? Int64,
           let freeSize = attributes[.systemFreeSize] as? Int64 {
            let usedSize = totalSize - freeSize
            usedPercentage = Double(usedSize) / Double(totalSize) * 100
        }
    }
}
