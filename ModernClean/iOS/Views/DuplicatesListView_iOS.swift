//
//  DuplicatesListView_iOS.swift
//  ModernClean (iOS)
//
//  iOS duplicates list view
//

import SwiftUI

struct DuplicatesListView_iOS: View {
    @EnvironmentObject var fileScanner: FileScanner
    
    @State private var selectedDuplicates: Set<ScannedFile.ID> = []
    @State private var showingDeleteConfirmation = false
    @State private var expandedGroups: Set<UUID> = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Scanning progress
            if fileScanner.isScanningDuplicates {
                DuplicateScanningProgress_iOS()
            }
            
            // Summary header
            if !fileScanner.duplicateGroups.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(fileScanner.duplicateGroups.count) duplicate groups")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                        
                        Text("Potential savings: \(formatBytes(fileScanner.totalDuplicateSavings))")
                            .font(.caption)
                            .foregroundColor(Color(hex: "a855f7"))
                    }
                    
                    Spacer()
                    
                    if !selectedDuplicates.isEmpty {
                        Text("\(selectedDuplicates.count) selected")
                            .font(.caption.weight(.medium))
                            .foregroundColor(Color(hex: "e94560"))
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
            }
            
            // Duplicate groups list
            List {
                ForEach(fileScanner.duplicateGroups) { group in
                    DuplicateGroupSection_iOS(
                        group: group,
                        isExpanded: expandedGroups.contains(group.id),
                        selectedDuplicates: $selectedDuplicates,
                        onToggleExpand: { toggleExpand(group) },
                        onDeleteFile: { file in
                            fileScanner.deleteDuplicateFile(file, from: group.id)
                        },
                        onKeepFirst: {
                            fileScanner.deleteAllDuplicatesInGroup(group, keepFirst: true)
                        }
                    )
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            
            // Selection toolbar
            if !selectedDuplicates.isEmpty {
                SelectionToolbar_iOS(
                    count: selectedDuplicates.count,
                    onDelete: { showingDeleteConfirmation = true },
                    onClear: { selectedDuplicates.removeAll() }
                )
            }
        }
        .alert("Delete Selected Duplicates?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedDuplicates()
            }
        } message: {
            Text("This action cannot be undone. \(selectedDuplicates.count) file(s) will be deleted.")
        }
    }
    
    func toggleExpand(_ group: DuplicateGroup) {
        if expandedGroups.contains(group.id) {
            expandedGroups.remove(group.id)
        } else {
            expandedGroups.insert(group.id)
        }
    }
    
    func deleteSelectedDuplicates() {
        for group in fileScanner.duplicateGroups {
            for file in group.files {
                if selectedDuplicates.contains(file.id) {
                    fileScanner.deleteDuplicateFile(file, from: group.id)
                }
            }
        }
        selectedDuplicates.removeAll()
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Duplicate Group Section

struct DuplicateGroupSection_iOS: View {
    let group: DuplicateGroup
    let isExpanded: Bool
    @Binding var selectedDuplicates: Set<ScannedFile.ID>
    let onToggleExpand: () -> Void
    let onDeleteFile: (ScannedFile) -> Void
    let onKeepFirst: () -> Void
    
    var body: some View {
        Section {
            if isExpanded {
                ForEach(Array(group.files.enumerated()), id: \.element.id) { index, file in
                    DuplicateFileRow_iOS(
                        file: file,
                        isOriginal: index == 0,
                        isSelected: selectedDuplicates.contains(file.id)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSelection(file)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDeleteFile(file)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowBackground(
                        selectedDuplicates.contains(file.id)
                            ? Color(hex: "a855f7").opacity(0.2)
                            : Color.white.opacity(0.02)
                    )
                    .listRowSeparatorTint(Color.white.opacity(0.1))
                }
            }
        } header: {
            DuplicateGroupHeader_iOS(
                group: group,
                isExpanded: isExpanded,
                onToggle: onToggleExpand,
                onKeepFirst: onKeepFirst
            )
        }
    }
    
    func toggleSelection(_ file: ScannedFile) {
        if selectedDuplicates.contains(file.id) {
            selectedDuplicates.remove(file.id)
        } else {
            selectedDuplicates.insert(file.id)
        }
    }
}

// MARK: - Duplicate Group Header

struct DuplicateGroupHeader_iOS: View {
    let group: DuplicateGroup
    let isExpanded: Bool
    let onToggle: () -> Void
    let onKeepFirst: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.5))
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "a855f7").opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "a855f7"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.files.first?.name ?? "Unknown")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            Text("\(group.files.count) copies")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("Save: \(formatBytes(group.potentialSavings))")
                                .font(.caption.weight(.medium))
                                .foregroundColor(Color(hex: "28c840"))
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Quick action: Keep first only
            Button(action: onKeepFirst) {
                Text("Keep 1")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(hex: "a855f7"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: "a855f7").opacity(0.2))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Duplicate File Row

struct DuplicateFileRow_iOS: View {
    let file: ScannedFile
    let isOriginal: Bool
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Original badge or selection
            if isOriginal {
                Text("KEEP")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: "28c840"))
                    .clipShape(Capsule())
            } else if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "a855f7"))
            } else {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
            }
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(shortenedPath)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                
                Text(formatBytes(file.size))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.leading, 20)
        .opacity(isOriginal ? 0.7 : 1.0)
    }
    
    var shortenedPath: String {
        let components = file.path.components(separatedBy: "/")
        if components.count > 3 {
            return ".../" + components.suffix(3).joined(separator: "/")
        }
        return file.path
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Scanning Progress

struct DuplicateScanningProgress_iOS: View {
    @EnvironmentObject var fileScanner: FileScanner
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .trim(from: 0, to: fileScanner.duplicateScanProgress)
                        .stroke(Color(hex: "a855f7"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(-90))
                }
                
                Text("Scanning for duplicates... \(Int(fileScanner.duplicateScanProgress * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Button("Stop") {
                    fileScanner.stopDuplicateScan()
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color(hex: "a855f7"))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
    }
}

#Preview {
    DuplicatesListView_iOS()
        .environmentObject(FileScanner.shared)
        .background(Color(hex: "1a1a2e"))
}
