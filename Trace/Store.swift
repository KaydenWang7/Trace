//
//  Store.swift
//  Trace
//

import StoreKit
import SwiftUI

@Observable @MainActor
class Store {
    var isPro: Bool = false
    var products: [Product] = []
    var isLoadingProducts: Bool = true
    
    private var updateListenerTask: Task<Void, Never>? = nil
    
    init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    func requestProducts() async {
        isLoadingProducts = true
        do {
            let storeProducts = try await Product.products(for: ["com.KaydenWang.Trace.Pro"])
            self.products = storeProducts
        } catch {
            print("Failed product request from the App Store server: \(error)")
        }
        isLoadingProducts = false
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Check whether the transaction is verified.
            let transaction = try checkVerified(verification)
            
            // The transaction is verified. Deliver content to the user.
            await updateCustomerProductStatus()
            
            // Always finish a transaction.
            await transaction.finish()
        case .userCancelled, .pending:
            break
        default:
            break
        }
    }
    
    func updateCustomerProductStatus() async {
        var hasPro = false
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            if transaction.productID == "com.KaydenWang.Trace.Pro" {
                hasPro = true
            }
        }
        
        self.isPro = hasPro
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            print("Failed to sync app store: \(error)")
        }
    }
    
    nonisolated private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached {
            // Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // Deliver products to the user.
                    await self.updateCustomerProductStatus()
                    
                    // Always finish a transaction.
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            // StoreKit parses the JWS, but it fails verification.
            throw StoreError.failedVerification
        case .verified(let safe):
            // The result is verified. Return the unwrapped value.
            return safe
        }
    }
}

public enum StoreError: Error {
    case failedVerification
}
