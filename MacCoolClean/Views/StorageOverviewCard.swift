//
//  StorageOverviewCard.swift
//  MacCoolClean
//

import SwiftUI

struct StorageOverviewCard: View {
    @State private var totalSpace: Int64 = 0
    @State private var freeSpace: Int64 = 0
    @State private var usedSpace: Int64 = 0
    @State private var animatedProgress: Double = 0
    
    var usedPercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace)
    }
    
    var body: some View {
        HStack(spacing: 24) {
            // Circular progress
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 12)
                    .frame(width: 100, height: 100)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        AngularGradient(
                            colors: progressColors,
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                // Center content
                VStack(spacing: 2) {
                    Text("\(Int(usedPercentage * 100))%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Used")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Stats
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 24) {
                    StatItem(
                        icon: "internaldrive.fill",
                        label: "Total",
                        value: formatBytes(totalSpace),
                        color: Color(hex: "a855f7")
                    )
                    
                    StatItem(
                        icon: "square.stack.3d.up.fill",
                        label: "Used",
                        value: formatBytes(usedSpace),
                        color: Color(hex: "e94560")
                    )
                    
                    StatItem(
                        icon: "checkmark.circle.fill",
                        label: "Free",
                        value: formatBytes(freeSpace),
                        color: Color(hex: "28c840")
                    )
                }
            }
            
            Spacer()
            
            // Status indicator
            VStack(spacing: 8) {
                Image(systemName: statusIcon)
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: statusColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.trailing, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            loadStorageInfo()
        }
    }
    
    var progressColors: [Color] {
        if usedPercentage > 0.9 {
            return [Color(hex: "ff5f57"), Color(hex: "ff8a80")]
        } else if usedPercentage > 0.7 {
            return [Color(hex: "febc2e"), Color(hex: "ffd54f")]
        } else {
            return [Color(hex: "28c840"), Color(hex: "69f0ae")]
        }
    }
    
    var statusIcon: String {
        if usedPercentage > 0.9 {
            return "exclamationmark.triangle.fill"
        } else if usedPercentage > 0.7 {
            return "exclamationmark.circle.fill"
        } else {
            return "checkmark.seal.fill"
        }
    }
    
    var statusColors: [Color] {
        if usedPercentage > 0.9 {
            return [Color(hex: "ff5f57"), Color(hex: "ff8a80")]
        } else if usedPercentage > 0.7 {
            return [Color(hex: "febc2e"), Color(hex: "ffd54f")]
        } else {
            return [Color(hex: "28c840"), Color(hex: "69f0ae")]
        }
    }
    
    var statusText: String {
        if usedPercentage > 0.9 {
            return "Critical"
        } else if usedPercentage > 0.7 {
            return "Warning"
        } else {
            return "Healthy"
        }
    }
    
    func loadStorageInfo() {
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
           let total = attributes[.systemSize] as? Int64,
           let free = attributes[.systemFreeSize] as? Int64 {
            totalSpace = total
            freeSpace = free
            usedSpace = total - free
            
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = usedPercentage
            }
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    StorageOverviewCard()
        .padding()
        .background(Color(hex: "1a1a2e"))
}

