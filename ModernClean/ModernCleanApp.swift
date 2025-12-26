//
//  ModernCleanApp.swift
//  ModernClean
//
//  A beautiful macOS utility for cleaning up your disk 😎
//

import SwiftUI
import StoreKit

@main
struct ModernCleanApp: App {
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
        
        // Bring app to foreground with retry logic
        bringAppToForeground(attempt: 1)
    }
    
    private func bringAppToForeground(attempt: Int) {
        // Try up to 5 times with increasing delays
        guard attempt <= 5 else { return }
        
        let delay = Double(attempt) * 0.2 // 0.2, 0.4, 0.6, 0.8, 1.0 seconds
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Activate the application
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            // Find the main window - try multiple approaches
            let window = NSApplication.shared.mainWindow 
                ?? NSApplication.shared.keyWindow
                ?? NSApplication.shared.windows.first(where: { $0.isVisible && $0.canBecomeKey })
                ?? NSApplication.shared.windows.first
            
            if let window = window {
                self.mainWindow = window
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                
                // Force the app to be frontmost
                NSApplication.shared.activate(ignoringOtherApps: true)
            } else {
                // Window not ready yet, try again
                self.bringAppToForeground(attempt: attempt + 1)
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
