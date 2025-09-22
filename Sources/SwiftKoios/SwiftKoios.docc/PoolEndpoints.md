# Pool Endpoints

Query Cardano stake pool information, delegators, rewards, and metadata.

## Overview

Pool endpoints provide comprehensive information about Cardano stake pools including registration details, performance metrics, delegator information, and rewards history. These endpoints are essential for staking applications, pool explorers, and delegation services.

## Pool Information

### Get Pool Details

Query detailed information about specific stake pools:

```swift
func getPoolInfo(poolIds: [String]) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.poolInfo(
        body: .init(poolIds)
    )
    
    let pools = try response.ok.body.json
    
    for pool in pools {
        print("Pool: \(pool.poolIdBech32 ?? "unknown")")
        print("- Hex ID: \(pool.poolIdHex ?? "unknown")")
        print("- Ticker: \(pool.metaJson?.ticker ?? "N/A")")
        print("- Name: \(pool.metaJson?.name ?? "N/A")")
        print("- Margin: \(pool.margin ?? 0)%")
        print("- Fixed Cost: \(pool.fixedCost ?? "0") ADA")
        print("- Pledge: \(pool.pledge ?? "0") ADA")
        print("- Active Stake: \(pool.activeStake ?? "0") ADA")
        print("- Live Stake: \(pool.liveStake ?? "0") ADA")
        print("- Saturated: \(pool.liveSaturated ?? false)")
        print("- Active Epoch: \(pool.activeEpochNo ?? 0)")
        
        if let retiring = pool.retiringEpoch {
            print("- Retiring in Epoch: \(retiring)")
        }
    }
}
```

### Get All Active Pools

Retrieve a list of all active stake pools:

```swift
func getAllActivePools() async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.poolList()
    let pools = try response.ok.body.json
    
    print("Total active pools: \(pools.count)")
    
    // Group pools by status
    let activePools = pools.filter { ($0.poolStatus ?? "") == "registered" }
    let retiringPools = pools.filter { $0.retiringEpoch != nil }
    
    print("- Active: \(activePools.count)")
    print("- Retiring: \(retiringPools.count)")
    
    // Show top 10 pools by active stake
    let topPools = pools.sorted { lhs, rhs in
        let lhsStake = Double(lhs.activeStake ?? "0") ?? 0
        let rhsStake = Double(rhs.activeStake ?? "0") ?? 0
        return lhsStake > rhsStake
    }.prefix(10)
    
    print("\nTop 10 pools by stake:")
    for (index, pool) in topPools.enumerated() {
        let ticker = pool.metaJson?.ticker ?? "UNKNOWN"
        let stake = pool.activeStake ?? "0"
        print("\(index + 1). [\(ticker)] \(stake) ADA")
    }
}
```

## Pool Delegators

### Get Pool Delegators

Retrieve all addresses delegating to a pool:

```swift
func getPoolDelegators(poolId: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.poolDelegators(
        body: .init([poolId])
    )
    
    let delegators = try response.ok.body.json
    
    print("Delegators for pool \(poolId):")
    print("Total delegators: \(delegators.count)")
    
    var totalDelegation: UInt64 = 0
    
    for delegator in delegators.prefix(20) { // Show first 20
        let amount = UInt64(delegator.amount ?? "0") ?? 0
        totalDelegation += amount
        
        print("- \(delegator.stakeAddress ?? "unknown"): \(delegator.amount ?? "0") lovelace")
    }
    
    print("Total delegation shown: \(Double(totalDelegation) / 1_000_000) ADA")
}
```

### Delegation Analysis

Analyze delegation patterns for a pool:

```swift
struct PoolDelegationStats {
    let totalDelegators: Int
    let totalDelegation: String
    let averageDelegation: Double
    let medianDelegation: Double
    let topDelegators: [(address: String, amount: String, percentage: Double)]
}

func analyzePoolDelegation(poolId: String) async throws -> PoolDelegationStats {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.poolDelegators(
        body: .init([poolId])
    )
    
    let delegators = try response.ok.body.json
    
    // Convert to amounts for analysis
    let amounts = delegators.compactMap { delegator -> Double? in
        guard let amountStr = delegator.amount else { return nil }
        return Double(amountStr)
    }.sorted(by: >)
    
    let totalDelegation = amounts.reduce(0, +)
    let averageDelegation = totalDelegation / Double(amounts.count)
    
    // Calculate median
    let medianDelegation: Double
    if amounts.count % 2 == 0 {
        let mid = amounts.count / 2
        medianDelegation = (amounts[mid - 1] + amounts[mid]) / 2
    } else {
        medianDelegation = amounts[amounts.count / 2]
    }
    
    // Top 10 delegators
    let topDelegators = delegators
        .compactMap { delegator -> (address: String, amount: Double)? in
            guard let address = delegator.stakeAddress,
                  let amountStr = delegator.amount,
                  let amount = Double(amountStr) else { return nil }
            return (address: address, amount: amount)
        }
        .sorted { $0.amount > $1.amount }
        .prefix(10)
        .map { delegator in
            let percentage = (delegator.amount / totalDelegation) * 100
            return (
                address: delegator.address,
                amount: String(Int(delegator.amount)),
                percentage: percentage
            )
        }
    
    return PoolDelegationStats(
        totalDelegators: delegators.count,
        totalDelegation: String(Int(totalDelegation)),
        averageDelegation: averageDelegation,
        medianDelegation: medianDelegation,
        topDelegators: topDelegators
    )
}
```

## Pool Performance

### Get Pool History

Track pool performance over time:

```swift
func getPoolHistory(poolId: String, epochCount: Int = 10) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.poolHistory(
        body: .init([poolId])
    )
    
    let history = try response.ok.body.json
    
    print("Pool history for \(poolId) (last \(min(epochCount, history.count)) epochs):")
    
    for epoch in history.prefix(epochCount) {
        print("Epoch \(epoch.epochNo ?? 0):")
        print("  - Active Stake: \(epoch.activeStake ?? "0") lovelace")
        print("  - Pool Fees: \(epoch.poolFees ?? "0") lovelace")
        print("  - Delegator Rewards: \(epoch.delegRewards ?? "0") lovelace")
        print("  - Blocks: \(epoch.epochBlockCnt ?? 0)")
    }
}
```

### Pool Performance Calculator

Calculate pool performance metrics:

```swift
struct PoolPerformance {
    let poolId: String
    let epochsAnalyzed: Int
    let averageBlocks: Double
    let totalRewards: String
    let averageROA: Double // Return on Active stake
    let consistency: Double // Block production consistency
}

func calculatePoolPerformance(poolId: String, epochs: Int = 20) async throws -> PoolPerformance {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.poolHistory(
        body: .init([poolId])
    )
    
    let history = Array(try response.ok.body.json.prefix(epochs))
    
    let totalBlocks = history.reduce(0) { total, epoch in
        total + (epoch.epochBlockCnt ?? 0)
    }
    
    let totalRewards = history.reduce(0.0) { total, epoch in
        let rewards = Double(epoch.delegRewards ?? "0") ?? 0
        return total + rewards
    }
    
    let averageBlocks = Double(totalBlocks) / Double(history.count)
    
    // Calculate consistency (variance in block production)
    let blockCounts = history.map { Double($0.epochBlockCnt ?? 0) }
    let variance = blockCounts.reduce(0) { sum, blocks in
        sum + pow(blocks - averageBlocks, 2)
    } / Double(blockCounts.count)
    let consistency = max(0, 1 - (sqrt(variance) / averageBlocks)) * 100
    
    // Calculate average ROA (simplified)
    let avgStake = history.reduce(0.0) { total, epoch in
        let stake = Double(epoch.activeStake ?? "0") ?? 0
        return total + stake
    } / Double(history.count)
    
    let averageROA = avgStake > 0 ? (totalRewards / avgStake) * 100 : 0
    
    return PoolPerformance(
        poolId: poolId,
        epochsAnalyzed: history.count,
        averageBlocks: averageBlocks,
        totalRewards: String(Int(totalRewards)),
        averageROA: averageROA,
        consistency: consistency
    )
}
```

## Pool Metadata

### Get Pool Metadata

Retrieve and parse pool metadata:

```swift
func getPoolMetadata(poolIds: [String]) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.poolMetadata(
        body: .init(poolIds)
    )
    
    let metadata = try response.ok.body.json
    
    for poolMeta in metadata {
        print("Pool: \(poolMeta.poolIdBech32 ?? "unknown")")
        print("- Metadata URL: \(poolMeta.metaUrl ?? "N/A")")
        print("- Metadata Hash: \(poolMeta.metaHash ?? "N/A")")
        
        if let metaJson = poolMeta.metaJson {
            print("- Ticker: \(metaJson.ticker ?? "N/A")")
            print("- Name: \(metaJson.name ?? "N/A")")
            print("- Description: \(metaJson.description ?? "N/A")")
            print("- Homepage: \(metaJson.homepage ?? "N/A")")
        }
    }
}
```

## Pool Search and Filtering

### Pool Search Engine

Create utilities for finding pools by criteria:

```swift
class PoolSearchEngine {
    private let koios: Koios
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    struct PoolSearchFilters {
        let minActiveStake: String?
        let maxActiveStake: String?
        let maxMargin: Double?
        let maxFixedCost: String?
        let ticker: String?
        let isRetiring: Bool?
    }
    
    func searchPools(filters: PoolSearchFilters) async throws -> [PoolListResponse] {
        let response = try await koios.client.poolList()
        var pools = try response.ok.body.json
        
        // Apply filters
        if let minStake = filters.minActiveStake, let minStakeValue = Double(minStake) {
            pools = pools.filter { pool in
                let stake = Double(pool.activeStake ?? "0") ?? 0
                return stake >= minStakeValue
            }
        }
        
        if let maxStake = filters.maxActiveStake, let maxStakeValue = Double(maxStake) {
            pools = pools.filter { pool in
                let stake = Double(pool.activeStake ?? "0") ?? 0
                return stake <= maxStakeValue
            }
        }
        
        if let maxMargin = filters.maxMargin {
            pools = pools.filter { pool in
                let margin = pool.margin ?? 100 // Default to high value if not set
                return margin <= maxMargin
            }
        }
        
        if let maxCost = filters.maxFixedCost, let maxCostValue = Double(maxCost) {
            pools = pools.filter { pool in
                let cost = Double(pool.fixedCost ?? "999999999999") ?? 999999999999
                return cost <= maxCostValue
            }
        }
        
        if let ticker = filters.ticker {
            pools = pools.filter { pool in
                return pool.metaJson?.ticker?.lowercased().contains(ticker.lowercased()) ?? false
            }
        }
        
        if let isRetiring = filters.isRetiring {
            if isRetiring {
                pools = pools.filter { $0.retiringEpoch != nil }
            } else {
                pools = pools.filter { $0.retiringEpoch == nil }
            }
        }
        
        return pools
    }
}
```

## See Also

- <doc:NetworkEndpoints> - Query epoch and network information for pool context
- <doc:AddressEndpoints> - Query stake addresses and delegation information
- <doc:TransactionEndpoints> - Track pool registration and delegation transactions
- <doc:ErrorHandling> - Handle pool query errors