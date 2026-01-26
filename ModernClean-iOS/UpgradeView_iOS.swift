//
//  UpgradeView_iOS.swift
//  ModernClean (iOS)
//
//  iOS upgrade/purchase view
//

import SwiftUI
import StoreKit

struct UpgradeView_iOS: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) var dismiss
    
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e"),
                    Color(hex: "0f3460")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.top, 8)
                    
                    // Crown icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(hex: "ffd700").opacity(0.3), Color.clear],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 140, height: 140)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "ffd700"), Color(hex: "ff8c00")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(hex: "ffd700").opacity(0.5), radius: 16)
                    }
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Upgrade to Pro")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Unlock unlimited scans forever")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow_iOS(icon: "infinity", text: "Unlimited file scans")
                        FeatureRow_iOS(icon: "bolt.fill", text: "Priority scanning speed")
                        FeatureRow_iOS(icon: "heart.fill", text: "Support indie development")
                        FeatureRow_iOS(icon: "arrow.up.circle.fill", text: "Free updates forever")
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
                    
                    // Price
                    VStack(spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("$")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                            Text("4.99")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Text("One-time purchase • No subscription")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    // Purchase button
                    Button(action: purchase) {
                        HStack(spacing: 10) {
                            if isPurchasing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(isPurchasing ? "Processing..." : "Unlock Pro Now")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "ffd700"), Color(hex: "ff8c00")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color(hex: "ffd700").opacity(0.4), radius: 8, y: 4)
                    }
                    .disabled(isPurchasing)
                    
                    // Restore purchases
                    Button(action: restore) {
                        Text("Restore Previous Purchase")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .underline()
                    }
                    
                    // Free scans remaining
                    VStack(spacing: 8) {
                        if storeManager.remainingFreeScans > 0 {
                            Text("You have \(storeManager.remainingFreeScans) free scan\(storeManager.remainingFreeScans == 1 ? "" : "s") remaining")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                        
                        Button(action: { dismiss() }) {
                            Text("Maybe Later")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color(hex: "e94560"))
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    func purchase() {
        isPurchasing = true
        
        Task {
            do {
                try await storeManager.purchase()
                await MainActor.run {
                    isPurchasing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    func restore() {
        isPurchasing = true
        
        Task {
            do {
                try await storeManager.restorePurchases()
                await MainActor.run {
                    isPurchasing = false
                    if storeManager.isPurchased {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = "Could not restore purchases. Please try again."
                    showError = true
                }
            }
        }
    }
}

struct FeatureRow_iOS: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "ffd700"))
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    UpgradeView_iOS()
        .environmentObject(StoreManager.shared)
}
