//
//  MacCoolCleanApp.swift
//  MacCoolClean
//
//  A beautiful macOS utility for cleaning up your Mac 😎
//

import SwiftUI
import StoreKit

@main
struct MacCoolCleanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var storeManager = StoreManager.shared
    @StateObject private var fileScanner = FileScanner.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storeManager)
                .environmentObject(fileScanner)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        MenuBarExtra {
            MenuBarView()
                .environmentObject(storeManager)
                .environmentObject(fileScanner)
        } label: {
            MenuBarIcon()
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request full disk access notification
        checkFullDiskAccess()
    }
    
    func checkFullDiskAccess() {
        let testPath = "/Users"
        let fileManager = FileManager.default
        
        do {
            _ = try fileManager.contentsOfDirectory(atPath: testPath)
        } catch {
            DispatchQueue.main.async {
                self.showFullDiskAccessAlert()
            }
        }
    }
    
    func showFullDiskAccessAlert() {
        let alert = NSAlert()
        alert.messageText = "Full Disk Access Required"
        alert.informativeText = "MacCoolClean needs Full Disk Access to scan all files on your Mac. Please enable it in System Settings > Privacy & Security > Full Disk Access."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                NSWorkspace.shared.open(url)
            }
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
