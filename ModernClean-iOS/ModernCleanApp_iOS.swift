//
//  ModernCleanApp_iOS.swift
//  ModernClean (iOS)
//
//  iOS App entry point
//

import SwiftUI
import StoreKit

@main
struct ModernCleanApp_iOS: App {
    @StateObject private var storeManager = StoreManager.shared
    @StateObject private var fileScanner = FileScanner.shared
    @StateObject private var folderAccessManager = FolderAccessManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView_iOS()
                .environmentObject(storeManager)
                .environmentObject(fileScanner)
                .environmentObject(folderAccessManager)
                .preferredColorScheme(.dark)
        }
    }
}
