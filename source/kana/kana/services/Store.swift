//
//  Store.swift
//  kana
//
//  "Buy me a coffee" non-consumable purchase that removes ads (StoreKit 2).
//

import Foundation
import StoreKit

extension Notification.Name {
    static let adsRemovedDidChange = Notification.Name("kana.adsRemovedDidChange")
}

enum StoreError: LocalizedError {
    case productUnavailable
    case unverified

    var errorDescription: String? {
        switch self {
        case .productUnavailable: return .coffeeUnavailable
        case .unverified: return .purchaseUnverified
        }
    }
}

enum CoffeePurchaseOutcome {
    case purchased, cancelled, pending
}

@MainActor
protocol CoffeeStore: AnyObject {
    var adsRemoved: Bool { get }
    var coffeePrice: String? { get }
    func loadProduct() async
    func purchaseCoffee() async throws -> CoffeePurchaseOutcome
    func restore() async throws -> Bool
}

@MainActor
final class Store: CoffeeStore {

    static let shared = Store()
    static let coffeeProductID = "com.salmonapps.app.kana.coffee"

    private static let adsRemovedKey = "user.purchase.adsRemoved"

    private(set) var adsRemoved: Bool {
        didSet {
            guard adsRemoved != oldValue else { return }
            UserDefaults.standard.set(adsRemoved, forKey: Store.adsRemovedKey)
            NotificationCenter.default.post(name: .adsRemovedDidChange, object: nil)
        }
    }
    private(set) var coffeeProduct: Product?
    var coffeePrice: String? { coffeeProduct?.displayPrice }
    private var updatesTask: Task<Void, Never>?

    private init() {
        adsRemoved = UserDefaults.standard.bool(forKey: Store.adsRemovedKey)
    }

    /// Call once at launch.
    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task {
            await refreshEntitlements()
            await loadProduct()
        }
    }

    func loadProduct() async {
        coffeeProduct = try? await Product.products(for: [Store.coffeeProductID]).first
    }

    func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Store.coffeeProductID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        adsRemoved = owned
    }

    func purchaseCoffee() async throws -> CoffeePurchaseOutcome {
        if coffeeProduct == nil { await loadProduct() }
        guard let product = coffeeProduct else { throw StoreError.productUnavailable }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw StoreError.unverified }
            adsRemoved = true
            await transaction.finish()
            return .purchased
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .cancelled
        }
    }

    /// Returns true when a previous purchase was found.
    func restore() async throws -> Bool {
        try await AppStore.sync()
        await refreshEntitlements()
        return adsRemoved
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Store.coffeeProductID {
            adsRemoved = transaction.revocationDate == nil
        }
        await transaction.finish()
    }
}
