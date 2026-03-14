import Foundation
import StoreKit
import Combine

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    private let productID = "Gazi.apta.pro"
    private let isProKey = "isProUser"

    @Published private(set) var isProUser: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var product: Product?
    @Published var errorMessage: String?

    private var updateTask: Task<Void, Never>?

    private var defaults: UserDefaults { SharedDefaults.suite }

    init() {
        loadStoredPurchase()
        updateTask = Task {
            await loadProduct()
            await listenForTransactions()
        }
    }

    deinit {
        updateTask?.cancel()
    }

    private func loadStoredPurchase() {
        isProUser = defaults.bool(forKey: isProKey)
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

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
        } catch {
            errorMessage = "Failed to restore purchases"
        }
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
            isProUser = transaction.revocationDate == nil
            defaults.set(isProUser, forKey: isProKey)
        }
        await transaction.finish()
    }
}
