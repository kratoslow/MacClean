//
//  StoreManager.swift
//  ModernClean
//

import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    // Product ID for the one-time purchase
    private let productID = "com.idevelopmentllc.ModernClean.pro.lifetime"
    
    @Published var isPurchased = false
    @Published var remainingFreeScans: Int = 5
    @Published var product: Product?
    @Published var purchaseError: String?
    
    private let freeScansKey = "freeScansRemaining"
    private let purchasedKey = "proPurchased"
    
    private init() {
        // Load saved state
        loadSavedState()
        
        // Start listening for transactions
        Task {
            await listenForTransactions()
            await loadProducts()
            await checkPurchaseStatus()
        }
    }
    
    private func loadSavedState() {
        // Check if we have a saved purchase state
        if UserDefaults.standard.bool(forKey: purchasedKey) {
            isPurchased = true
        }
        
        // Load remaining free scans (default to 5 if not set)
        if UserDefaults.standard.object(forKey: freeScansKey) == nil {
            UserDefaults.standard.set(5, forKey: freeScansKey)
            remainingFreeScans = 5
        } else {
            remainingFreeScans = UserDefaults.standard.integer(forKey: freeScansKey)
        }
    }
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [productID])
            if let product = products.first {
                self.product = product
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase() async throws {
        guard let product = product else {
            // If no product loaded, simulate purchase for development
            #if DEBUG
            await MainActor.run {
                self.isPurchased = true
                UserDefaults.standard.set(true, forKey: self.purchasedKey)
            }
            return
            #else
            throw PurchaseError.productNotFound
            #endif
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            
            await MainActor.run {
                self.isPurchased = true
                UserDefaults.standard.set(true, forKey: self.purchasedKey)
            }
            
        case .userCancelled:
            throw PurchaseError.userCancelled
            
        case .pending:
            throw PurchaseError.pending
            
        @unknown default:
            throw PurchaseError.unknown
        }
    }
    
    func restorePurchases() async throws {
        // Sync with App Store
        try await AppStore.sync()
        
        // Check for existing purchases
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == productID {
                    await MainActor.run {
                        self.isPurchased = true
                        UserDefaults.standard.set(true, forKey: self.purchasedKey)
                    }
                    return
                }
            }
        }
    }
    
    private func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == productID {
                    await MainActor.run {
                        self.isPurchased = true
                        UserDefaults.standard.set(true, forKey: self.purchasedKey)
                    }
                }
            }
        }
    }
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                if transaction.productID == productID {
                    await MainActor.run {
                        self.isPurchased = true
                        UserDefaults.standard.set(true, forKey: self.purchasedKey)
                    }
                }
                await transaction.finish()
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    func useFreeScan() {
        guard remainingFreeScans > 0 else { return }
        
        remainingFreeScans -= 1
        UserDefaults.standard.set(remainingFreeScans, forKey: freeScansKey)
    }
    
    func canScan() -> Bool {
        return isPurchased || remainingFreeScans > 0
    }
    
    // For testing/development - reset free scans
    func resetFreeScans() {
        remainingFreeScans = 5
        UserDefaults.standard.set(5, forKey: freeScansKey)
    }
    
    #if DEBUG
    // Debug function to reset purchase status
    func resetPurchase() {
        isPurchased = false
        UserDefaults.standard.set(false, forKey: purchasedKey)
        resetFreeScans()
    }
    #endif
}

enum PurchaseError: LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case verificationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found. Please try again later."
        case .userCancelled:
            return "Purchase was cancelled."
        case .pending:
            return "Purchase is pending approval."
        case .verificationFailed:
            return "Purchase verification failed."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

