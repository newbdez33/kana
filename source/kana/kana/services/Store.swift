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
        case .productUnavailable: return "The product is not available right now."
        case .unverified: return "The purchase could not be verified."
        }
    }
}

@MainActor
final class Store {

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
    private var updatesTask: Task<Void, Never>?

    private init() {
        adsRemoved = UserDefaults.standard.bool(forKey: Store.adsRemovedKey)
    }

    /// Call once at launch.
    func start() {
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

    /// Returns true when the purchase completed, false when cancelled or pending.
    func purchaseCoffee() async throws -> Bool {
        if coffeeProduct == nil { await loadProduct() }
        guard let product = coffeeProduct else { throw StoreError.productUnavailable }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw StoreError.unverified }
            adsRemoved = true
            await transaction.finish()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
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
