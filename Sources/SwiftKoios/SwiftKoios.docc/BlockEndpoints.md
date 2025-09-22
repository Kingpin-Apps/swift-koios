# Block Endpoints

Query Cardano block information, transactions, and metadata.

## Overview

Block endpoints provide access to Cardano block data including block headers, transaction lists, and detailed block information. These endpoints are essential for blockchain explorers and applications that need to track block-level activity.

## Block Information

### Get Block Details

Query detailed information about specific blocks:

```swift
func getBlockInfo(blockHashes: [String]) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.blockInfo(
        body: .init(blockHashes)
    )
    
    let blocks = try response.ok.body.json
    
    for block in blocks {
        print("Block: \(block.hash ?? "unknown")")
        print("- Height: \(block.blockHeight ?? 0)")
        print("- Epoch: \(block.epochNo ?? 0)")
        print("- Slot: \(block.absSlot ?? 0)")
        print("- Size: \(block.blockSize ?? 0) bytes")
        print("- Transactions: \(block.txCount ?? 0)")
        print("- Producer: \(block.pool ?? "unknown")")
        print("- VRF Key: \(block.vrfKey ?? "unknown")")
        print("- Protocol: \(block.protoMajor ?? 0).\(block.protoMinor ?? 0)")
    }
}
```

### Get Block List

Retrieve a list of recent blocks:

```swift
func getRecentBlocks(limit: Int = 20) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.blocks(
        query: .init(limit: limit)
    )
    
    let blocks = try response.ok.body.json
    
    print("Recent \(blocks.count) blocks:")
    
    for block in blocks {
        print("Block \(block.blockHeight ?? 0): \(block.hash ?? "unknown")")
        print("  Producer: \(block.pool ?? "unknown")")
        print("  Transactions: \(block.txCount ?? 0)")
        print("  Time: \(block.blockTime ?? 0)")
    }
}
```

## Block Transactions

### Get Transactions in Block

Retrieve all transactions within a specific block:

```swift
func getBlockTransactions(blockHash: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.blockTxs(
        body: .init([blockHash])
    )
    
    let transactions = try response.ok.body.json
    
    print("Transactions in block \(blockHash):")
    
    for tx in transactions {
        print("- \(tx.txHash ?? "unknown")")
        print("  Block Height: \(tx.blockHeight ?? 0)")
        print("  Block Time: \(tx.blockTime ?? 0)")
        print("  Epoch: \(tx.epochNo ?? 0)")
    }
}
```

### Get Block Transaction Details

Retrieve detailed transaction information for a block:

```swift
func getBlockTransactionDetails(blockHash: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.blockTxInfo(
        body: .init([blockHash])
    )
    
    let transactions = try response.ok.body.json
    
    print("Transaction details for block \(blockHash):")
    
    for tx in transactions {
        print("Transaction: \(tx.txHash ?? "unknown")")
        print("- Size: \(tx.txSize ?? 0) bytes")
        print("- Fee: \(tx.fee ?? "0") lovelace")
        print("- Total Output: \(tx.totalOutput ?? "0") lovelace")
        print("- Block Index: \(tx.txBlockIndex ?? 0)")
        
        // Show inputs and outputs count
        if let inputs = tx.inputs {
            print("- Inputs: \(inputs.count)")
        }
        if let outputs = tx.outputs {
            print("- Outputs: \(outputs.count)")
        }
        
        // Show metadata if present
        if let metadata = tx.metadata, !metadata.isEmpty {
            print("- Has Metadata: Yes")
        }
    }
}
```

## Block Monitoring

### Real-time Block Monitor

Create a monitor for new blocks:

```swift
class BlockMonitor: ObservableObject {
    @Published var latestBlocks: [BlocksResponse] = []
    @Published var isMonitoring = false
    
    private let koios: Koios
    private var monitorTask: Task<Void, Never>?
    private var lastBlockHeight: Int = 0
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    func startMonitoring(interval: TimeInterval = 20) {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        monitorTask = Task { [weak self] in
            while !Task.isCancelled && self?.isMonitoring == true {
                await self?.checkForNewBlocks()
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitorTask?.cancel()
        monitorTask = nil
    }
    
    @MainActor
    private func checkForNewBlocks() async {
        do {
            let response = try await koios.client.blocks(
                query: .init(limit: 10)
            )
            
            let blocks = try response.ok.body.json
            
            // Filter for new blocks
            let newBlocks = blocks.filter { block in
                let height = block.blockHeight ?? 0
                return height > lastBlockHeight
            }
            
            if !newBlocks.isEmpty {
                print("Found \(newBlocks.count) new blocks")
                latestBlocks = blocks
                lastBlockHeight = blocks.first?.blockHeight ?? lastBlockHeight
            }
            
        } catch {
            print("Error monitoring blocks: \(error)")
        }
    }
}
```

### Block Statistics

Calculate statistics for a range of blocks:

```swift
struct BlockStats {
    let blockCount: Int
    let totalTransactions: Int
    let totalSize: Int
    let averageSize: Double
    let producerDistribution: [String: Int]
}

func calculateBlockStats(fromHeight: Int, toHeight: Int) async throws -> BlockStats {
    let koios = try Koios(network: .mainnet)
    
    // Get blocks in range
    let response = try await koios.client.blocks(
        query: .init(
            minHeight: fromHeight,
            maxHeight: toHeight,
            limit: toHeight - fromHeight
        )
    )
    
    let blocks = try response.ok.body.json
    
    var totalTransactions = 0
    var totalSize = 0
    var producerCount: [String: Int] = [:]
    
    for block in blocks {
        totalTransactions += block.txCount ?? 0
        totalSize += block.blockSize ?? 0
        
        let producer = block.pool ?? "unknown"
        producerCount[producer, default: 0] += 1
    }
    
    return BlockStats(
        blockCount: blocks.count,
        totalTransactions: totalTransactions,
        totalSize: totalSize,
        averageSize: blocks.count > 0 ? Double(totalSize) / Double(blocks.count) : 0,
        producerDistribution: producerCount
    )
}
```

## See Also

- <doc:NetworkEndpoints> - Query network and chain information
- <doc:TransactionEndpoints> - Get detailed transaction information
- <doc:AddressEndpoints> - Query address-specific transactions
- <doc:ErrorHandling> - Handle block query errors