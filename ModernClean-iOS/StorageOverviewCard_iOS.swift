//
//  StorageOverviewCard_iOS.swift
//  ModernClean (iOS)
//
//  iOS-optimized storage overview card
//

import SwiftUI

struct StorageOverviewCard_iOS: View {
    @State private var totalSpace: Int64 = 0
    @State private var freeSpace: Int64 = 0
    @State private var usedSpace: Int64 = 0
    @State private var animatedProgress: Double = 0
    
    var usedPercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 10)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        AngularGradient(
                            colors: progressColors,
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(Int(usedPercentage * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Used")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Stats
            VStack(alignment: .leading, spacing: 12) {
                StatRow_iOS(label: "Total", value: formatBytes(totalSpace), color: Color(hex: "a855f7"))
                StatRow_iOS(label: "Used", value: formatBytes(usedSpace), color: Color(hex: "e94560"))
                StatRow_iOS(label: "Free", value: formatBytes(freeSpace), color: Color(hex: "28c840"))
            }
            
            Spacer()
            
            // Status
            VStack(spacing: 4) {
                Image(systemName: statusIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: statusColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(statusText)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
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
        // On iOS, we need to check the home directory
        let homeDir = NSHomeDirectory()
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: homeDir),
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

struct StatRow_iOS: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    StorageOverviewCard_iOS()
        .padding()
        .background(Color(hex: "1a1a2e"))
}
