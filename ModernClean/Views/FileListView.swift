//
//  FileListView.swift
//  ModernClean
//

import SwiftUI

struct FileListView: View {
    @EnvironmentObject var fileScanner: FileScanner
    @Binding var selectedFiles: Set<ScannedFile.ID>
    @Binding var showingDeleteConfirmation: Bool
    @Binding var currentPath: String
    let onDrillDown: (String) -> Void
    
    @State private var sortOrder: SortOrder = .sizeDescending
    @State private var searchText = ""
    @State private var navigationHistory: [String] = []
    
    enum SortOrder: String, CaseIterable {
        case sizeDescending = "Largest First"
        case sizeAscending = "Smallest First"
        case nameAscending = "Name A-Z"
        case nameDescending = "Name Z-A"
    }
    
    var filteredAndSortedFiles: [ScannedFile] {
        var files = fileScanner.scannedFiles
        
        // Filter by search text
        if !searchText.isEmpty {
            files = files.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.path.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Sort
        switch sortOrder {
        case .sizeDescending:
            files.sort { $0.size > $1.size }
        case .sizeAscending:
            files.sort { $0.size < $1.size }
        case .nameAscending:
            files.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            files.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        }
        
        return files
    }
    
    var totalSelectedSize: Int64 {
        fileScanner.scannedFiles
            .filter { selectedFiles.contains($0.id) }
            .reduce(0) { $0 + $1.size }
    }
    
    var pathComponents: [(name: String, path: String)] {
        var components: [(name: String, path: String)] = []
        var path = currentPath
        
        // Add root
        if path.hasPrefix("/") {
            components.append(("🖥️ Root", "/"))
        }
        
        // Build path components
        let parts = path.split(separator: "/").map(String.init)
        var buildPath = ""
        
        for part in parts {
            buildPath += "/" + part
            components.append((part, buildPath))
        }
        
        return components
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Breadcrumb navigation
            if !fileScanner.scannedFiles.isEmpty || !navigationHistory.isEmpty {
                BreadcrumbView(
                    pathComponents: pathComponents,
                    navigationHistory: navigationHistory,
                    onNavigate: { path in
                        navigateToPath(path)
                    },
                    onBack: goBack
                )
                .padding(.bottom, 12)
            }
            
            // Header with controls
            HStack(spacing: 16) {
                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.5))
                    
                    TextField("Search files...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.3))
                )
                .frame(width: 200)
                
                // Sort picker
                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
                
                Spacer()
                
                // Legend
                if !fileScanner.scannedFiles.isEmpty {
                    ImportanceLegend()
                }
                
                // Stats
                if !fileScanner.scannedFiles.isEmpty {
                    HStack(spacing: 16) {
                        Label("\(fileScanner.scannedFiles.count) files", systemImage: "doc.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        
                        if !selectedFiles.isEmpty {
                            Label("\(selectedFiles.count) selected (\(formatBytes(totalSelectedSize)))", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "e94560"))
                        }
                    }
                }
                
                // Delete button
                if !selectedFiles.isEmpty {
                    Button(action: { showingDeleteConfirmation = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                            Text("Delete Selected")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "ff5f57"), Color(hex: "d32f2f")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 12)
            
            // File list
            if fileScanner.isScanning {
                ScanningView(
                    currentPath: fileScanner.currentScanPath,
                    filesFound: fileScanner.scannedFiles.count
                )
            } else if fileScanner.scannedFiles.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredAndSortedFiles) { file in
                            FileRowView(
                                file: file,
                                isSelected: selectedFiles.contains(file.id),
                                onToggle: {
                                    if selectedFiles.contains(file.id) {
                                        selectedFiles.remove(file.id)
                                    } else {
                                        selectedFiles.insert(file.id)
                                    }
                                },
                                onDrillDown: file.isDirectory ? {
                                    drillIntoFolder(file)
                                } : nil
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.2))
                )
            }
        }
        .onChange(of: currentPath) { oldValue, newValue in
            // Track navigation history
            if !navigationHistory.contains(oldValue) && oldValue != newValue {
                // Only add to history if we're drilling down (not going back)
                if newValue.hasPrefix(oldValue) || navigationHistory.isEmpty {
                    if !navigationHistory.contains(oldValue) {
                        navigationHistory.append(oldValue)
                    }
                }
            }
        }
    }
    
    func drillIntoFolder(_ file: ScannedFile) {
        // Add current path to history before drilling down
        if !navigationHistory.contains(currentPath) {
            navigationHistory.append(currentPath)
        }
        onDrillDown(file.path)
    }
    
    func navigateToPath(_ path: String) {
        // Remove all history after this path
        if let index = navigationHistory.firstIndex(of: path) {
            navigationHistory = Array(navigationHistory.prefix(index))
        } else {
            navigationHistory.removeAll()
        }
        onDrillDown(path)
    }
    
    func goBack() {
        if let previousPath = navigationHistory.popLast() {
            onDrillDown(previousPath)
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Importance Legend

struct ImportanceLegend: View {
    @State private var showingLegend = false
    
    var body: some View {
        Button(action: { showingLegend.toggle() }) {
            HStack(spacing: 4) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                Text("Legend")
                    .font(.system(size: 11))
            }
            .foregroundColor(.white.opacity(0.6))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingLegend, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Folder Safety Guide")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                Divider()
                
                LegendRow(importance: .critical)
                LegendRow(importance: .important)
                LegendRow(importance: .caution)
                LegendRow(importance: .safe)
                
                Divider()
                
                Text("Hover over badges for detailed info")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 280)
        }
    }
}

struct LegendRow: View {
    let importance: SystemFolderImportance
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: importance.icon)
                .font(.system(size: 14))
                .foregroundColor(importance.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(importance.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(legendDescription)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var legendDescription: String {
        switch importance {
        case .critical:
            return "Never delete - will break macOS"
        case .important:
            return "May break apps or features"
        case .caution:
            return "Review before deleting"
        case .safe:
            return "Generally safe to delete"
        }
    }
}

// MARK: - Breadcrumb Views

struct BreadcrumbView: View {
    let pathComponents: [(name: String, path: String)]
    let navigationHistory: [String]
    let onNavigate: (String) -> Void
    let onBack: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Back button
            if !navigationHistory.isEmpty {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "e94560"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "e94560").opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
                
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 1, height: 20)
                    .padding(.horizontal, 4)
            }
            
            // Breadcrumb path
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(pathComponents.enumerated()), id: \.offset) { index, component in
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        
                        BreadcrumbButton(
                            name: component.name,
                            path: component.path,
                            isLast: index == pathComponents.count - 1,
                            action: {
                                if index < pathComponents.count - 1 {
                                    onNavigate(component.path)
                                }
                            }
                        )
                    }
                }
            }
            
            Spacer()
            
            // Current location indicator
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 10))
                Text("Current Location")
                    .font(.system(size: 11))
            }
            .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct BreadcrumbButton: View {
    let name: String
    let path: String
    let isLast: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var systemInfo: SystemFolderInfo? {
        SystemFolderInfo.getInfo(for: path)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 12, weight: isLast ? .semibold : .regular))
                    .foregroundColor(isLast ? .white : (isHovering ? Color(hex: "e94560") : .white.opacity(0.7)))
                
                // Show system folder indicator in breadcrumb
                if let info = systemInfo {
                    Image(systemName: info.importance.icon)
                        .font(.system(size: 9))
                        .foregroundColor(info.importance.color)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isLast ? Color(hex: "e94560").opacity(0.2) : (isHovering ? Color.white.opacity(0.1) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .disabled(isLast)
        .onHover { hovering in
            isHovering = hovering
        }
        .help(systemInfo?.description ?? "Navigate to \(name)")
    }
}

// MARK: - File Row View

struct FileRowView: View {
    let file: ScannedFile
    let isSelected: Bool
    let onToggle: () -> Void
    let onDrillDown: (() -> Void)?
    
    @State private var isHovering = false
    @State private var showingInfoPopover = false
    
    var systemInfo: SystemFolderInfo? {
        SystemFolderInfo.getInfo(for: file.path)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color(hex: "e94560") : Color.white.opacity(0.1))
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .help("Select for deletion")
            
            // Clickable file/folder content
            HStack(spacing: 12) {
                // File icon with system badge
                ZStack(alignment: .bottomTrailing) {
                    FileIconView(filename: file.name, isDirectory: file.isDirectory)
                    
                    // System folder badge
                    if let info = systemInfo {
                        SystemBadge(info: info)
                            .offset(x: 6, y: 6)
                    }
                }
                
                // File info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(file.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        // System folder label badge
                        if let info = systemInfo {
                            SystemFolderLabel(info: info)
                        }
                        
                        // Drill-down indicator for folders
                        if file.isDirectory && onDrillDown != nil {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 12))
                                Text("Double-click to open")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(Color(hex: "e94560").opacity(isHovering ? 1 : 0.5))
                        }
                    }
                    
                    Text(file.path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                TapGesture(count: 2)
                    .onEnded {
                        // Double-click to drill down into folder
                        if let drillDown = onDrillDown {
                            drillDown()
                        }
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 1)
                    .onEnded {
                        // Single click toggles selection
                        onToggle()
                    }
            )
            
            Spacer()
            
            // Size
            Text(formatBytes(file.size))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(sizeColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(sizeColor.opacity(0.15))
                )
                .help("File size: \(formatBytes(file.size))")
            
            // Actions
            HStack(spacing: 8) {
                // Info button for system folders
                if let info = systemInfo {
                    Button(action: { showingInfoPopover.toggle() }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(info.importance.color)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(info.importance.color.opacity(0.2))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Learn about this folder")
                    .popover(isPresented: $showingInfoPopover, arrowEdge: .leading) {
                        SystemFolderInfoPopover(info: info)
                    }
                }
                
                // Drill-down button for folders
                if file.isDirectory, let drillDown = onDrillDown {
                    Button(action: drillDown) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "e94560"))
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color(hex: "e94560").opacity(0.2))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Open folder and scan contents")
                }
                
                Button(action: revealInFinder) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
                
                Button(action: quickLook) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .help("Preview file or folder")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    var backgroundFill: Color {
        if isSelected {
            return Color(hex: "e94560").opacity(0.15)
        } else if let info = systemInfo, info.importance == .critical && isHovering {
            return info.importance.color.opacity(0.1)
        } else if isHovering {
            return Color.white.opacity(0.05)
        }
        return Color.clear
    }
    
    var borderColor: Color {
        if isSelected {
            return Color(hex: "e94560").opacity(0.3)
        } else if let info = systemInfo, info.importance == .critical {
            return info.importance.color.opacity(0.2)
        }
        return Color.clear
    }
    
    var sizeColor: Color {
        if file.size > 1_000_000_000 { // > 1GB
            return Color(hex: "ff5f57")
        } else if file.size > 500_000_000 { // > 500MB
            return Color(hex: "febc2e")
        } else {
            return Color(hex: "28c840")
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func revealInFinder() {
        NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: "")
    }
    
    func quickLook() {
        NSWorkspace.shared.open(URL(fileURLWithPath: file.path))
    }
}

// MARK: - System Folder Badge

struct SystemBadge: View {
    let info: SystemFolderInfo
    
    var body: some View {
        Image(systemName: info.importance.icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(4)
            .background(
                Circle()
                    .fill(info.importance.color)
                    .shadow(color: info.importance.color.opacity(0.5), radius: 3)
            )
    }
}

struct SystemFolderLabel: View {
    let info: SystemFolderInfo
    
    var body: some View {
        Text(info.importance.label)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(info.importance.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(info.importance.color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(info.importance.color.opacity(0.3), lineWidth: 0.5)
                    )
            )
            .help("\(info.name): \(info.description)")
    }
}

struct SystemFolderInfoPopover: View {
    let info: SystemFolderInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: info.importance.icon)
                    .font(.system(size: 24))
                    .foregroundColor(info.importance.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(info.importance.label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(info.importance.color)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Label("What is this?", systemImage: "info.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text(info.description)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Recommendation
            VStack(alignment: .leading, spacing: 8) {
                Label("Recommendation", systemImage: "lightbulb.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text(info.recommendation)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(info.importance.color.opacity(0.1))
            )
        }
        .padding()
        .frame(width: 320)
    }
}

// MARK: - File Icon View

struct FileIconView: View {
    let filename: String
    let isDirectory: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(iconColor.opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image(systemName: iconName)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
        }
    }
    
    var iconName: String {
        if isDirectory {
            return "folder.fill"
        }
        
        let ext = (filename as NSString).pathExtension.lowercased()
        
        switch ext {
        case "app":
            return "app.fill"
        case "dmg", "iso":
            return "opticaldisc.fill"
        case "zip", "rar", "7z", "tar", "gz":
            return "doc.zipper"
        case "mp4", "mov", "avi", "mkv", "wmv":
            return "film.fill"
        case "mp3", "wav", "aac", "flac", "m4a":
            return "music.note"
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic":
            return "photo.fill"
        case "pdf":
            return "doc.text.fill"
        case "doc", "docx":
            return "doc.richtext.fill"
        case "xls", "xlsx":
            return "tablecells.fill"
        case "ppt", "pptx":
            return "rectangle.stack.fill"
        case "swift", "py", "js", "ts", "java", "cpp", "c", "h":
            return "chevron.left.forwardslash.chevron.right"
        case "log", "txt":
            return "doc.plaintext.fill"
        default:
            return "doc.fill"
        }
    }
    
    var iconColor: Color {
        if isDirectory {
            return Color(hex: "5c9eff")
        }
        
        let ext = (filename as NSString).pathExtension.lowercased()
        
        switch ext {
        case "app":
            return Color(hex: "a855f7")
        case "dmg", "iso":
            return Color(hex: "f59e0b")
        case "zip", "rar", "7z", "tar", "gz":
            return Color(hex: "8b5cf6")
        case "mp4", "mov", "avi", "mkv", "wmv":
            return Color(hex: "ef4444")
        case "mp3", "wav", "aac", "flac", "m4a":
            return Color(hex: "ec4899")
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic":
            return Color(hex: "10b981")
        case "pdf":
            return Color(hex: "ef4444")
        case "swift", "py", "js", "ts", "java", "cpp", "c", "h":
            return Color(hex: "3b82f6")
        default:
            return Color(hex: "6b7280")
        }
    }
}

// MARK: - Scanning View

struct ScanningView: View {
    let currentPath: String
    let filesFound: Int
    
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated scanner
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color(hex: "e94560").opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: 80 + CGFloat(i) * 30, height: 80 + CGFloat(i) * 30)
                }
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "e94560"))
                    .rotationEffect(.degrees(rotation))
            }
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            
            VStack(spacing: 8) {
                Text("Scanning for large files...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(currentPath)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 400)
                
                Text("\(filesFound) large files found")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "28c840"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "externaldrive.badge.checkmark")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "e94560"), Color(hex: "a855f7")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("No Files Scanned Yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Click 'Scan for Large Files' to find space hogs on your Mac")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FileListView(
        selectedFiles: .constant([]),
        showingDeleteConfirmation: .constant(false),
        currentPath: .constant("/"),
        onDrillDown: { _ in }
    )
    .environmentObject(FileScanner.shared)
    .padding()
    .background(Color(hex: "1a1a2e"))
}
