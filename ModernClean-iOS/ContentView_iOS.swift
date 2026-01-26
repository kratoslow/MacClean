//
//  ContentView_iOS.swift
//  ModernClean (iOS)
//
//  Main content view with tab navigation for iOS
//

import SwiftUI

enum iOSScanMode: String, CaseIterable {
    case largeFiles = "Large Files"
    case duplicates = "Duplicates"
    
    var icon: String {
        switch self {
        case .largeFiles: return "externaldrive.fill"
        case .duplicates: return "doc.on.doc.fill"
        }
    }
}

struct ContentView_iOS: View {
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var fileScanner: FileScanner
    @EnvironmentObject var folderAccessManager: FolderAccessManager
    
    @State private var selectedTab: Tab = .scan
    @State private var showingUpgradeSheet = false
    @State private var showingFolderPicker = false
    @State private var selectedFolderURL: URL?
    
    enum Tab: Hashable {
        case scan
        case duplicates
        case settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ScanTab_iOS()
                .tabItem {
                    Label("Scan", systemImage: "magnifyingglass")
                }
                .tag(Tab.scan)
            
            DuplicatesTab_iOS()
                .tabItem {
                    Label("Duplicates", systemImage: "doc.on.doc")
                }
                .tag(Tab.duplicates)
            
            SettingsTab_iOS()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .accentColor(Color(hex: "e94560"))
        .sheet(isPresented: $showingUpgradeSheet) {
            UpgradeView_iOS()
                .environmentObject(storeManager)
        }
    }
}

// MARK: - Scan Tab

struct ScanTab_iOS: View {
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var fileScanner: FileScanner
    @EnvironmentObject var folderAccessManager: FolderAccessManager
    
    @State private var showingFolderPicker = false
    @State private var selectedFolderURL: URL?
    @State private var minSizeGB: Double = 0.1
    @State private var showingUpgradeSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "1a1a2e"),
                        Color(hex: "16213e"),
                        Color(hex: "0f3460")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Storage overview
                    StorageOverviewCard_iOS()
                        .padding()
                    
                    if folderAccessManager.accessibleFolders.isEmpty {
                        // Onboarding
                        OnboardingView_iOS(onFolderSelected: { url in
                            selectedFolderURL = url
                        })
                    } else if fileScanner.scannedFiles.isEmpty && !fileScanner.isScanning {
                        // Ready to scan
                        ReadyToScanView_iOS(
                            selectedFolder: selectedFolderURL ?? folderAccessManager.accessibleFolders.first,
                            minSizeGB: $minSizeGB,
                            onScan: startScan,
                            onPickFolder: { showingFolderPicker = true }
                        )
                    } else {
                        // File list
                        FileListView_iOS()
                    }
                }
            }
            .navigationTitle("ModernClean")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !storeManager.isPurchased {
                        Button {
                            showingUpgradeSheet = true
                        } label: {
                            Image(systemName: "crown.fill")
                                .foregroundColor(Color(hex: "ffd700"))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingFolderPicker) {
            FolderPickerView { url in
                selectedFolderURL = url
                showingFolderPicker = false
            }
            .environmentObject(folderAccessManager)
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            UpgradeView_iOS()
                .environmentObject(storeManager)
        }
    }
    
    func startScan() {
        guard let url = selectedFolderURL ?? folderAccessManager.accessibleFolders.first else { return }
        
        // Check if user can scan
        if !storeManager.canScan() {
            showingUpgradeSheet = true
            return
        }
        
        // Use a free scan if not purchased
        if !storeManager.isPurchased {
            storeManager.useFreeScan()
        }
        
        let minBytes = Int64(minSizeGB * 1024 * 1024 * 1024)
        fileScanner.startScanning(path: url.path, minSize: minBytes)
    }
}

// MARK: - Ready to Scan View

struct ReadyToScanView_iOS: View {
    let selectedFolder: URL?
    @Binding var minSizeGB: Double
    let onScan: () -> Void
    let onPickFolder: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Folder icon
            ZStack {
                Circle()
                    .fill(Color(hex: "e94560").opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "folder.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "e94560"))
            }
            
            // Selected folder
            VStack(spacing: 8) {
                Text("Ready to Scan")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                if let folder = selectedFolder {
                    Button(action: onPickFolder) {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text(folder.lastPathComponent)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            
            // Min size slider
            VStack(spacing: 8) {
                Text("Minimum file size: \(String(format: "%.1f", minSizeGB)) GB")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Slider(value: $minSizeGB, in: 0.01...5.0)
                    .accentColor(Color(hex: "e94560"))
                    .padding(.horizontal, 40)
            }
            
            // Scan button
            Button(action: onScan) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Scan for Large Files")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color(hex: "e94560"), Color(hex: "c62a47")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding View

struct OnboardingView_iOS: View {
    @EnvironmentObject var folderAccessManager: FolderAccessManager
    var onFolderSelected: ((URL) -> Void)?
    
    @State private var showingPicker = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "e94560").opacity(0.2), Color(hex: "e94560").opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "e94560"), Color(hex: "ff6b6b")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("Grant Folder Access")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("ModernClean needs your permission to scan folders.\nSelect a folder from Files to get started.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Grant access button
            Button(action: { showingPicker = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "folder.badge.plus")
                    Text("Choose Folder to Scan")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "e94560"), Color(hex: "c62a47")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color(hex: "e94560").opacity(0.4), radius: 8, y: 4)
            }
            
            // Privacy info
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield")
                        .font(.caption)
                    Text("Your privacy is protected")
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(.white.opacity(0.5))
                
                Text("Files are only scanned locally on your device.\nNothing is uploaded to any server.")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding(40)
        .sheet(isPresented: $showingPicker) {
            FolderPickerView { url in
                onFolderSelected?(url)
                showingPicker = false
            }
            .environmentObject(folderAccessManager)
        }
    }
}

// MARK: - Duplicates Tab

struct DuplicatesTab_iOS: View {
    @EnvironmentObject var fileScanner: FileScanner
    @EnvironmentObject var folderAccessManager: FolderAccessManager
    @EnvironmentObject var storeManager: StoreManager
    
    @State private var showingFolderPicker = false
    @State private var showingUpgradeSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "1a1a2e"),
                        Color(hex: "16213e"),
                        Color(hex: "0f3460")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if fileScanner.duplicateGroups.isEmpty && !fileScanner.isScanningDuplicates {
                    // Empty state
                    VStack(spacing: 24) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color(hex: "a855f7").opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: "a855f7"))
                        }
                        
                        VStack(spacing: 8) {
                            Text("Find Duplicate Files")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("Scan a folder to find duplicate files\nand reclaim storage space.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: startDuplicateScan) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Scan for Duplicates")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "a855f7"), Color(hex: "6366f1")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Spacer()
                    }
                } else {
                    DuplicatesListView_iOS()
                }
            }
            .navigationTitle("Duplicates")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingFolderPicker) {
            FolderPickerView { _ in
                showingFolderPicker = false
                startDuplicateScan()
            }
            .environmentObject(folderAccessManager)
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            UpgradeView_iOS()
                .environmentObject(storeManager)
        }
    }
    
    func startDuplicateScan() {
        if folderAccessManager.accessibleFolders.isEmpty {
            showingFolderPicker = true
            return
        }
        
        if !storeManager.canScan() {
            showingUpgradeSheet = true
            return
        }
        
        if !storeManager.isPurchased {
            storeManager.useFreeScan()
        }
        
        if let url = folderAccessManager.accessibleFolders.first {
            fileScanner.startDuplicateScan(path: url.path)
        }
    }
}

// MARK: - Settings Tab

struct SettingsTab_iOS: View {
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var folderAccessManager: FolderAccessManager
    
    @State private var showingUpgradeSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "1a1a2e"),
                        Color(hex: "16213e"),
                        Color(hex: "0f3460")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                List {
                    // Pro Section
                    Section {
                        if storeManager.isPurchased {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(Color(hex: "ffd700"))
                                Text("Pro Unlocked")
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "28c840"))
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        } else {
                            Button {
                                showingUpgradeSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(Color(hex: "ffd700"))
                                    VStack(alignment: .leading) {
                                        Text("Upgrade to Pro")
                                            .foregroundColor(.white)
                                        Text("\(storeManager.remainingFreeScans) free scans remaining")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                        
                        Button {
                            Task {
                                try? await storeManager.restorePurchases()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(Color(hex: "e94560"))
                                Text("Restore Purchases")
                                    .foregroundColor(.white)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    } header: {
                        Text("Subscription")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Accessible Folders
                    Section {
                        ForEach(folderAccessManager.accessibleFolders, id: \.self) { folder in
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(Color(hex: "e94560"))
                                Text(folderAccessManager.displayName(for: folder))
                                    .foregroundColor(.white)
                                Spacer()
                                Button {
                                    folderAccessManager.removeBookmark(for: folder)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                        
                        if folderAccessManager.accessibleFolders.isEmpty {
                            Text("No folders added yet")
                                .foregroundColor(.white.opacity(0.5))
                                .listRowBackground(Color.white.opacity(0.05))
                        }
                    } header: {
                        Text("Accessible Folders")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // About
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                        
                        HStack {
                            Text("Made with ❤️")
                                .foregroundColor(.white)
                            Spacer()
                            Text("iDevelopment LLC")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    } header: {
                        Text("About")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            UpgradeView_iOS()
                .environmentObject(storeManager)
        }
    }
}

#Preview {
    ContentView_iOS()
        .environmentObject(StoreManager.shared)
        .environmentObject(FileScanner.shared)
        .environmentObject(FolderAccessManager.shared)
}
