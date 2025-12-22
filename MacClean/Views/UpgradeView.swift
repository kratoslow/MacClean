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
            
            VStack(spacing: 32) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Crown icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "ffd700").opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "ffd700"), Color(hex: "ff8c00")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(hex: "ffd700").opacity(0.5), radius: 20)
                }
                
                // Title
                VStack(spacing: 12) {
                    Text("Upgrade to Pro")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Unlock unlimited scans forever")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Features
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "infinity", text: "Unlimited file scans")
                    FeatureRow(icon: "bolt.fill", text: "Priority scanning speed")
                    FeatureRow(icon: "heart.fill", text: "Support indie development")
                    FeatureRow(icon: "arrow.up.circle.fill", text: "Free updates forever")
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 32)
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
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                        Text("0.99")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Text("One-time purchase • No subscription")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Purchase button
                Button(action: purchase) {
                    HStack(spacing: 12) {
                        if isPurchasing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isPurchasing ? "Processing..." : "Unlock Pro Now")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "ffd700"), Color(hex: "ff8c00")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color(hex: "ffd700").opacity(0.4), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(isPurchasing)
                .padding(.horizontal, 40)
                
                // Restore purchases
                Button(action: restore) {
                    Text("Restore Previous Purchase")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .underline()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Free scans remaining
                if storeManager.remainingFreeScans > 0 {
                    Text("You have \(storeManager.remainingFreeScans) free scan(s) remaining")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.bottom, 20)
                }
            }
            .padding()
        }
        .frame(width: 480, height: 680)
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
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "ffd700"))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    UpgradeView()
        .environmentObject(StoreManager.shared)
}

