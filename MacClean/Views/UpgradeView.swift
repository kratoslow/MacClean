//
//  UpgradeView.swift
//  MacClean
//

import SwiftUI
import StoreKit

struct UpgradeView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) var dismiss
    
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
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
            
            // Main content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Spacer for close button area
                    Spacer()
                        .frame(height: 20)
                    
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
                            .font(.system(size: 52))
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
                    VStack(spacing: 6) {
                        Text("Upgrade to Pro")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Unlock unlimited scans forever")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "infinity", text: "Unlimited file scans")
                        FeatureRow(icon: "bolt.fill", text: "Priority scanning speed")
                        FeatureRow(icon: "heart.fill", text: "Support indie development")
                        FeatureRow(icon: "arrow.up.circle.fill", text: "Free updates forever")
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    
                    // Price
                    VStack(spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("$")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                            Text("0.99")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Text("One-time purchase • No subscription")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    // Purchase button
                    Button(action: purchase) {
                        HStack(spacing: 10) {
                            if isPurchasing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isPurchasing ? "Processing..." : "Unlock Pro Now")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "ffd700"), Color(hex: "ff8c00")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color(hex: "ffd700").opacity(0.4), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing)
                    .padding(.horizontal, 16)
                    
                    // Restore purchases
                    Button(action: restore) {
                        Text("Restore Previous Purchase")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .underline()
                    }
                    .buttonStyle(.plain)
                    
                    // Free scans remaining & skip option
                    VStack(spacing: 8) {
                        if storeManager.remainingFreeScans > 0 {
                            Text("You have \(storeManager.remainingFreeScans) free scan\(storeManager.remainingFreeScans == 1 ? "" : "s") remaining")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        
                        Button(action: { dismiss() }) {
                            Text("Maybe Later")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "e94560"))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 24)
            }
            
            // Close button - ALWAYS visible, fixed position
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
            .padding(.trailing, 12)
            .help("Close")
        }
        .frame(width: 380, height: 540)
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

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "ffd700"))
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    UpgradeView()
        .environmentObject(StoreManager.shared)
}
