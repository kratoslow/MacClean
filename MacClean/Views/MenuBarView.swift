//
//  MenuBarView.swift
//  MacClean
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var fileScanner: FileScanner
    
    @State private var totalSpace: Int64 = 0
    @State private var freeSpace: Int64 = 0
    @State private var usedSpace: Int64 = 0
    
    var usedPercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace) * 100
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "e94560"), Color(hex: "ff6b6b")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("MacClean")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                
                Spacer()
                
                if storeManager.isPurchased {
                    Label("Pro", systemImage: "crown.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "ffd700"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: "ffd700").opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // Storage visualization
            VStack(spacing: 12) {
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: usedPercentage / 100)
                        .stroke(
                            AngularGradient(
                                colors: progressColors,
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(Int(usedPercentage))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("Used")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
                
                // Stats
                HStack(spacing: 20) {
                    VStack(spacing: 2) {
                        Text("Used")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(formatBytes(usedSpace))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 24)
                    
                    VStack(spacing: 2) {
                        Text("Free")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(formatBytes(freeSpace))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(statusColor)
                    }
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 24)
                    
                    VStack(spacing: 2) {
                        Text("Total")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(formatBytes(totalSpace))
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
            }
            .padding(16)
            
            Divider()
            
            // Status message
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Divider()
            
            // Actions
            VStack(spacing: 0) {
                MenuBarButton(icon: "arrow.clockwise", title: "Refresh") {
                    loadStorageInfo()
                }
                
                MenuBarButton(icon: "magnifyingglass", title: "Open MacClean") {
                    openMainWindow()
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                MenuBarButton(icon: "xmark.circle", title: "Quit MacClean") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 260)
        .onAppear {
            loadStorageInfo()
        }
    }
    
    var progressColors: [Color] {
        if usedPercentage > 90 {
            return [Color(hex: "ff5f57"), Color(hex: "ff8a80")]
        } else if usedPercentage > 70 {
            return [Color(hex: "febc2e"), Color(hex: "ffd54f")]
        } else {
            return [Color(hex: "28c840"), Color(hex: "69f0ae")]
        }
    }
    
    var statusColor: Color {
        if usedPercentage > 90 {
            return Color(hex: "ff5f57")
        } else if usedPercentage > 70 {
            return Color(hex: "febc2e")
        } else {
            return Color(hex: "28c840")
        }
    }
    
    var statusMessage: String {
        if usedPercentage > 90 {
            return "Storage almost full! Clean up needed."
        } else if usedPercentage > 70 {
            return "Storage getting low. Consider cleaning."
        } else {
            return "Storage healthy."
        }
    }
    
    func loadStorageInfo() {
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
           let total = attributes[.systemSize] as? Int64,
           let free = attributes[.systemFreeSize] as? Int64 {
            totalSpace = total
            freeSpace = free
            usedSpace = total - free
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func openMainWindow() {
        if let window = NSApplication.shared.windows.first(where: { $0.title.isEmpty || $0.title == "MacClean" }) {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        } else {
            // Try to bring any window to front
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}

struct MenuBarButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                Text(title)
                    .font(.system(size: 13))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Color.accentColor.opacity(0.2) : Color.clear)
            )
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(StoreManager.shared)
        .environmentObject(FileScanner.shared)
}

