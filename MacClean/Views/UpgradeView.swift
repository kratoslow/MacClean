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
            
            VStack(spacing: 0) {
                // Close button - fixed at top
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Close")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
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
                                .frame(width: 160, height: 160)
                            
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
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Features
                        VStack(alignment: .leading, spacing: 14) {
                            FeatureRow(icon: "infinity", text: "Unlimited file scans")
                            FeatureRow(icon: "bolt.fill", text: "Priority scanning speed")
                            FeatureRow(icon: "heart.fill", text: "Support indie development")
                            FeatureRow(icon: "arrow.up.circle.fill", text: "Free updates forever")
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 28)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        
                        // Price
                        VStack(spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("$")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                Text("0.99")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            Text("One-time purchase • No subscription")
                                .font(.system(size: 12))
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
                                    .font(.system(size: 17, weight: .bold))
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
                            .shadow(color: Color(hex: "ffd700").opacity(0.4), radius: 10, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(isPurchasing)
                        .padding(.horizontal, 24)
                        
                        // Restore purchases
                        Button(action: restore) {
                            Text("Restore Previous Purchase")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .underline()
                        }
                        .buttonStyle(.plain)
                        
                        // Free scans remaining
                        if storeManager.remainingFreeScans > 0 {
                            Text("You have \(storeManager.remainingFreeScans) free scan\(storeManager.remainingFreeScans == 1 ? "" : "s") remaining")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        
                        // Skip for now
                        if storeManager.remainingFreeScans > 0 {
                            Button(action: { dismiss() }) {
                                Text("Continue with Free Trial")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(hex: "e94560"))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .frame(width: 420, height: 580)
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
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "ffd700"))
                .frame(width: 22)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    UpgradeView()
        .environmentObject(StoreManager.shared)
}
