//
//  SystemFolderInfo.swift
//  ModernClean
//
//  Information about important macOS system folders
//

import SwiftUI

enum SystemFolderImportance {
    case critical    // Never delete - will break macOS
    case important   // Caution - may break apps or system features
    case caution     // User data - deletable but be careful
    case safe        // Safe to delete (caches, logs, etc.)
    
    var color: Color {
        switch self {
        case .critical:
            return Color(hex: "ff3b30")  // Red
        case .important:
            return Color(hex: "ff9500")  // Orange
        case .caution:
            return Color(hex: "ffcc00")  // Yellow
        case .safe:
            return Color(hex: "34c759")  // Green
        }
    }
    
    var icon: String {
        switch self {
        case .critical:
            return "exclamationmark.shield.fill"
        case .important:
            return "exclamationmark.triangle.fill"
        case .caution:
            return "info.circle.fill"
        case .safe:
            return "checkmark.circle.fill"
        }
    }
    
    var label: String {
        switch self {
        case .critical:
            return "System Critical"
        case .important:
            return "Important"
        case .caution:
            return "Use Caution"
        case .safe:
            return "Safe to Clean"
        }
    }
}

struct SystemFolderInfo {
    let importance: SystemFolderImportance
    let name: String
    let description: String
    let recommendation: String
    
    static func getInfo(for path: String) -> SystemFolderInfo? {
        let normalizedPath = path.lowercased()
        
        // Check exact matches first, then prefix matches
        for (checkPath, info) in systemFolders {
            if normalizedPath == checkPath.lowercased() || 
               normalizedPath.hasPrefix(checkPath.lowercased() + "/") {
                return info
            }
        }
        
        // Check pattern matches
        for (pattern, info) in patternFolders {
            if matchesPattern(path: normalizedPath, pattern: pattern) {
                return info
            }
        }
        
        return nil
    }
    
    private static func matchesPattern(path: String, pattern: String) -> Bool {
        // Simple pattern matching for paths
        if pattern.contains("*") {
            let parts = pattern.split(separator: "*")
            if parts.count == 2 {
                return path.contains(String(parts[0])) && path.contains(String(parts[1]))
            }
        }
        return path.contains(pattern.lowercased())
    }
    
    // MARK: - System Folders Database
    
    #if os(iOS)
    // iOS Folder Database
    private static let systemFolders: [String: SystemFolderInfo] = [
        // User accessible folders
        "Documents": SystemFolderInfo(
            importance: .caution,
            name: "Documents",
            description: "Your personal documents and app data stored in the Files app.",
            recommendation: "Review contents carefully. May contain important documents."
        ),
        "Downloads": SystemFolderInfo(
            importance: .safe,
            name: "Downloads",
            description: "Downloaded files from Safari, Mail, and other apps.",
            recommendation: "Often contains forgotten downloads. Safe to clean regularly!"
        ),
        "iCloud Drive": SystemFolderInfo(
            importance: .caution,
            name: "iCloud Drive",
            description: "Files synced across all your Apple devices via iCloud.",
            recommendation: "⚠️ Deleting here removes from ALL your devices!"
        ),
        "On My iPhone": SystemFolderInfo(
            importance: .caution,
            name: "On My iPhone",
            description: "Files stored locally on your device, not synced to iCloud.",
            recommendation: "Safe to clean but check if you need files elsewhere."
        ),
        "On My iPad": SystemFolderInfo(
            importance: .caution,
            name: "On My iPad",
            description: "Files stored locally on your device, not synced to iCloud.",
            recommendation: "Safe to clean but check if you need files elsewhere."
        ),
        // App-specific folders commonly seen
        "Podcasts": SystemFolderInfo(
            importance: .safe,
            name: "Podcasts",
            description: "Downloaded podcast episodes.",
            recommendation: "Safe to delete! Episodes can be re-downloaded."
        ),
        "Music": SystemFolderInfo(
            importance: .caution,
            name: "Music",
            description: "Downloaded music and Apple Music content.",
            recommendation: "Delete with caution. Purchased music can be re-downloaded."
        ),
        "Photos": SystemFolderInfo(
            importance: .important,
            name: "Photos",
            description: "Your photo library and downloaded images.",
            recommendation: "⚠️ These may be irreplaceable! Ensure backups exist."
        ),
        "Videos": SystemFolderInfo(
            importance: .caution,
            name: "Videos",
            description: "Video files and downloaded movies.",
            recommendation: "Large files! Safe to delete if you don't need them."
        ),
        // Common cache/temp patterns
        "Caches": SystemFolderInfo(
            importance: .safe,
            name: "App Caches",
            description: "Temporary cached data from apps.",
            recommendation: "Safe to delete. Apps will recreate as needed."
        ),
        "tmp": SystemFolderInfo(
            importance: .safe,
            name: "Temporary Files",
            description: "Temporary files that can be safely removed.",
            recommendation: "Safe to delete. Often cleaned automatically."
        ),
    ]
    
    private static let patternFolders: [String: SystemFolderInfo] = [
        "Attachments": SystemFolderInfo(
            importance: .safe,
            name: "Message Attachments",
            description: "Photos and files received in Messages.",
            recommendation: "Can be very large! Safe to delete old attachments."
        ),
        "Recordings": SystemFolderInfo(
            importance: .caution,
            name: "Voice Recordings",
            description: "Voice memos and audio recordings.",
            recommendation: "Check if you need these before deleting."
        ),
        "Backup": SystemFolderInfo(
            importance: .caution,
            name: "Backup Files",
            description: "Backup data from various apps.",
            recommendation: "May contain important backups. Review carefully."
        ),
        "Export": SystemFolderInfo(
            importance: .safe,
            name: "Exported Files",
            description: "Files exported from apps for sharing.",
            recommendation: "Usually temporary exports. Safe to clean."
        ),
    ]
    #else
    // macOS Folder Database
    private static let systemFolders: [String: SystemFolderInfo] = [
        // Critical System Folders
        "/System": SystemFolderInfo(
            importance: .critical,
            name: "System",
            description: "Core macOS operating system files including frameworks, libraries, and essential components that macOS needs to run.",
            recommendation: "Never delete. Removing files here will break your Mac and may require a complete reinstall of macOS."
        ),
        "/System/Library": SystemFolderInfo(
            importance: .critical,
            name: "System Library",
            description: "System-level frameworks, extensions, and core services used by macOS. Includes kernel extensions and system daemons.",
            recommendation: "Never delete. These files are protected by System Integrity Protection (SIP) for good reason."
        ),
        "/System/Applications": SystemFolderInfo(
            importance: .critical,
            name: "System Applications",
            description: "Built-in macOS apps like Finder, Safari, Mail, and other core applications that come with your Mac.",
            recommendation: "Never delete. These are essential system applications."
        ),
        "/usr": SystemFolderInfo(
            importance: .critical,
            name: "Unix System Resources",
            description: "Unix-based system utilities, libraries, and resources. Contains essential command-line tools and shared libraries.",
            recommendation: "Never delete. Critical for system operation and command-line functionality."
        ),
        "/bin": SystemFolderInfo(
            importance: .critical,
            name: "System Binaries",
            description: "Essential command-line programs like ls, cp, mv, and other core Unix utilities needed for basic system operation.",
            recommendation: "Never delete. Required for basic system functionality."
        ),
        "/sbin": SystemFolderInfo(
            importance: .critical,
            name: "System Administration Binaries",
            description: "System administration utilities used for booting, recovery, and maintenance. Includes fsck, mount, and other critical tools.",
            recommendation: "Never delete. Essential for system administration and recovery."
        ),
        "/private": SystemFolderInfo(
            importance: .critical,
            name: "Private System Data",
            description: "Contains system-critical directories like /var, /etc, and /tmp. Stores configuration files and runtime data.",
            recommendation: "Never delete the folder itself. Some contents like caches may be safely cleaned."
        ),
        "/private/var": SystemFolderInfo(
            importance: .critical,
            name: "Variable System Data",
            description: "System logs, databases, mail spools, and runtime data. Contains data that changes during system operation.",
            recommendation: "Caution required. Logs can be cleaned, but other data is essential."
        ),
        "/etc": SystemFolderInfo(
            importance: .critical,
            name: "System Configuration",
            description: "System-wide configuration files for various services and applications. Actually a symlink to /private/etc.",
            recommendation: "Never delete. Modifying these files can break system services."
        ),
        "/var": SystemFolderInfo(
            importance: .critical,
            name: "Variable Data",
            description: "Runtime data, logs, and temporary files. Symlink to /private/var.",
            recommendation: "Logs may be cleaned, but be careful with other contents."
        ),
        "/Volumes": SystemFolderInfo(
            importance: .critical,
            name: "Mounted Volumes",
            description: "Mount points for all storage devices including your main disk, external drives, and network volumes.",
            recommendation: "Never delete. This is where all your drives are accessed from."
        ),
        "/cores": SystemFolderInfo(
            importance: .important,
            name: "Core Dumps",
            description: "Stores crash dumps from applications. Used for debugging when apps crash.",
            recommendation: "Safe to delete contents if you're not debugging crashes. These can get very large."
        ),
        
        // Important System Folders
        "/Library": SystemFolderInfo(
            importance: .important,
            name: "System Library (Shared)",
            description: "System-wide resources shared by all users including application support, fonts, preferences, and extensions.",
            recommendation: "Be careful. Deleting wrong files may break applications for all users."
        ),
        "/Library/Application Support": SystemFolderInfo(
            importance: .important,
            name: "Application Support (System)",
            description: "Shared application data used by apps for all users. Includes license files, databases, and app resources.",
            recommendation: "Check each app's folder. May contain important data or just cache-like content."
        ),
        "/Library/Caches": SystemFolderInfo(
            importance: .safe,
            name: "System Caches",
            description: "System-wide cache files that can be regenerated. Includes software update caches and system service caches.",
            recommendation: "Generally safe to delete. Contents will be regenerated as needed."
        ),
        "/Library/Logs": SystemFolderInfo(
            importance: .safe,
            name: "System Logs",
            description: "System-wide log files from various services and applications. Useful for troubleshooting.",
            recommendation: "Safe to delete. New logs will be created automatically. Keep if troubleshooting issues."
        ),
        "/Library/LaunchAgents": SystemFolderInfo(
            importance: .important,
            name: "Launch Agents (System)",
            description: "Background processes that start automatically for all users. Controls what apps start at login.",
            recommendation: "Caution. Removing items will prevent associated apps from starting automatically."
        ),
        "/Library/LaunchDaemons": SystemFolderInfo(
            importance: .important,
            name: "Launch Daemons",
            description: "System-level background services that run regardless of user login. Critical for many system functions.",
            recommendation: "High caution. Only remove if you know the daemon is from unneeded software."
        ),
        "/Library/Extensions": SystemFolderInfo(
            importance: .critical,
            name: "Kernel Extensions",
            description: "Third-party kernel extensions (kexts) that add hardware or system functionality.",
            recommendation: "High caution. Removing these may disable hardware or features."
        ),
        "/Library/Preferences": SystemFolderInfo(
            importance: .important,
            name: "System Preferences",
            description: "System-wide preference files for applications and services.",
            recommendation: "Caution. Deleting will reset app settings to defaults."
        ),
        "/Library/Fonts": SystemFolderInfo(
            importance: .caution,
            name: "System Fonts",
            description: "Fonts available to all users on this Mac. Includes third-party installed fonts.",
            recommendation: "Safe to delete unused fonts. System fonts cannot be removed."
        ),
        
        // Applications
        "/Applications": SystemFolderInfo(
            importance: .caution,
            name: "Applications",
            description: "Installed applications for all users. Contains both system apps and user-installed apps.",
            recommendation: "Safe to delete apps you don't need. Use Finder or dedicated uninstaller for clean removal."
        ),
        "/Applications/Utilities": SystemFolderInfo(
            importance: .important,
            name: "Utilities",
            description: "System utility applications like Disk Utility, Terminal, Activity Monitor, and other maintenance tools.",
            recommendation: "Keep these. Essential for system maintenance and troubleshooting."
        ),
        
        // User Library
        "~/Library": SystemFolderInfo(
            importance: .caution,
            name: "User Library",
            description: "Your personal application support files, preferences, caches, and app-specific data.",
            recommendation: "Be careful. Contains your app settings and data. Some contents are safe to clean."
        ),
        "~/Library/Application Support": SystemFolderInfo(
            importance: .caution,
            name: "Application Support",
            description: "Your personal app data including saved games, app databases, and configuration files.",
            recommendation: "Check each folder. May contain important data like saved games or app history."
        ),
        "~/Library/Caches": SystemFolderInfo(
            importance: .safe,
            name: "User Caches",
            description: "Cache files for your applications. These speed up apps but can be regenerated.",
            recommendation: "Safe to delete. Apps will recreate caches as needed. Great for reclaiming space!"
        ),
        "~/Library/Logs": SystemFolderInfo(
            importance: .safe,
            name: "User Logs",
            description: "Log files from applications you use. Useful for troubleshooting app issues.",
            recommendation: "Safe to delete. Keep if you're troubleshooting a specific app problem."
        ),
        "~/Library/Preferences": SystemFolderInfo(
            importance: .caution,
            name: "User Preferences",
            description: "Your personal preferences for applications. Contains app settings and configurations.",
            recommendation: "Caution. Deleting will reset apps to default settings."
        ),
        "~/Library/Containers": SystemFolderInfo(
            importance: .caution,
            name: "App Containers",
            description: "Sandboxed app data. Each App Store app has its own container with its documents and preferences.",
            recommendation: "Deleting will remove all data for that sandboxed app."
        ),
        "~/Library/Mail": SystemFolderInfo(
            importance: .important,
            name: "Mail Data",
            description: "Your email messages, attachments, and account data for Apple Mail.",
            recommendation: "Caution! Contains all your emails. Only delete if you have backups."
        ),
        "~/Library/Messages": SystemFolderInfo(
            importance: .important,
            name: "Messages Data",
            description: "Your iMessage and SMS history, attachments, and conversation data.",
            recommendation: "Caution! Contains your message history. Attachments folder can be large."
        ),
        "~/Library/Safari": SystemFolderInfo(
            importance: .caution,
            name: "Safari Data",
            description: "Safari browser data including history, bookmarks, and extensions.",
            recommendation: "Caution. Contains bookmarks and browsing data."
        ),
        "~/Library/Cookies": SystemFolderInfo(
            importance: .safe,
            name: "Cookies",
            description: "Website cookies storing login sessions and preferences.",
            recommendation: "Safe to delete but you'll be logged out of websites."
        ),
        "~/Library/Saved Application State": SystemFolderInfo(
            importance: .safe,
            name: "Saved App State",
            description: "Window positions and states for apps when you quit them.",
            recommendation: "Safe to delete. Apps will just start fresh instead of restoring state."
        ),
        "~/Library/WebKit": SystemFolderInfo(
            importance: .safe,
            name: "WebKit Data",
            description: "Web content caches and data for Safari and apps using WebKit.",
            recommendation: "Safe to delete. Will be regenerated as you browse."
        ),
        
        // User folders
        "~/Downloads": SystemFolderInfo(
            importance: .safe,
            name: "Downloads",
            description: "Your downloaded files from the internet, email, and AirDrop.",
            recommendation: "Review contents! Often contains forgotten large files. Safe to delete what you don't need."
        ),
        "~/Documents": SystemFolderInfo(
            importance: .caution,
            name: "Documents",
            description: "Your personal documents and files.",
            recommendation: "This is your data! Review carefully before deleting anything."
        ),
        "~/Desktop": SystemFolderInfo(
            importance: .caution,
            name: "Desktop",
            description: "Files and folders on your desktop.",
            recommendation: "This is your data! Make sure you don't need files before deleting."
        ),
        "~/Movies": SystemFolderInfo(
            importance: .caution,
            name: "Movies",
            description: "Your video files and movie projects.",
            recommendation: "Often contains large files. Review what you want to keep."
        ),
        "~/Music": SystemFolderInfo(
            importance: .caution,
            name: "Music",
            description: "Your music library and audio files.",
            recommendation: "May include purchased music. Make sure you have backups."
        ),
        "~/Pictures": SystemFolderInfo(
            importance: .caution,
            name: "Pictures",
            description: "Your photos, images, and Pictures library.",
            recommendation: "May contain irreplaceable photos. Ensure backups exist."
        ),
        
        // Developer
        "~/Library/Developer": SystemFolderInfo(
            importance: .safe,
            name: "Developer Files",
            description: "Xcode caches, simulators, and development-related files.",
            recommendation: "Often very large! DerivedData and old simulators are safe to delete."
        ),
        "~/Library/Developer/Xcode/DerivedData": SystemFolderInfo(
            importance: .safe,
            name: "Xcode Derived Data",
            description: "Xcode build caches and indexes. Can grow very large over time.",
            recommendation: "Safe to delete! Xcode will rebuild as needed. Great space saver for developers."
        ),
        "~/Library/Developer/CoreSimulator": SystemFolderInfo(
            importance: .safe,
            name: "iOS Simulators",
            description: "iOS/iPadOS/watchOS/tvOS simulator data and caches.",
            recommendation: "Old simulator versions can be deleted. Use Xcode to manage simulators."
        ),
        
        // Other common locations
        "/tmp": SystemFolderInfo(
            importance: .safe,
            name: "Temporary Files",
            description: "Temporary files created by the system and apps. Cleared on restart.",
            recommendation: "Safe to delete contents. Will be cleaned automatically on restart."
        ),
        "~/.Trash": SystemFolderInfo(
            importance: .safe,
            name: "Trash",
            description: "Files you've deleted but not yet permanently removed.",
            recommendation: "Empty Trash to reclaim space. Files here are already marked for deletion."
        ),
        "/Users/Shared": SystemFolderInfo(
            importance: .caution,
            name: "Shared User Files",
            description: "Files shared between all users on this Mac.",
            recommendation: "Check with other users before deleting shared files."
        ),
    ]
    
    // Pattern-based matches
    private static let patternFolders: [String: SystemFolderInfo] = [
        "node_modules": SystemFolderInfo(
            importance: .safe,
            name: "Node.js Modules",
            description: "npm package dependencies for JavaScript/Node.js projects.",
            recommendation: "Safe to delete! Run 'npm install' to restore. Can be very large."
        ),
        ".git": SystemFolderInfo(
            importance: .caution,
            name: "Git Repository",
            description: "Version control data for a Git repository.",
            recommendation: "Only delete if you no longer need version history. Push changes first!"
        ),
        "Pods": SystemFolderInfo(
            importance: .safe,
            name: "CocoaPods",
            description: "iOS/macOS dependency manager packages.",
            recommendation: "Safe to delete. Run 'pod install' to restore."
        ),
        ".cache": SystemFolderInfo(
            importance: .safe,
            name: "Cache Folder",
            description: "Application cache directory.",
            recommendation: "Generally safe to delete. Will be regenerated as needed."
        ),
        "build": SystemFolderInfo(
            importance: .safe,
            name: "Build Output",
            description: "Compiled build artifacts from development projects.",
            recommendation: "Safe to delete. Can be regenerated by rebuilding the project."
        ),
        "dist": SystemFolderInfo(
            importance: .safe,
            name: "Distribution Files",
            description: "Compiled distribution files from build processes.",
            recommendation: "Safe to delete. Can be regenerated by rebuilding."
        ),
        "__pycache__": SystemFolderInfo(
            importance: .safe,
            name: "Python Cache",
            description: "Compiled Python bytecode files.",
            recommendation: "Safe to delete. Python will regenerate as needed."
        ),
        "venv": SystemFolderInfo(
            importance: .safe,
            name: "Python Virtual Environment",
            description: "Python virtual environment with installed packages.",
            recommendation: "Safe to delete. Can be recreated with requirements.txt."
        ),
        ".venv": SystemFolderInfo(
            importance: .safe,
            name: "Python Virtual Environment",
            description: "Python virtual environment with installed packages.",
            recommendation: "Safe to delete. Can be recreated with requirements.txt."
        ),
    ]
    #endif
}

