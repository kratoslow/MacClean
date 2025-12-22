//
//  ScanControlsView.swift
//  MacCoolClean
//

import SwiftUI

struct ScanControlsView: View {
    @EnvironmentObject var fileScanner: FileScanner
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @Binding var searchPath: String
    @Binding var minSizeGB: Double
    @Binding var showingUpgradeSheet: Bool
    
    @State private var isHovering = false
    @State private var showingAccessAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Path display with access indicator
            HStack(spacing: 8) {
                Image(systemName: bookmarkManager.hasAccess(to: searchPath) ? "folder.fill" : "folder.badge.questionmark")
                    .foregroundColor(bookmarkManager.hasAccess(to: searchPath) ? Color(hex: "e94560") : Color(hex: "febc2e"))
                
                Text(searchPath)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                Button(action: selectFolder) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Choose folder to scan")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(bookmarkManager.hasAccess(to: searchPath) ? Color.white.opacity(0.1) : Color(hex: "febc2e").opacity(0.5), lineWidth: 1)
                    )
            )
            .frame(maxWidth: 300)
            
            // Min size slider
            HStack(spacing: 12) {
                Text("Min Size:")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                
                Slider(value: $minSizeGB, in: 0.01...10, step: 0.01)
                    .frame(width: 120)
                    .tint(Color(hex: "e94560"))
                
                Text(formatSize(minSizeGB))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.3))
            )
            
            Spacer()
            
            // Scan button
            Button(action: startScan) {
                HStack(spacing: 8) {
                    if fileScanner.isScanning {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Scanning...")
                    } else {
                        Image(systemName: "magnifyingglass")
                        Text("Scan for Large Files")
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: isHovering ? [Color(hex: "ff6b6b"), Color(hex: "e94560")] : [Color(hex: "e94560"), Color(hex: "c62a47")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color(hex: "e94560").opacity(0.4), radius: isHovering ? 12 : 6, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(fileScanner.isScanning)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            
            // Stop button (when scanning)
            if fileScanner.isScanning {
                Button(action: { fileScanner.stopScanning() }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color(hex: "ff5f57"))
                        )
                }
                .buttonStyle(.plain)
                .help("Stop scanning")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
        .alert("Folder Access Required", isPresented: $showingAccessAlert) {
            Button("Select Folder") {
                selectFolder()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To scan this folder, you need to grant access first. Click 'Select Folder' to choose a folder to scan.")
        }
    }
    
    func formatSize(_ gb: Double) -> String {
        if gb >= 1 {
            return String(format: "%.1f GB", gb)
        } else {
            return String(format: "%.0f MB", gb * 1024)
        }
    }
    
    func selectFolder() {
        if let url = bookmarkManager.requestFolderAccess(message: "Select a folder to scan for large files") {
            searchPath = url.path
        }
    }
    
    func startScan() {
        // Check if we have access to this path
        if !bookmarkManager.hasAccess(to: searchPath) {
            showingAccessAlert = true
            return
        }
        
        // Check if user has scans remaining or is pro
        if !storeManager.isPurchased && storeManager.remainingFreeScans <= 0 {
            showingUpgradeSheet = true
            return
        }
        
        // Use a scan if not pro
        if !storeManager.isPurchased {
            storeManager.useFreeScan()
        }
        
        // Start the scan
        let minBytes = Int64(minSizeGB * 1024 * 1024 * 1024)
        fileScanner.startScanning(path: searchPath, minSize: minBytes)
    }
}

#Preview {
    ScanControlsView(
        searchPath: .constant("/"),
        minSizeGB: .constant(0.1),
        showingUpgradeSheet: .constant(false)
    )
    .environmentObject(FileScanner.shared)
    .environmentObject(StoreManager.shared)
    .environmentObject(BookmarkManager.shared)
    .padding()
    .background(Color(hex: "1a1a2e"))
}
