//
//  BookmarkManager.swift
//  CoolClean
//
//  Manages security-scoped bookmarks for sandbox-compatible file access
//

import Foundation
import AppKit

@MainActor
class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()
    
    /// Currently accessible folders (user has granted access)
    @Published var accessibleFolders: [URL] = []
    
    /// Active security-scoped access tokens (need to be stopped when done)
    private var activeAccessTokens: [URL: Bool] = [:]
    
    private let bookmarksKey = "SavedFolderBookmarks"
    
    private init() {
        loadSavedBookmarks()
    }
    
    // MARK: - Public API
    
    /// Request access to a folder via NSOpenPanel
    /// Returns the URL if access was granted, nil otherwise
    func requestFolderAccess(message: String = "Select a folder to scan") -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = message
        panel.prompt = "Grant Access"
        
        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }
        
        // Save bookmark for future access
        saveBookmark(for: url)
        
        // Add to accessible folders if not already there
        if !accessibleFolders.contains(url) {
            accessibleFolders.append(url)
        }
        
        return url
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
        
        // Also check if file is directly readable (e.g., in app container)
        return FileManager.default.isReadableFile(atPath: url.path)
    }
    
    /// Start accessing a security-scoped resource
    /// Call this before accessing files in a bookmarked folder
    func startAccessing(url: URL) -> Bool {
        if activeAccessTokens[url] == true {
            return true // Already accessing
        }
        
        if url.startAccessingSecurityScopedResource() {
            activeAccessTokens[url] = true
            return true
        }
        
        return false
    }
    
    /// Stop accessing a security-scoped resource
    /// Call this when done with the folder
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
        
        // Update saved bookmarks
        var bookmarkData = UserDefaults.standard.dictionary(forKey: bookmarksKey) as? [String: Data] ?? [:]
        bookmarkData.removeValue(forKey: url.path)
        UserDefaults.standard.set(bookmarkData, forKey: bookmarksKey)
    }
    
    /// Get a display name for the accessible folders section
    func displayName(for url: URL) -> String {
        let path = url.path
        // Use real home directory (not sandbox container)
        let homeDir = NSHomeDirectory().replacingOccurrences(of: "/Library/Containers/com.idevelopmentllc.CoolClean/Data", with: "")
        
        if path == homeDir {
            return "Home Folder"
        } else if path == "/" {
            return "Entire System"
        } else if path == "/Applications" {
            return "Applications"
        } else if path.hasPrefix(homeDir) {
            // Show relative path from home
            let relativePath = String(path.dropFirst(homeDir.count + 1))
            return relativePath
        } else {
            return url.lastPathComponent
        }
    }
    
    // MARK: - Private Methods
    
    private func saveBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
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
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                
                if isStale {
                    // Bookmark is stale, try to refresh it
                    saveBookmark(for: url)
                }
                
                // Start accessing the resource
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

