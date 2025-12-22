# MacClean 🧹✨

A beautiful, native macOS app built with SwiftUI to help you clean up your Mac by finding and removing large files.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-green)

## Features

### 🔍 Smart File Scanning
- Scan your entire system or specific folders for large files
- Configurable minimum file size threshold
- Real-time progress display
- Supports scanning with administrator privileges for protected directories

### 📊 Storage Overview
- Beautiful circular progress indicator showing disk usage
- Real-time storage statistics (used, free, total)
- Health status indicator (Healthy, Warning, Critical)

### 🖥️ Menu Bar Integration
- Beautiful menu bar icon that reflects storage status
- Quick access to storage information without opening the main app
- One-click access to main window

### 💎 Premium Features
- **5 free scans** to try the app
- **One-time purchase of $0.99** for unlimited scans forever
- No subscriptions, no hidden fees

### 🎨 Beautiful Design
- Dark mode optimized interface
- Smooth animations and transitions
- Modern gradient backgrounds
- File type icons with contextual colors

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later (for building)

## Building

1. Open `MacClean.xcodeproj` in Xcode
2. Select your Development Team in the Signing & Capabilities tab
3. Build and run (⌘R)

## Permissions

For full functionality, MacClean requires:

1. **Full Disk Access** - To scan all files on your Mac
   - Go to System Settings → Privacy & Security → Full Disk Access
   - Add MacClean to the list

2. **Administrator Privileges** - For deleting protected files
   - The app will prompt for authentication when needed

## In-App Purchase Setup (for App Store)

1. Create a product in App Store Connect with ID: `com.macclean.pro.lifetime`
2. Set the price to $0.99
3. The included `StoreKit.storekit` file allows testing purchases in development

## Project Structure

```
MacClean/
├── MacCleanApp.swift          # Main app entry point
├── Views/
│   ├── ContentView.swift      # Main window layout
│   ├── StorageOverviewCard.swift
│   ├── ScanControlsView.swift
│   ├── FileListView.swift     # File list with actions
│   ├── UpgradeView.swift      # Pro upgrade sheet
│   └── MenuBarView.swift      # Menu bar popover
├── Models/
│   ├── ScannedFile.swift      # File data model
│   ├── FileScanner.swift      # File scanning logic
│   └── StoreManager.swift     # In-app purchase handling
├── Assets.xcassets/
├── Info.plist
├── MacClean.entitlements
└── StoreKit.storekit          # StoreKit testing config
```

## License

Copyright © 2024. All rights reserved.

---

Made with ❤️ for Mac

