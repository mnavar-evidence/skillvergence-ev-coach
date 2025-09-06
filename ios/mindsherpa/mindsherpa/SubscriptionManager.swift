//
//  SubscriptionManager.swift
//  mindsherpa
//
//  Created by Claude on 9/4/25.
//

import SwiftUI
import StoreKit

@available(iOS 15.0, *)
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Published Properties
    @Published var currentTier: SubscriptionTier = .free
    @Published var hasActiveSubscription: Bool = false
    @Published var isLoading: Bool = false
    @Published var showPaywall: Bool = false
    
    // Authorization code access
    private let authorizationAccessKey = "premium_authorization_granted"
    
    // MARK: - Subscription Products
    private var subscriptionProducts: [Product] = []
    private let productIds = [
        "com.skillvergence.premium.monthly",
        "com.skillvergence.premium.yearly"
    ]
    
    private init() {
        // Check for existing authorization access
        checkAuthorizationAccess()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    // MARK: - Public Methods
    
    func checkAdvancedAccess(for courseId: String) -> Bool {
        return hasActiveSubscription
    }
    
    func requestAdvancedAccess() {
        if !hasActiveSubscription {
            showPaywall = true
        }
    }
    
    func canAccessAdvancedContent() -> Bool {
        return hasActiveSubscription
    }
    
    // MARK: - StoreKit Integration
    
    private func loadProducts() async {
        do {
            subscriptionProducts = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    private func updateSubscriptionStatus() async {
        var validSubscriptions: [StoreKit.Transaction] = []
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productType == .autoRenewable {
                    validSubscriptions.append(transaction)
                }
            }
        }
        
        let hasStoreKitSubscription = !validSubscriptions.isEmpty
        let hasAuthorizationAccess = UserDefaults.standard.bool(forKey: authorizationAccessKey)
        
        // User has premium access if they have either a StoreKit subscription OR authorization code access
        hasActiveSubscription = hasStoreKitSubscription || hasAuthorizationAccess
        currentTier = hasActiveSubscription ? .premium : .free
    }
    
    func purchase(_ product: Product) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                hasActiveSubscription = true
                currentTier = .premium
                showPaywall = false
                await transaction.finish()
            }
        case .userCancelled:
            break
        case .pending:
            break
        default:
            break
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    // MARK: - Helper Methods
    
    func getMonthlyProduct() -> Product? {
        return subscriptionProducts.first { $0.id == "com.skillvergence.premium.monthly" }
    }
    
    func getYearlyProduct() -> Product? {
        return subscriptionProducts.first { $0.id == "com.skillvergence.premium.yearly" }
    }
    
    // MARK: - Authorization Code Access
    
    func grantPremiumAccess() {
        UserDefaults.standard.set(true, forKey: authorizationAccessKey)
        hasActiveSubscription = true
        currentTier = .premium
        showPaywall = false
    }
    
    func revokePremiumAccess() {
        UserDefaults.standard.set(false, forKey: authorizationAccessKey)
        checkAuthorizationAccess()
    }
    
    private func checkAuthorizationAccess() {
        let hasAuthorizationAccess = UserDefaults.standard.bool(forKey: authorizationAccessKey)
        if hasAuthorizationAccess {
            hasActiveSubscription = true
            currentTier = .premium
        }
    }
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, CaseIterable {
    case free = "free"
    case premium = "premium"
    
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .premium:
            return "Premium"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "Basic courses (1.1-1.7, 2.1-2.4, etc.)",
                "Standard certificates",
                "Basic XP system",
                "Community access"
            ]
        case .premium:
            return [
                "All Free features",
                "Advanced deep-dive courses",
                "Expert-level certificates", 
                "2x XP multiplier",
                "Premium badges",
                "Priority support"
            ]
        }
    }
    
    var xpMultiplier: Double {
        switch self {
        case .free:
            return 1.0
        case .premium:
            return 2.0
        }
    }
}