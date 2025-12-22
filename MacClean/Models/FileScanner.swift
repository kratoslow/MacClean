//
//  FileScanner.swift
//  MacClean
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
        
        // Start background scan
        scanTask = Task {
            await performScan(path: path, minSize: minSize)
        }
    }
    
    func stopScanning() {
        shouldStopScanning = true
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
    }
    
    private func performScan(path: String, minSize: Int64) async {
        let fileManager = FileManager.default
        let rootURL = URL(fileURLWithPath: path)
        
        // Check if we need admin access for this path
        let needsAdmin = !fileManager.isReadableFile(atPath: path)
        
        if needsAdmin {
            // Try to scan with elevated privileges using helper
            await scanWithAdminPrivileges(path: path, minSize: minSize)
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
                .isReadableKey
            ],
            options: [.skipsHiddenFiles],
            errorHandler: { [weak self] url, error in
                // Skip directories we can't access
                return true
            }
        ) else {
            await MainActor.run {
                self.isScanning = false
                self.lastError = "Could not access \(path)"
            }
            return
        }
        
        var filesFound: [ScannedFile] = []
        var scannedCount = 0
        
        for case let fileURL as URL in enumerator {
            // Check if we should stop
            if shouldStopScanning || Task.isCancelled {
                break
            }
            
            scannedCount += 1
            
            // Update UI periodically
            if scannedCount % 100 == 0 {
                await MainActor.run {
                    self.currentScanPath = fileURL.path
                }
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
                    // For directories, calculate total size
                    size = calculateDirectorySize(at: fileURL)
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
                    
                    filesFound.append(file)
                    
                    // Update UI with new file
                    await MainActor.run {
                        self.scannedFiles.append(file)
                        // Sort by size descending
                        self.scannedFiles.sort { $0.size > $1.size }
                        // Keep only top 1000 files for performance
                        if self.scannedFiles.count > 1000 {
                            self.scannedFiles = Array(self.scannedFiles.prefix(1000))
                        }
                    }
                    
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
        
        await MainActor.run {
            self.isScanning = false
            self.currentScanPath = ""
        }
    }
    
    private func calculateDirectorySize(at url: URL) -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            if shouldStopScanning {
                break
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
    
    private func scanWithAdminPrivileges(path: String, minSize: Int64) async {
        // For scanning protected directories, we use a helper script with admin privileges
        // This requires the user to authenticate
        
        let script = """
        do shell script "find '\(path)' -type f -size +\(minSize / 1024)k 2>/dev/null | head -1000" with administrator privileges
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)
            
            if let error = error {
                await MainActor.run {
                    self.lastError = error["NSAppleScriptErrorMessage"] as? String ?? "Admin access denied"
                    self.isScanning = false
                }
                return
            }
            
            if let output = result.stringValue {
                let paths = output.components(separatedBy: "\n").filter { !$0.isEmpty }
                
                for filePath in paths {
                    if shouldStopScanning {
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
                            
                            await MainActor.run {
                                self.scannedFiles.append(file)
                                self.scannedFiles.sort { $0.size > $1.size }
                            }
                        }
                    } catch {
                        continue
                    }
                }
            }
        }
        
        await MainActor.run {
            self.isScanning = false
        }
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
                // Successfully deleted
                DispatchQueue.main.async {
                    self.scannedFiles.removeAll { $0.id == file.id }
                }
            } else {
                // Show error
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

