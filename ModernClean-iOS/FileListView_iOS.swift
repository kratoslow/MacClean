//
//  FileListView_iOS.swift
//  ModernClean (iOS)
//
//  iOS file list with swipe actions
//

import SwiftUI

struct FileListView_iOS: View {
    @EnvironmentObject var fileScanner: FileScanner
    
    @State private var selectedFiles: Set<ScannedFile.ID> = []
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Scanning progress
            if fileScanner.isScanning {
                ScanningProgressView_iOS()
            }
            
            // Results header
            if !fileScanner.scannedFiles.isEmpty {
                HStack {
                    Text("\(fileScanner.scannedFiles.count) files found")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("Total: \(formatBytes(totalSize))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(hex: "e94560"))
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // File list
            List {
                ForEach(fileScanner.scannedFiles) { file in
                    FileRow_iOS(file: file, isSelected: selectedFiles.contains(file.id))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleSelection(file)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                fileScanner.deleteFile(file)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowBackground(
                            selectedFiles.contains(file.id) 
                                ? Color(hex: "e94560").opacity(0.2) 
                                : Color.white.opacity(0.02)
                        )
                        .listRowSeparatorTint(Color.white.opacity(0.1))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            
            // Selection toolbar
            if !selectedFiles.isEmpty {
                SelectionToolbar_iOS(
                    count: selectedFiles.count,
                    onDelete: { showingDeleteConfirmation = true },
                    onClear: { selectedFiles.removeAll() }
                )
            }
        }
        .alert("Delete Selected Files?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedFiles()
            }
        } message: {
            Text("This action cannot be undone. \(selectedFiles.count) file(s) will be deleted.")
        }
    }
    
    var totalSize: Int64 {
        fileScanner.scannedFiles.reduce(0) { $0 + $1.size }
    }
    
    func toggleSelection(_ file: ScannedFile) {
        if selectedFiles.contains(file.id) {
            selectedFiles.remove(file.id)
        } else {
            selectedFiles.insert(file.id)
        }
    }
    
    func deleteSelectedFiles() {
        let filesToDelete = fileScanner.scannedFiles.filter { selectedFiles.contains($0.id) }
        for file in filesToDelete {
            fileScanner.deleteFile(file)
        }
        selectedFiles.removeAll()
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - File Row

struct FileRow_iOS: View {
    let file: ScannedFile
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // File icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(fileColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: fileIcon)
                    .font(.system(size: 20))
                    .foregroundColor(fileColor)
            }
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(formatBytes(file.size))
                        .font(.caption)
                        .foregroundColor(Color(hex: "e94560"))
                    
                    if file.isDirectory {
                        Text("Folder")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            
            Spacer()
            
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "e94560"))
            }
        }
        .padding(.vertical, 4)
    }
    
    var fileIcon: String {
        if file.isDirectory {
            return "folder.fill"
        }
        
        let ext = (file.name as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4", "mov", "avi", "mkv":
            return "film.fill"
        case "mp3", "wav", "m4a", "aac":
            return "music.note"
        case "jpg", "jpeg", "png", "gif", "heic":
            return "photo.fill"
        case "pdf":
            return "doc.fill"
        case "zip", "tar", "gz", "rar":
            return "archivebox.fill"
        case "dmg", "pkg":
            return "shippingbox.fill"
        default:
            return "doc.fill"
        }
    }
    
    var fileColor: Color {
        if file.isDirectory {
            return Color(hex: "febc2e")
        }
        
        let ext = (file.name as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4", "mov", "avi", "mkv":
            return Color(hex: "a855f7")
        case "mp3", "wav", "m4a", "aac":
            return Color(hex: "ec4899")
        case "jpg", "jpeg", "png", "gif", "heic":
            return Color(hex: "3b82f6")
        case "pdf":
            return Color(hex: "ef4444")
        case "zip", "tar", "gz", "rar":
            return Color(hex: "f97316")
        case "dmg", "pkg":
            return Color(hex: "10b981")
        default:
            return Color(hex: "6b7280")
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Scanning Progress

struct ScanningProgressView_iOS: View {
    @EnvironmentObject var fileScanner: FileScanner
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ProgressView()
                    .tint(Color(hex: "e94560"))
                
                Text("Scanning...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Button("Stop") {
                    fileScanner.stopScanning()
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color(hex: "e94560"))
            }
            
            
            if !fileScanner.currentScanPath.isEmpty {
                Text(fileScanner.currentScanPath)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
    }
}

// MARK: - Selection Toolbar

struct SelectionToolbar_iOS: View {
    let count: Int
    let onDelete: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onClear) {
                Text("Clear")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("\(count) selected")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: onDelete) {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text("Delete")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "e94560"))
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
}

#Preview {
    FileListView_iOS()
        .environmentObject(FileScanner.shared)
        .background(Color(hex: "1a1a2e"))
}
