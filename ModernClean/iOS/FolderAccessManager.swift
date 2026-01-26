//
//  FolderAccessManager.swift
//  ModernClean (iOS)
//
//  iOS equivalent of BookmarkManager - manages folder access via UIDocumentPicker
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class FolderAccessManager: ObservableObject {
    static let shared = FolderAccessManager()
    
    /// Currently accessible folders (user has granted access)
    @Published var accessibleFolders: [URL] = []
    
    /// Whether we're showing the document picker
    @Published var isShowingPicker = false
    
    /// Active security-scoped access tokens
    private var activeAccessTokens: [URL: Bool] = [:]
    
    private let bookmarksKey = "SavedFolderBookmarks_iOS"
    
    private init() {
        loadSavedBookmarks()
    }
    
    // MARK: - Public API
    
    /// Request folder access - triggers the document picker
    func requestFolderAccess() {
        isShowingPicker = true
    }
    
    /// Handle a URL picked by the document picker
    func handlePickedURL(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource: \(url)")
            return
        }
        
        activeAccessTokens[url] = true
        
        // Save bookmark for persistent access
        saveBookmark(for: url)
        
        if !accessibleFolders.contains(url) {
            accessibleFolders.append(url)
        }
    }
    
    /// Check if we have access to a given path
    func hasAccess(to path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        return hasAccess(to: url)
    }
    
    /// Check if we have access to a given URL
    func hasAccess(to url: URL) -> Bool {
        // Check if this URL or any parent is in our accessible folders
        for accessibleURL in accessibleFolders {
            if url.path.hasPrefix(accessibleURL.path) {
                return true
            }
        }
        
        // Also check if file is directly readable
        return FileManager.default.isReadableFile(atPath: url.path)
    }
    
    /// Start accessing a security-scoped resource
    func startAccessing(url: URL) -> Bool {
        if activeAccessTokens[url] == true {
            return true
        }
        
        if url.startAccessingSecurityScopedResource() {
            activeAccessTokens[url] = true
            return true
        }
        
        return false
    }
    
    /// Stop accessing a security-scoped resource
    func stopAccessing(url: URL) {
        if activeAccessTokens[url] == true {
            url.stopAccessingSecurityScopedResource()
            activeAccessTokens[url] = nil
        }
    }
    
    /// Stop accessing all resources
    func stopAccessingAll() {
        for (url, _) in activeAccessTokens {
            url.stopAccessingSecurityScopedResource()
        }
        activeAccessTokens.removeAll()
    }
    
    /// Remove a saved bookmark
    func removeBookmark(for url: URL) {
        stopAccessing(url: url)
        accessibleFolders.removeAll { $0 == url }
        
        var bookmarkData = UserDefaults.standard.dictionary(forKey: bookmarksKey) as? [String: Data] ?? [:]
        bookmarkData.removeValue(forKey: url.path)
        UserDefaults.standard.set(bookmarkData, forKey: bookmarksKey)
    }
    
    /// Get a display name for folders
    func displayName(for url: URL) -> String {
        let name = url.lastPathComponent
        
        // Provide friendly names for common paths
        if name == "Documents" {
            return "Documents"
        } else if name.contains("iCloud") {
            return "iCloud Drive"
        } else if name == "Downloads" {
            return "Downloads"
        }
        
        return name
    }
    
    // MARK: - Private Methods
    
    private func saveBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            var savedBookmarks = UserDefaults.standard.dictionary(forKey: bookmarksKey) as? [String: Data] ?? [:]
            savedBookmarks[url.path] = bookmarkData
            UserDefaults.standard.set(savedBookmarks, forKey: bookmarksKey)
            
        } catch {
            print("Failed to save bookmark for \(url.path): \(error)")
        }
    }
    
    private func loadSavedBookmarks() {
        guard let savedBookmarks = UserDefaults.standard.dictionary(forKey: bookmarksKey) as? [String: Data] else {
            return
        }
        
        for (_, bookmarkData) in savedBookmarks {
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: [],
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                
                if isStale {
                    saveBookmark(for: url)
                }
                
                if url.startAccessingSecurityScopedResource() {
                    activeAccessTokens[url] = true
                    
                    if !accessibleFolders.contains(url) {
                        accessibleFolders.append(url)
                    }
                }
                
            } catch {
                print("Failed to resolve bookmark: \(error)")
            }
        }
    }
}

// MARK: - Document Picker Coordinator

struct FolderPickerView: UIViewControllerRepresentable {
    @EnvironmentObject var folderAccessManager: FolderAccessManager
    var onFolderSelected: ((URL) -> Void)?
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FolderPickerView
        
        init(_ parent: FolderPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            Task { @MainActor in
                self.parent.folderAccessManager.handlePickedURL(url)
                self.parent.onFolderSelected?(url)
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // User cancelled
        }
    }
}
