//
//  FileScanner.swift
//  ModernClean
//
//  Sandbox-compatible file scanner for Mac App Store distribution
//

import Foundation
import Combine
import CryptoKit

@MainActor
class FileScanner: ObservableObject {
    static let shared = FileScanner()
    
    @Published var scannedFiles: [ScannedFile] = []
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var isScanning = false
    @Published var isScanningDuplicates = false
    @Published var currentScanPath = ""
    @Published var scanProgress: Double = 0
    @Published var duplicateScanProgress: Double = 0
    @Published var lastError: String?
    
    private var scanTask: Task<Void, Never>?
    private var duplicateScanTask: Task<Void, Never>?
    private var shouldStopScanning = false
    private var shouldStopDuplicateScan = false
    
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
    
    // MARK: - Duplicate Scanning
    
    func startDuplicateScan(path: String, minSize: Int64 = 1024) { // Default min 1KB to skip tiny files
        stopDuplicateScan()
        
        duplicateGroups.removeAll()
        isScanningDuplicates = true
        shouldStopDuplicateScan = false
        duplicateScanProgress = 0
        lastError = nil
        
        let scanner = BackgroundDuplicateScanner()
        duplicateScanTask = Task {
            await scanner.performDuplicateScan(
                path: path,
                minSize: minSize,
                shouldStop: { self.shouldStopDuplicateScan },
                onProgress: { progress, currentPath in
                    await MainActor.run {
                        self.duplicateScanProgress = progress
                        self.currentScanPath = currentPath
                    }
                },
                onGroupFound: { group in
                    await MainActor.run {
                        self.duplicateGroups.append(group)
                        // Sort by potential savings
                        self.duplicateGroups.sort { $0.potentialSavings > $1.potentialSavings }
                    }
                },
                onComplete: {
                    await MainActor.run {
                        self.isScanningDuplicates = false
                        self.currentScanPath = ""
                        self.duplicateScanProgress = 1.0
                    }
                },
                onError: { error in
                    await MainActor.run {
                        self.lastError = error
                        self.isScanningDuplicates = false
                    }
                }
            )
        }
    }
    
    func stopDuplicateScan() {
        shouldStopDuplicateScan = true
        duplicateScanTask?.cancel()
        duplicateScanTask = nil
        isScanningDuplicates = false
    }
    
    func deleteDuplicateFile(_ file: ScannedFile, from groupId: UUID) {
        // Delete the file
        deleteFileDirectly(file)
        
        // Update the duplicate group
        if let index = duplicateGroups.firstIndex(where: { $0.id == groupId }) {
            duplicateGroups[index].files.removeAll { $0.id == file.id }
            
            // Remove the group if only one file remains (no longer duplicates)
            if duplicateGroups[index].files.count <= 1 {
                duplicateGroups.remove(at: index)
            }
        }
    }
    
    func deleteAllDuplicatesInGroup(_ group: DuplicateGroup, keepFirst: Bool = true) {
        let filesToDelete = keepFirst ? Array(group.files.dropFirst()) : group.files
        
        for file in filesToDelete {
            deleteFileDirectly(file)
        }
        
        // Update or remove the group
        if let index = duplicateGroups.firstIndex(where: { $0.id == group.id }) {
            if keepFirst && !group.files.isEmpty {
                duplicateGroups[index].files = [group.files[0]]
                // Actually remove since only 1 file left
                duplicateGroups.remove(at: index)
            } else {
                duplicateGroups.remove(at: index)
            }
        }
    }
    
    private func deleteFileDirectly(_ file: ScannedFile) {
        let fileManager = FileManager.default
        
        do {
            try fileManager.trashItem(at: URL(fileURLWithPath: file.path), resultingItemURL: nil)
        } catch {
            do {
                try fileManager.removeItem(atPath: file.path)
            } catch {
                lastError = "Could not delete \(file.name): \(error.localizedDescription)"
            }
        }
    }
    
    var totalDuplicateSavings: Int64 {
        duplicateGroups.reduce(0) { $0 + $1.potentialSavings }
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

// MARK: - Background Duplicate Scanner Actor
// Scans for duplicate files using hash comparison

actor BackgroundDuplicateScanner {
    
    func performDuplicateScan(
        path: String,
        minSize: Int64,
        shouldStop: @escaping () -> Bool,
        onProgress: @escaping (Double, String) async -> Void,
        onGroupFound: @escaping (DuplicateGroup) async -> Void,
        onComplete: @escaping () async -> Void,
        onError: @escaping (String) async -> Void
    ) async {
        let fileManager = FileManager.default
        let rootURL = URL(fileURLWithPath: path)
        
        guard fileManager.isReadableFile(atPath: path) else {
            await onError("Cannot access \(path). Please grant folder access first.")
            return
        }
        
        // Phase 1: Collect all files and group by size (potential duplicates have same size)
        var filesBySize: [Int64: [URL]] = [:]
        var totalFiles = 0
        var processedFiles = 0
        
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isReadableKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else {
            await onError("Could not access \(path)")
            return
        }
        
        // First pass: count files and group by size
        var allFiles: [(URL, Int64)] = []
        
        for case let fileURL as URL in enumerator {
            if shouldStop() || Task.isCancelled { break }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                let isDirectory = resourceValues.isDirectory ?? false
                
                if !isDirectory {
                    let size = Int64(resourceValues.fileSize ?? 0)
                    if size >= minSize {
                        allFiles.append((fileURL, size))
                        filesBySize[size, default: []].append(fileURL)
                    }
                }
            } catch {
                continue
            }
            
            totalFiles += 1
            if totalFiles % 100 == 0 {
                await onProgress(0.1, fileURL.path) // First 10% is file enumeration
                await Task.yield()
            }
        }
        
        // Filter to only sizes with potential duplicates (more than 1 file)
        let potentialDuplicates = filesBySize.filter { $0.value.count > 1 }
        let totalToHash = potentialDuplicates.values.reduce(0) { $0 + $1.count }
        var hashedCount = 0
        
        // Phase 2: Hash files with matching sizes
        var filesByHash: [String: [(URL, Int64)]] = [:]
        
        for (size, urls) in potentialDuplicates {
            if shouldStop() || Task.isCancelled { break }
            
            for url in urls {
                if shouldStop() || Task.isCancelled { break }
                
                if let hash = await computeFileHash(url: url) {
                    filesByHash[hash, default: []].append((url, size))
                }
                
                hashedCount += 1
                let progress = 0.1 + (Double(hashedCount) / Double(max(1, totalToHash))) * 0.85
                
                if hashedCount % 10 == 0 {
                    await onProgress(progress, url.path)
                    await Task.yield()
                }
            }
        }
        
        // Phase 3: Create duplicate groups
        for (hash, files) in filesByHash {
            if files.count > 1 {
                let scannedFiles = files.map { (url, size) in
                    ScannedFile(
                        url: url,
                        size: size,
                        isDirectory: false,
                        modifiedDate: try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                        createdDate: try? url.resourceValues(forKeys: [.creationDateKey]).creationDate
                    )
                }
                
                let group = DuplicateGroup(
                    hash: hash,
                    size: files[0].1,
                    files: scannedFiles
                )
                
                await onGroupFound(group)
            }
        }
        
        await onProgress(1.0, "")
        await onComplete()
    }
    
    private func computeFileHash(url: URL) async -> String? {
        // Use partial hashing for large files (first 64KB + last 64KB + middle 64KB)
        // This is much faster while still being effective for duplicate detection
        
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        
        defer { try? fileHandle.close() }
        
        do {
            let fileSize = try fileHandle.seekToEnd()
            
            var hasher = SHA256()
            
            if fileSize <= 256 * 1024 { // Files <= 256KB: hash entire file
                try fileHandle.seek(toOffset: 0)
                if let data = try fileHandle.read(upToCount: Int(fileSize)) {
                    hasher.update(data: data)
                }
            } else {
                // Large files: sample beginning, middle, and end
                let chunkSize = 64 * 1024
                
                // Beginning
                try fileHandle.seek(toOffset: 0)
                if let beginData = try fileHandle.read(upToCount: chunkSize) {
                    hasher.update(data: beginData)
                }
                
                // Middle
                let middleOffset = fileSize / 2
                try fileHandle.seek(toOffset: middleOffset)
                if let middleData = try fileHandle.read(upToCount: chunkSize) {
                    hasher.update(data: middleData)
                }
                
                // End
                let endOffset = max(0, fileSize - UInt64(chunkSize))
                try fileHandle.seek(toOffset: endOffset)
                if let endData = try fileHandle.read(upToCount: chunkSize) {
                    hasher.update(data: endData)
                }
                
                // Also include file size in hash to reduce false positives
                var sizeBytes = fileSize
                hasher.update(data: Data(bytes: &sizeBytes, count: MemoryLayout<UInt64>.size))
            }
            
            let digest = hasher.finalize()
            return digest.compactMap { String(format: "%02x", $0) }.joined()
            
        } catch {
            return nil
        }
    }
}
