//
//  FileScanner.swift
//  MacCoolClean
//
//  Sandbox-compatible file scanner for Mac App Store distribution
//

import Foundation
import Combine

@MainActor
class FileScanner: ObservableObject {
    static let shared = FileScanner()
    
    @Published var scannedFiles: [ScannedFile] = []
    @Published var isScanning = false
    @Published var currentScanPath = ""
    @Published var scanProgress: Double = 0
    @Published var lastError: String?
    
    private var scanTask: Task<Void, Never>?
    private var shouldStopScanning = false
    
    private init() {}
    
    func startScanning(path: String, minSize: Int64) {
        // Cancel any existing scan
        stopScanning()
        
        // Reset state
        scannedFiles.removeAll()
        isScanning = true
        shouldStopScanning = false
        lastError = nil
        
        // Start background scan on a detached task (off main thread)
        let scanner = BackgroundScanner()
        scanTask = Task {
            await scanner.performScan(
                path: path,
                minSize: minSize,
                shouldStop: { self.shouldStopScanning },
                onFileFound: { file in
                    await MainActor.run {
                        self.scannedFiles.append(file)
                        self.scannedFiles.sort { $0.size > $1.size }
                        if self.scannedFiles.count > 1000 {
                            self.scannedFiles = Array(self.scannedFiles.prefix(1000))
                        }
                    }
                },
                onPathUpdate: { path in
                    await MainActor.run {
                        self.currentScanPath = path
                    }
                },
                onComplete: {
                    await MainActor.run {
                        self.isScanning = false
                        self.currentScanPath = ""
                    }
                },
                onError: { error in
                    await MainActor.run {
                        self.lastError = error
                        self.isScanning = false
                    }
                }
            )
        }
    }
    
    func stopScanning() {
        shouldStopScanning = true
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
    }
    
    func deleteFile(_ file: ScannedFile) {
        let fileManager = FileManager.default
        
        do {
            // In sandbox mode, we can only delete files the user has granted access to
            try fileManager.trashItem(at: URL(fileURLWithPath: file.path), resultingItemURL: nil)
            scannedFiles.removeAll { $0.id == file.id }
        } catch {
            // Try direct removal if trash fails
            do {
                try fileManager.removeItem(atPath: file.path)
                scannedFiles.removeAll { $0.id == file.id }
            } catch {
                lastError = "Could not delete \(file.name): \(error.localizedDescription)"
            }
        }
    }
    
    func deleteFiles(_ files: [ScannedFile]) {
        for file in files {
            deleteFile(file)
        }
    }
}

// MARK: - Background Scanner Actor
// This runs all heavy file system operations off the main thread

actor BackgroundScanner {
    
    func performScan(
        path: String,
        minSize: Int64,
        shouldStop: @escaping () -> Bool,
        onFileFound: @escaping (ScannedFile) async -> Void,
        onPathUpdate: @escaping (String) async -> Void,
        onComplete: @escaping () async -> Void,
        onError: @escaping (String) async -> Void
    ) async {
        let fileManager = FileManager.default
        let rootURL = URL(fileURLWithPath: path)
        
        // Check if we can read this path
        guard fileManager.isReadableFile(atPath: path) else {
            await onError("Cannot access \(path). Please grant folder access first.")
            return
        }
        
        // Use directory enumerator for recursive scanning
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [
                .fileSizeKey,
                .isDirectoryKey,
                .contentModificationDateKey,
                .creationDateKey,
                .isReadableKey,
                .totalFileAllocatedSizeKey
            ],
            options: [.skipsHiddenFiles],
            errorHandler: { url, error in
                // Skip directories we can't access (expected in sandbox)
                return true
            }
        ) else {
            await onError("Could not access \(path)")
            return
        }
        
        var scannedCount = 0
        
        for case let fileURL as URL in enumerator {
            // Check if we should stop
            if shouldStop() || Task.isCancelled {
                break
            }
            
            scannedCount += 1
            
            // Update UI periodically (every 50 files for responsiveness)
            if scannedCount % 50 == 0 {
                await onPathUpdate(fileURL.path)
                // Yield to allow UI updates
                await Task.yield()
            }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [
                    .fileSizeKey,
                    .isDirectoryKey,
                    .contentModificationDateKey,
                    .creationDateKey,
                    .totalFileAllocatedSizeKey
                ])
                
                let isDirectory = resourceValues.isDirectory ?? false
                
                // Get size - use allocated size for accuracy, fallback to file size
                var size: Int64 = 0
                
                if isDirectory {
                    // For directories, calculate total size in background
                    size = await calculateDirectorySize(at: fileURL, shouldStop: shouldStop)
                } else {
                    size = Int64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileSize ?? 0)
                }
                
                // Only include files/directories meeting minimum size
                if size >= minSize {
                    let file = ScannedFile(
                        url: fileURL,
                        size: size,
                        isDirectory: isDirectory,
                        modifiedDate: resourceValues.contentModificationDate,
                        createdDate: resourceValues.creationDate
                    )
                    
                    await onFileFound(file)
                    
                    // Skip directory contents if we already counted it
                    if isDirectory {
                        enumerator.skipDescendants()
                    }
                }
            } catch {
                // Skip files we can't read
                continue
            }
        }
        
        await onComplete()
    }
    
    private func calculateDirectorySize(at url: URL, shouldStop: @escaping () -> Bool) async -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        var count = 0
        for case let fileURL as URL in enumerator {
            if shouldStop() || Task.isCancelled {
                break
            }
            
            count += 1
            // Yield periodically to keep UI responsive
            if count % 100 == 0 {
                await Task.yield()
            }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
                totalSize += Int64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileSize ?? 0)
            } catch {
                continue
            }
        }
        
        return totalSize
    }
}
