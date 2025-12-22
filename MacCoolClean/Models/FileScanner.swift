//
//  FileScanner.swift
//  MacCoolClean
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
        
        // Try normal deletion first
        do {
            try fileManager.removeItem(atPath: file.path)
            scannedFiles.removeAll { $0.id == file.id }
        } catch {
            // If normal deletion fails, try with admin privileges
            deleteWithAdminPrivileges(file)
        }
    }
    
    private func deleteWithAdminPrivileges(_ file: ScannedFile) {
        let escapedPath = file.path.replacingOccurrences(of: "'", with: "'\\''")
        
        let script = """
        do shell script "rm -rf '\(escapedPath)'" with administrator privileges
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            
            if error == nil {
                scannedFiles.removeAll { $0.id == file.id }
            } else {
                lastError = "Could not delete \(file.name)"
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
        
        // Check if we need admin access for this path
        let needsAdmin = !fileManager.isReadableFile(atPath: path)
        
        if needsAdmin {
            await scanWithAdminPrivileges(
                path: path,
                minSize: minSize,
                shouldStop: shouldStop,
                onFileFound: onFileFound,
                onComplete: onComplete,
                onError: onError
            )
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
                // Skip directories we can't access
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
    
    private func scanWithAdminPrivileges(
        path: String,
        minSize: Int64,
        shouldStop: @escaping () -> Bool,
        onFileFound: @escaping (ScannedFile) async -> Void,
        onComplete: @escaping () async -> Void,
        onError: @escaping (String) async -> Void
    ) async {
        let script = """
        do shell script "find '\(path)' -type f -size +\(minSize / 1024)k 2>/dev/null | head -1000" with administrator privileges
        """
        
        // Run AppleScript on main thread as required
        let result: (output: String?, error: String?) = await MainActor.run {
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                let result = appleScript.executeAndReturnError(&error)
                if let error = error {
                    return (nil, error["NSAppleScriptErrorMessage"] as? String ?? "Admin access denied")
                }
                return (result.stringValue, nil)
            }
            return (nil, "Could not create AppleScript")
        }
        
        if let errorMsg = result.error {
            await onError(errorMsg)
            return
        }
        
        if let output = result.output {
            let paths = output.components(separatedBy: "\n").filter { !$0.isEmpty }
            
            for filePath in paths {
                if shouldStop() {
                    break
                }
                
                let url = URL(fileURLWithPath: filePath)
                
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
                    let size = attributes[.size] as? Int64 ?? 0
                    let modDate = attributes[.modificationDate] as? Date
                    let creationDate = attributes[.creationDate] as? Date
                    
                    if size >= minSize {
                        let file = ScannedFile(
                            url: url,
                            size: size,
                            isDirectory: false,
                            modifiedDate: modDate,
                            createdDate: creationDate
                        )
                        
                        await onFileFound(file)
                    }
                } catch {
                    continue
                }
            }
        }
        
        await onComplete()
    }
}
