//
//  ContentView.swift
//  MacClean
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var fileScanner: FileScanner
    @State private var selectedFiles: Set<ScannedFile.ID> = []
    @State private var showingDeleteConfirmation = false
    @State private var showingUpgradeSheet = false
    @State private var searchPath = "/"
    @State private var minSizeGB: Double = 0.1
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            // Gradient background
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
                // Custom title bar
                TitleBarView()
                
                // Main content
                HStack(spacing: 0) {
                    // Sidebar
                    SidebarView(searchPath: $searchPath, onNavigate: navigateToPath)
                        .frame(width: 260)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1)
                    
                    // Main content area
                    VStack(spacing: 0) {
                        // Storage overview
                        StorageOverviewCard()
                            .padding()
                        
                        // Scan controls
                        ScanControlsView(
                            searchPath: $searchPath,
                            minSizeGB: $minSizeGB,
                            showingUpgradeSheet: $showingUpgradeSheet
                        )
                        .padding(.horizontal)
                        
                        // File list
                        FileListView(
                            selectedFiles: $selectedFiles,
                            showingDeleteConfirmation: $showingDeleteConfirmation,
                            currentPath: $searchPath,
                            onDrillDown: drillIntoFolder
                        )
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            UpgradeView()
                .environmentObject(storeManager)
        }
        .alert("Delete Selected Files?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedFiles()
            }
        } message: {
            Text("This action cannot be undone. \(selectedFiles.count) file(s) will be permanently deleted.")
        }
    }
    
    func drillIntoFolder(_ path: String) {
        // Clear selection when drilling into a new folder
        selectedFiles.removeAll()
        
        // Update the search path
        searchPath = path
        
        // Trigger a new scan for the folder
        // Note: Drilling down doesn't consume a free scan - only top-level scans do
        let minBytes = Int64(minSizeGB * 1024 * 1024 * 1024)
        fileScanner.startScanning(path: path, minSize: minBytes)
    }
    
    func navigateToPath(_ path: String) {
        selectedFiles.removeAll()
        searchPath = path
        
        // Start a fresh scan when clicking sidebar items
        let minBytes = Int64(minSizeGB * 1024 * 1024 * 1024)
        
        // Check if user has scans remaining or is pro
        if !storeManager.isPurchased && storeManager.remainingFreeScans <= 0 {
            showingUpgradeSheet = true
            return
        }
        
        // Use a scan if not pro
        if !storeManager.isPurchased {
            storeManager.useFreeScan()
        }
        
        fileScanner.startScanning(path: path, minSize: minBytes)
    }
    
    func deleteSelectedFiles() {
        let filesToDelete = fileScanner.scannedFiles.filter { selectedFiles.contains($0.id) }
        
        for file in filesToDelete {
            fileScanner.deleteFile(file)
        }
        
        selectedFiles.removeAll()
    }
}

struct TitleBarView: View {
    var body: some View {
        HStack {
            // Window controls space
            HStack(spacing: 8) {
                Circle().fill(Color(hex: "ff5f57")).frame(width: 12, height: 12)
                Circle().fill(Color(hex: "febc2e")).frame(width: 12, height: 12)
                Circle().fill(Color(hex: "28c840")).frame(width: 12, height: 12)
            }
            .padding(.leading, 20)
            
            Spacer()
            
            // App title
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "e94560"), Color(hex: "ff6b6b")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("MacClean")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Placeholder for symmetry
            HStack(spacing: 8) {
                Circle().fill(Color.clear).frame(width: 12, height: 12)
                Circle().fill(Color.clear).frame(width: 12, height: 12)
                Circle().fill(Color.clear).frame(width: 12, height: 12)
            }
            .padding(.trailing, 20)
        }
        .frame(height: 52)
        .background(Color.black.opacity(0.3))
    }
}

struct SidebarView: View {
    @Binding var searchPath: String
    let onNavigate: (String) -> Void
    @EnvironmentObject var storeManager: StoreManager
    
    let quickPaths: [(name: String, path: String, icon: String)] = [
        ("Entire System", "/", "internaldrive.fill"),
        ("Home Folder", FileManager.default.homeDirectoryForCurrentUser.path, "house.fill"),
        ("Downloads", FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").path, "arrow.down.circle.fill"),
        ("Documents", FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents").path, "doc.fill"),
        ("Applications", "/Applications", "app.fill"),
        ("Library Caches", FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches").path, "archivebox.fill"),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pro badge or free tier info
            if storeManager.isPurchased {
                ProBadge()
                    .padding()
            } else {
                FreeTierInfo()
                    .padding()
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Quick locations
            VStack(alignment: .leading, spacing: 4) {
                Text("QUICK LOCATIONS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                ForEach(quickPaths, id: \.path) { item in
                    SidebarButton(
                        icon: item.icon,
                        title: item.name,
                        isSelected: searchPath == item.path || searchPath.hasPrefix(item.path + "/")
                    ) {
                        onNavigate(item.path)
                    }
                }
            }
            
            Spacer()
            
            // Version info
            VStack(spacing: 4) {
                Text("MacClean v1.0")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                Text("Made with ❤️ for Mac")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)
        }
        .background(Color.black.opacity(0.2))
    }
}

struct SidebarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? Color(hex: "e94560") : .white.opacity(0.7))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "e94560").opacity(0.2) : (isHovering ? Color.white.opacity(0.05) : Color.clear))
                    .padding(.horizontal, 8)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct ProBadge: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "ffd700"), Color(hex: "ff8c00")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Pro Unlocked")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text("Unlimited Scans")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "ffd700").opacity(0.2), Color(hex: "ff8c00").opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "ffd700").opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct FreeTierInfo: View {
    @EnvironmentObject var storeManager: StoreManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "e94560"))
                
                Text("Free Scans")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(storeManager.remainingFreeScans)/5")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(storeManager.remainingFreeScans > 0 ? Color(hex: "28c840") : Color(hex: "ff5f57"))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "e94560"), Color(hex: "ff6b6b")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(storeManager.remainingFreeScans) / 5.0, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(StoreManager.shared)
        .environmentObject(FileScanner.shared)
}
