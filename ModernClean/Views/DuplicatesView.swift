//
//  DuplicatesView.swift
//  ModernClean
//
//  View for displaying and managing duplicate files
//

import SwiftUI

struct DuplicatesView: View {
    @EnvironmentObject var fileScanner: FileScanner
    @Binding var selectedDuplicates: Set<ScannedFile.ID>
    @Binding var showingDeleteConfirmation: Bool
    @State private var expandedGroups: Set<UUID> = []
    @State private var searchText = ""
    
    var filteredGroups: [DuplicateGroup] {
        if searchText.isEmpty {
            return fileScanner.duplicateGroups
        }
        return fileScanner.duplicateGroups.filter { group in
            group.files.contains { file in
                file.name.localizedCaseInsensitiveContains(searchText) ||
                file.path.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var totalSelectedSize: Int64 {
        fileScanner.duplicateGroups
            .flatMap { $0.files }
            .filter { selectedDuplicates.contains($0.id) }
            .reduce(0) { $0 + $1.size }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with stats
            DuplicatesHeaderView(
                searchText: $searchText,
                selectedCount: selectedDuplicates.count,
                selectedSize: totalSelectedSize,
                showingDeleteConfirmation: $showingDeleteConfirmation
            )
            .padding(.bottom, 12)
            
            // Content
            if fileScanner.isScanningDuplicates {
                DuplicateScanningView(
                    progress: fileScanner.duplicateScanProgress,
                    currentPath: fileScanner.currentScanPath,
                    groupsFound: fileScanner.duplicateGroups.count
                )
            } else if fileScanner.duplicateGroups.isEmpty {
                DuplicatesEmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Summary card
                        DuplicatesSummaryCard(
                            totalGroups: filteredGroups.count,
                            totalSavings: fileScanner.totalDuplicateSavings
                        )
                        .padding(.horizontal, 4)
                        
                        // Duplicate groups
                        ForEach(filteredGroups) { group in
                            DuplicateGroupCard(
                                group: group,
                                isExpanded: expandedGroups.contains(group.id),
                                selectedFiles: $selectedDuplicates,
                                onToggleExpand: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        if expandedGroups.contains(group.id) {
                                            expandedGroups.remove(group.id)
                                        } else {
                                            expandedGroups.insert(group.id)
                                        }
                                    }
                                },
                                onDeleteAllDuplicates: {
                                    fileScanner.deleteAllDuplicatesInGroup(group, keepFirst: true)
                                }
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
    }
}

// MARK: - Header View

struct DuplicatesHeaderView: View {
    @Binding var searchText: String
    let selectedCount: Int
    let selectedSize: Int64
    @Binding var showingDeleteConfirmation: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))
                
                TextField("Search duplicates...", text: $searchText)
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
            
            Spacer()
            
            // Stats
            if selectedCount > 0 {
                Label("\(selectedCount) selected (\(formatBytes(selectedSize)))", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "e94560"))
            }
            
            // Delete button
            if selectedCount > 0 {
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
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Summary Card

struct DuplicatesSummaryCard: View {
    let totalGroups: Int
    let totalSavings: Int64
    
    var body: some View {
        HStack(spacing: 20) {
            // Groups count
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundColor(Color(hex: "a855f7"))
                    Text("\(totalGroups)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Text("Duplicate Groups")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.2))
            
            // Potential savings
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(Color(hex: "28c840"))
                    Text(formatBytes(totalSavings))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Text("Potential Savings")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Tip
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(hex: "febc2e"))
                Text("Keep one copy, delete the rest to save space!")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "febc2e").opacity(0.1))
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "a855f7").opacity(0.15), Color(hex: "6366f1").opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "a855f7").opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Duplicate Group Card

struct DuplicateGroupCard: View {
    let group: DuplicateGroup
    let isExpanded: Bool
    @Binding var selectedFiles: Set<ScannedFile.ID>
    let onToggleExpand: () -> Void
    let onDeleteAllDuplicates: () -> Void
    
    @State private var isHovering = false
    @State private var showingDeleteAlert = false
    @State private var showingSensitivityInfo = false
    
    // Get sensitivity info for the first file (representative of the group)
    var groupSensitivity: SystemFolderInfo? {
        guard let firstFile = group.files.first else { return nil }
        return SystemFolderInfo.getInfo(for: firstFile.path)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggleExpand) {
                HStack(spacing: 12) {
                    // Expand/Collapse indicator
                    Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "a855f7"))
                    
                    // File icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "a855f7").opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: fileIconName)
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "a855f7"))
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(group.files.first?.name ?? "Unknown")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            // Sensitivity badge (clickable)
                            if let sensitivity = groupSensitivity {
                                SensitivityBadge(info: sensitivity, showingInfo: $showingSensitivityInfo)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Label("\(group.files.count) copies", systemImage: "doc.on.doc")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Label(formatBytes(group.size), systemImage: "internaldrive")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    // Potential savings badge
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Save \(formatBytes(group.potentialSavings))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "28c840"))
                        
                        Text("\(group.duplicateCount) duplicate\(group.duplicateCount == 1 ? "" : "s")")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "28c840").opacity(0.15))
                    )
                    
                    // Quick delete button
                    Button(action: { showingDeleteAlert = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash.fill")
                            Text("Delete Dupes")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
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
                    .help("Keep the first file, delete all duplicates")
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expanded file list
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                VStack(spacing: 0) {
                    ForEach(Array(group.files.enumerated()), id: \.element.id) { index, file in
                        DuplicateFileRow(
                            file: file,
                            isOriginal: index == 0,
                            isSelected: selectedFiles.contains(file.id),
                            onToggle: {
                                if selectedFiles.contains(file.id) {
                                    selectedFiles.remove(file.id)
                                } else {
                                    selectedFiles.insert(file.id)
                                }
                            },
                            groupId: group.id
                        )
                        
                        if index < group.files.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.05))
                                .padding(.leading, 60)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovering ? Color.white.opacity(0.05) : Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "a855f7").opacity(isExpanded ? 0.3 : 0.15), lineWidth: 1)
                )
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .alert("Delete Duplicates?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete \(group.duplicateCount) Duplicate\(group.duplicateCount == 1 ? "" : "s")", role: .destructive) {
                onDeleteAllDuplicates()
            }
        } message: {
            Text("This will keep the first file and delete \(group.duplicateCount) duplicate(s), saving \(formatBytes(group.potentialSavings)).")
        }
    }
    
    var fileIconName: String {
        guard let filename = group.files.first?.name else { return "doc.fill" }
        let ext = (filename as NSString).pathExtension.lowercased()
        
        switch ext {
        case "jpg", "jpeg", "png", "gif", "heic", "bmp", "tiff":
            return "photo.fill"
        case "mp4", "mov", "avi", "mkv", "wmv":
            return "film.fill"
        case "mp3", "wav", "aac", "flac", "m4a":
            return "music.note"
        case "pdf":
            return "doc.text.fill"
        case "zip", "rar", "7z", "tar", "gz":
            return "doc.zipper"
        case "doc", "docx":
            return "doc.richtext.fill"
        case "xls", "xlsx":
            return "tablecells.fill"
        default:
            return "doc.fill"
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Duplicate File Row

struct DuplicateFileRow: View {
    let file: ScannedFile
    let isOriginal: Bool
    let isSelected: Bool
    let onToggle: () -> Void
    let groupId: UUID
    
    @EnvironmentObject var fileScanner: FileScanner
    @State private var isHovering = false
    
    // Get sensitivity info for this specific file
    var fileSensitivity: SystemFolderInfo? {
        SystemFolderInfo.getInfo(for: file.path)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox (hidden for original)
            if isOriginal {
                // Original badge instead of checkbox
                Text("ORIGINAL")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color(hex: "28c840"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "28c840").opacity(0.2))
                    )
                    .frame(width: 60)
            } else {
                Button(action: onToggle) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isSelected ? Color(hex: "e94560") : Color.white.opacity(0.1))
                            .frame(width: 20, height: 20)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(width: 60)
            }
            
            // File path with sensitivity indicator
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(file.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                // Sensitivity indicator (clickable)
                if let sensitivity = fileSensitivity {
                    SensitivityIndicator(info: sensitivity)
                }
            }
            
            Spacer()
            
            // Modified date
            if let date = file.modifiedDate {
                Text(formatDate(date))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Actions
            HStack(spacing: 6) {
                Button(action: revealInFinder) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
                
                if !isOriginal {
                    Button(action: deleteFile) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "ff5f57"))
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color(hex: "ff5f57").opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    .help("Delete this duplicate")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isOriginal ? Color(hex: "28c840").opacity(0.05) : (isHovering ? Color.white.opacity(0.03) : Color.clear))
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func revealInFinder() {
        NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: "")
    }
    
    func deleteFile() {
        fileScanner.deleteDuplicateFile(file, from: groupId)
    }
}

// MARK: - Scanning View

struct DuplicateScanningView: View {
    let progress: Double
    let currentPath: String
    let groupsFound: Int
    
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated icon
            ZStack {
                // Pulsing rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color(hex: "a855f7").opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: 80 + CGFloat(i) * 30, height: 80 + CGFloat(i) * 30)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                            value: pulseAnimation
                        )
                }
                
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "a855f7"), Color(hex: "6366f1")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .onAppear {
                pulseAnimation = true
            }
            
            VStack(spacing: 12) {
                Text("Scanning for Duplicates...")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                // Progress bar
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "a855f7"), Color(hex: "6366f1")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                    }
                    .frame(height: 8)
                    .frame(maxWidth: 300)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text(currentPath)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 400)
                
                if groupsFound > 0 {
                    Text("\(groupsFound) duplicate groups found")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "28c840"))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View

struct DuplicatesEmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "a855f7").opacity(0.2), Color(hex: "6366f1").opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "a855f7"), Color(hex: "6366f1")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("No Duplicates Scanned Yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Click 'Scan for Duplicates' to find duplicate files\nand free up space on your Mac")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sensitivity Badge (Clickable with Popover)

struct SensitivityBadge: View {
    let info: SystemFolderInfo
    @Binding var showingInfo: Bool
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: { showingInfo.toggle() }) {
            HStack(spacing: 4) {
                Image(systemName: info.importance.icon)
                    .font(.system(size: 10, weight: .semibold))
                
                Text(info.importance.label)
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(info.importance.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(info.importance.color.opacity(isHovering ? 0.25 : 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(info.importance.color.opacity(0.3), lineWidth: 0.5)
                    )
            )
            .scaleEffect(isHovering ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .popover(isPresented: $showingInfo, arrowEdge: .bottom) {
            SensitivityInfoPopover(info: info)
        }
        .help("Click to learn why this is marked as \(info.importance.label)")
    }
}

// MARK: - Sensitivity Info Popover

struct SensitivityInfoPopover: View {
    let info: SystemFolderInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(info.importance.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: info.importance.icon)
                        .font(.system(size: 20))
                        .foregroundColor(info.importance.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(info.importance.label)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(info.importance.color)
                    
                    Text(info.name)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // What is this?
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.secondary)
                    Text("What is this?")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Text(info.description)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Why this classification?
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.secondary)
                    Text("Why \"\(info.importance.label)\"?")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Text(classificationReason)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Recommendation
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color(hex: "febc2e"))
                    Text("Recommendation")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Text(info.recommendation)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(info.importance.color.opacity(0.1))
            )
        }
        .padding(20)
        .frame(width: 360)
    }
    
    var classificationReason: String {
        switch info.importance {
        case .critical:
            return "These are core system files that macOS needs to function. Deleting them could break your Mac, prevent it from booting, or require a complete system reinstall."
        case .important:
            return "These files are used by applications or system features. Removing them may cause apps to malfunction, lose settings, or require reinstallation."
        case .caution:
            return "These are user files or app data that may be important to you. Review carefully before deleting to avoid losing personal data or settings."
        case .safe:
            return "These are temporary files, caches, or generated content that can be safely deleted. They will be recreated automatically when needed."
        }
    }
}

// MARK: - Small Sensitivity Indicator (for file rows)

struct SensitivityIndicator: View {
    let info: SystemFolderInfo
    @State private var showingInfo = false
    @State private var isHovering = false
    
    var body: some View {
        Button(action: { showingInfo.toggle() }) {
            Image(systemName: info.importance.icon)
                .font(.system(size: 12))
                .foregroundColor(info.importance.color)
                .padding(4)
                .background(
                    Circle()
                        .fill(info.importance.color.opacity(isHovering ? 0.3 : 0.15))
                )
                .scaleEffect(isHovering ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .popover(isPresented: $showingInfo, arrowEdge: .trailing) {
            SensitivityInfoPopover(info: info)
        }
        .help(info.importance.label)
    }
}

#Preview {
    DuplicatesView(
        selectedDuplicates: .constant([]),
        showingDeleteConfirmation: .constant(false)
    )
    .environmentObject(FileScanner.shared)
    .padding()
    .background(Color(hex: "1a1a2e"))
}

