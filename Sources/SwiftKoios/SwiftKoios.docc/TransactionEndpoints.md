# Transaction Endpoints

Query Cardano transaction data including details, metadata, UTxOs, and confirmations.

## Overview

Transaction endpoints provide comprehensive access to Cardano transaction data. You can query transaction details, metadata, UTxO sets, confirmation status, and more.

## Transaction Information

### Get Transaction Details

Query detailed information about specific transactions:

```swift
func getTransactionInfo(txHash: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.txInfo(
        body: .init(.init(txHashes: [txHash]))
    )
    
    let transactions = try response.ok.body.json
    
    for tx in transactions {
        print("Transaction: \\(tx.txHash ?? "unknown")")
        print("- Block Height: \\(tx.blockHeight ?? 0)")
        print("- Fee: \\(tx.fee ?? "0") lovelace")
        print("- Size: \\(tx.txSize ?? 0) bytes")
        print("- Total Output: \\(tx.totalOutput ?? "0") lovelace")
        print("- Confirmations: \\(tx.numConfirmations ?? 0)")
    }
}
```

### Batch Transaction Queries

Query multiple transactions efficiently:

```swift
func getBatchTransactionInfo(txHashes: [String]) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.txInfo(
        body: .init(.init(txHashes: txHashes))
    )
    
    let transactions = try response.ok.body.json
    
    print("Retrieved \\(transactions.count) transactions")
    
    for tx in transactions {
        print("\\(tx.txHash ?? "unknown"): \\(tx.fee ?? "0") lovelace fee")
    }
}
```

## Transaction Metadata

### Query Transaction Metadata

Retrieve metadata attached to transactions:

```swift
func getTransactionMetadata(txHash: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.txMetadata(
        body: .init(.init(txHashes: [txHash]))
    )
    
    let metadataList = try response.ok.body.json
    
    for metadata in metadataList {
        print("Transaction: \\(metadata.txHash ?? "unknown")")
        
        if let jsonMetadata = metadata.metadata {
            print("Metadata: \\(jsonMetadata)")
        }
    }
}
```

## Transaction Status

### Check Transaction Confirmations

Monitor transaction confirmation status:

```swift
func getTransactionStatus(txHash: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.txStatus(
        body: .init(.init(txHashes: [txHash]))
    )
    
    let statuses = try response.ok.body.json
    
    for status in statuses {
        print("Transaction: \\(status.txHash ?? "unknown")")
        print("- Confirmations: \\(status.numConfirmations ?? 0)")
        
        if let confirmed = status.numConfirmations, confirmed > 0 {
            print("- Status: Confirmed")
        } else {
            print("- Status: Unconfirmed")
        }
    }
}
```

### Transaction Confirmation Monitor

Create a monitor for transaction confirmations:

```swift
class TransactionMonitor: ObservableObject {
    @Published var confirmations: [String: Int] = [:]
    
    private let koios: Koios
    private var monitoringTasks: [String: Task<Void, Never>] = [:]
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    func startMonitoring(txHash: String, requiredConfirmations: Int = 6) {
        guard monitoringTasks[txHash] == nil else { return }
        
        let task = Task { [weak self] in
            await self?.monitorTransaction(txHash, required: requiredConfirmations)
        }
        
        monitoringTasks[txHash] = task
    }
    
    func stopMonitoring(txHash: String) {
        monitoringTasks[txHash]?.cancel()
        monitoringTasks.removeValue(forKey: txHash)
    }
    
    private func monitorTransaction(_ txHash: String, required: Int) async {
        while !Task.isCancelled {
            do {
                let response = try await koios.client.txStatus(
                    body: .init(.init(txHashes: [txHash]))
                )
                
                let statuses = try response.ok.body.json
                
                if let status = statuses.first,
                   let confirmations = status.numConfirmations {
                    
                    await MainActor.run {
                        self.confirmations[txHash] = confirmations
                    }
                    
                    if confirmations >= required {
                        break // Transaction sufficiently confirmed
                    }
                }
                
                try await Task.sleep(for: .seconds(30))
                
            } catch {
                print("Error monitoring transaction \\(txHash): \\(error)")
                try? await Task.sleep(for: .seconds(60))
            }
        }
        
        // Clean up
        await MainActor.run {
            self.monitoringTasks.removeValue(forKey: txHash)
        }
    }
}
```

## Transaction UTxOs

### Query Transaction UTxOs

Get UTxO information for transactions:

```swift
func getTransactionUTxOs(txHash: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.txUtxos(
        body: .init(.init(txHashes: [txHash]))
    )
    
    let utxoData = try response.ok.body.json
    
    for utxoInfo in utxoData {
        print("Transaction: \\(utxoInfo.txHash ?? "unknown")")
        
        // Process inputs
        if let inputs = utxoInfo.inputs {
            print("Inputs:")
            for input in inputs {
                print("  - \\(input.txHash ?? "unknown")#\\(input.txIndex ?? 0)")
                print("    Value: \\(input.value ?? "0") lovelace")
                
                if let address = input.paymentAddr?.cred {
                    print("    Address: \\(address)")
                }
            }
        }
        
        // Process outputs
        if let outputs = utxoInfo.outputs {
            print("Outputs:")
            for output in outputs {
                print("  - Index: \\(output.txIndex ?? 0)")
                print("    Value: \\(output.value ?? "0") lovelace")
                
                if let address = output.paymentAddr?.cred {
                    print("    Address: \\(address)")
                }
            }
        }
    }
}
```

## See Also

- <doc:NetworkEndpoints> - Query network and blockchain information
- <doc:AddressEndpoints> - Query address-specific transaction history
- <doc:BlockEndpoints> - Get transactions within specific blocks
- <doc:ErrorHandling> - Handle transaction query errors