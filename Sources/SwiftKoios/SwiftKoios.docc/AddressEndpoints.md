# Address Endpoints

Query Cardano address information, UTxOs, transactions, and native assets.

## Overview

Address endpoints provide comprehensive information about Cardano addresses, including balance, transaction history, UTxO sets, and associated native assets. These endpoints are essential for wallet applications and address monitoring.

## Address Information

### Get Basic Address Info

Query fundamental address information:

```swift
func getAddressInfo(address: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.addressInfo(
        body: .init([.init(address)])
    )
    
    let addresses = try response.ok.body.json
    
    for addressInfo in addresses {
        print("Address: \\(addressInfo.address ?? "unknown")")
        print("Balance: \\(addressInfo.balance ?? "0") lovelace")
        print("Stake Address: \\(addressInfo.stakeAddress ?? "none")")
        print("Script Address: \\(addressInfo.scriptAddress ?? false)")
        
        // UTxO information
        if let utxos = addressInfo.utxoSet {
            print("UTxOs: \\(utxos.count)")
            for utxo in utxos.prefix(5) { // Show first 5 UTxOs
                print("  - \\(utxo.txHash ?? "unknown")#\\(utxo.txIndex ?? 0)")
                print("    Value: \\(utxo.value ?? "0") lovelace")
            }
        }
    }
}
```

### Batch Address Queries

Query multiple addresses efficiently:

```swift
func getBatchAddressInfo(addresses: [String]) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.addressInfo(
        body: .init(addresses.map { .init($0) })
    )
    
    let addressData = try response.ok.body.json
    
    print("Retrieved information for \\(addressData.count) addresses")
    
    for address in addressData {
        print("\\(address.address ?? "unknown"): \\(address.balance ?? "0") lovelace")
    }
}
```

## Transaction History

### Get Address Transactions

Retrieve transaction history for an address:

```swift
func getAddressTransactions(address: String, limit: Int = 100) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.addressTxs(
        body: .init([.init(address)])
    )
    
    let transactions = try response.ok.body.json
    
    print("Transaction history for \\(address):")
    
    for tx in transactions.prefix(limit) {
        print("- \\(tx.txHash ?? "unknown")")
        print("  Block: \\(tx.blockHeight ?? 0)")
        print("  Time: \\(tx.blockTime ?? 0)")
        print("  Epoch: \\(tx.epochNo ?? 0)")
    }
}
```

### Paginated Transaction History

Handle large transaction histories with pagination:

```swift
func getFullTransactionHistory(address: String) async throws -> [AddressTxsResponse] {
    let koios = try Koios(network: .mainnet)
    var allTransactions: [AddressTxsResponse] = []
    var afterBlockHeight: Int? = nil
    let pageSize = 1000
    
    repeat {
        let response = try await koios.client.addressTxs(
            body: .init([.init(address)]),
            query: .init(
                afterBlockHeight: afterBlockHeight,
                limit: pageSize
            )
        )
        
        let transactions = try response.ok.body.json
        allTransactions.append(contentsOf: transactions)
        
        // Set cursor for next page
        afterBlockHeight = transactions.last?.blockHeight
        
        // Break if we got fewer results than requested
        if transactions.count < pageSize {
            break
        }
        
        // Add small delay to avoid rate limiting
        try await Task.sleep(for: .seconds(0.1))
        
    } while true
    
    print("Total transactions: \\(allTransactions.count)")
    return allTransactions
}
```

## UTxO Management

### Query Address UTxOs

Get all unspent transaction outputs for an address:

```swift
func getAddressUTxOs(address: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.utxoInfo(
        body: .init([.init(address)])
    )
    
    let utxos = try response.ok.body.json
    
    print("UTxOs for \\(address):")
    var totalValue: UInt64 = 0
    
    for utxo in utxos {
        print("- \\(utxo.txHash ?? "unknown")#\\(utxo.txIndex ?? 0)")
        print("  Value: \\(utxo.value ?? "0") lovelace")
        print("  Block: \\(utxo.blockHeight ?? 0)")
        
        if let valueStr = utxo.value,
           let value = UInt64(valueStr) {
            totalValue += value
        }
        
        // Show asset information if present
        if let assets = utxo.assetList, !assets.isEmpty {
            print("  Assets:")
            for asset in assets {
                print("    - \\(asset.policyId ?? "unknown").\\(asset.assetName ?? ""): \\(asset.quantity ?? "0")")
            }
        }
    }
    
    print("Total ADA: \\(Double(totalValue) / 1_000_000) ADA")
}
```

### UTxO Selection Helper

Create a helper for UTxO selection in transactions:

```swift
struct UTxOSelector {
    let koios: Koios
    
    func selectUTxOsForAmount(address: String, requiredAmount: UInt64) async throws -> [UtxoInfosResponse] {
        let response = try await koios.client.utxoInfo(
            body: .init([.init(address)])
        )
        
        let utxos = try response.ok.body.json
        var selectedUTxOs: [UtxoInfosResponse] = []
        var totalSelected: UInt64 = 0
        
        // Sort UTxOs by value (largest first for efficiency)
        let sortedUTxOs = utxos.sorted { lhs, rhs in
            let lhsValue = UInt64(lhs.value ?? "0") ?? 0
            let rhsValue = UInt64(rhs.value ?? "0") ?? 0
            return lhsValue > rhsValue
        }
        
        for utxo in sortedUTxOs {
            guard let valueStr = utxo.value,
                  let value = UInt64(valueStr) else { continue }
            
            selectedUTxOs.append(utxo)
            totalSelected += value
            
            if totalSelected >= requiredAmount {
                break
            }
        }
        
        guard totalSelected >= requiredAmount else {
            throw KoiosError.valueError("Insufficient funds: need \\(requiredAmount), have \\(totalSelected)")
        }
        
        return selectedUTxOs
    }
}
```

## Native Assets

### Get Address Assets

Query native assets held by an address:

```swift
func getAddressAssets(address: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.addressAssets(
        body: .init([.init(address)])
    )
    
    let assets = try response.ok.body.json
    
    print("Native assets for \\(address):")
    
    for asset in assets {
        print("- Policy: \\(asset.policyId ?? "unknown")")
        print("  Asset Name: \\(asset.assetName ?? "unnamed")")
        print("  Fingerprint: \\(asset.fingerprint ?? "unknown")")
        print("  Quantity: \\(asset.quantity ?? "0")")
        
        if let decimals = asset.decimals {
            let quantity = Double(asset.quantity ?? "0") ?? 0
            let adjustedQuantity = quantity / pow(10, Double(decimals))
            print("  Decimal Quantity: \\(adjustedQuantity)")
        }
    }
}
```

### Asset Portfolio Tracker

Create a portfolio tracker for native assets:

```swift
class AssetPortfolioTracker {
    private let koios: Koios
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    struct AssetHolding {
        let policyId: String
        let assetName: String
        let fingerprint: String
        let quantity: String
        let decimals: Int?
    }
    
    func getPortfolio(for addresses: [String]) async throws -> [AssetHolding] {
        var allAssets: [AssetHolding] = []
        
        // Query assets for each address
        for address in addresses {
            let response = try await koios.client.addressAssets(
                body: .init([.init(address)])
            )
            
            let assets = try response.ok.body.json
            
            for asset in assets {
                let holding = AssetHolding(
                    policyId: asset.policyId ?? "",
                    assetName: asset.assetName ?? "",
                    fingerprint: asset.fingerprint ?? "",
                    quantity: asset.quantity ?? "0",
                    decimals: asset.decimals
                )
                
                allAssets.append(holding)
            }
        }
        
        // Group by fingerprint and sum quantities
        let groupedAssets = Dictionary(grouping: allAssets) { $0.fingerprint }
        
        return groupedAssets.compactMap { (fingerprint, holdings) in
            guard let first = holdings.first else { return nil }
            
            let totalQuantity = holdings.reduce(0) { total, holding in
                return total + (UInt64(holding.quantity) ?? 0)
            }
            
            return AssetHolding(
                policyId: first.policyId,
                assetName: first.assetName,
                fingerprint: fingerprint,
                quantity: String(totalQuantity),
                decimals: first.decimals
            )
        }
    }
}
```

## Address Monitoring

### Real-time Address Monitor

Monitor address changes in real-time:

```swift
class AddressMonitor: ObservableObject {
    @Published var addressInfo: AddressInfoResponse?
    @Published var lastUpdate: Date = Date()
    
    private let koios: Koios
    private let address: String
    private var monitorTask: Task<Void, Never>?
    
    init(address: String, network: Network = .mainnet) throws {
        self.address = address
        self.koios = try Koios(network: network)
    }
    
    func startMonitoring(interval: TimeInterval = 30) {
        guard monitorTask == nil else { return }
        
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.checkForUpdates()
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }
    
    func stopMonitoring() {
        monitorTask?.cancel()
        monitorTask = nil
    }
    
    @MainActor
    private func checkForUpdates() async {
        do {
            let response = try await koios.client.addressInfo(
                body: .init([.init(address)])
            )
            
            let addresses = try response.ok.body.json
            
            if let info = addresses.first {
                addressInfo = info
                lastUpdate = Date()
            }
        } catch {
            print("Error monitoring address \\(address): \\(error)")
        }
    }
}
```

## See Also

- <doc:TransactionEndpoints> - Query transaction details and confirmations
- <doc:NetworkEndpoints> - Access network and blockchain information
- <doc:AssetEndpoints> - Query native asset information and metadata
- <doc:ErrorHandling> - Handle address query errors