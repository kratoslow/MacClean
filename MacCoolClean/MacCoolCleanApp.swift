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
    func applicationDidFinishLaunching(_ notification: Notification) {
        // App is sandboxed - folder access is granted per-folder via the Open Panel
        // No need to request Full Disk Access
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up security-scoped resource access
        Task { @MainActor in
            BookmarkManager.shared.stopAccessingAll()
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
