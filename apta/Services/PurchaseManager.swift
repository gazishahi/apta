import Foundation
import StoreKit
import Combine
import WidgetKit

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    private let productID = "Gazi.apta.pro"
    private let isProKey = "isProUser"

    @Published private(set) var isProUser: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var product: Product?
    @Published var errorMessage: String?
    @Published private(set) var restoreMessage: String?

    private var updateTask: Task<Void, Never>?
    private var startupTask: Task<Void, Never>?

    private var defaults: UserDefaults { SharedDefaults.suite }

    init() {
        loadStoredPurchase()
        updateTask = Task { await listenForTransactions() }
        startupTask = Task {
            await loadProduct()
            _ = await refreshEntitlements()
        }
    }

    deinit {
        updateTask?.cancel()
        startupTask?.cancel()
    }

    private func loadStoredPurchase() {
        isProUser = SharedDefaults.isProUser
    }

    func loadProduct() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: [productID])
            product = storeProducts.first
            if product == nil {
                errorMessage = "Product '\(productID)' not found. Check App Store Connect."
            }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }

    func purchase() async -> Bool {
        guard let product = product else {
            errorMessage = "Product not available"
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await handleVerifiedTransaction(transaction)
                    return true
                case .unverified:
                    errorMessage = "Transaction verification failed"
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                errorMessage = "Purchase is pending"
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func restorePurchases() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        restoreMessage = nil

        do {
            try await AppStore.sync()
            let restored = await refreshEntitlements()
            if !restored {
                errorMessage = "No active apta Pro purchase was found."
            }
            restoreMessage = restored ? "Your apta Pro purchase was restored." : errorMessage
            return restored
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            restoreMessage = errorMessage
            return false
        }
    }

    func clearRestoreMessage() {
        restoreMessage = nil
    }

    /// Reconciles cached state with StoreKit's current, verified entitlements.
    @discardableResult
    func refreshEntitlements() async -> Bool {
        var hasActiveProEntitlement = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == productID,
                  transaction.revocationDate == nil else {
                continue
            }
            hasActiveProEntitlement = true
            break
        }

        publishProStatus(hasActiveProEntitlement)
        return hasActiveProEntitlement
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            switch result {
            case .verified(let transaction):
                await handleVerifiedTransaction(transaction)
            case .unverified:
                break
            }
        }
    }

    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        if transaction.productID == productID {
            publishProStatus(transaction.revocationDate == nil)
        }
        await transaction.finish()
    }

    private func publishProStatus(_ isPro: Bool) {
        isProUser = isPro
        defaults.set(isPro, forKey: isProKey)
        defaults.set(Date().timeIntervalSince1970, forKey: SharedDefaults.proStatusUpdatedAtKey)
        WidgetCenter.shared.reloadAllTimelines()
        WatchSyncService.shared.sendSettingsUpdate()
    }
}
