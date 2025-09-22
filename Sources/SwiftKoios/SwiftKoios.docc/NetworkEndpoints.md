# Network Endpoints

Access Cardano network information including chain tip, genesis parameters, and protocol updates.

## Overview

Network endpoints provide essential blockchain information such as current chain state, network parameters, epoch information, and protocol updates. These endpoints are fundamental for understanding the current state of the Cardano network.

## Chain Tip Information

### Get Current Chain Tip

Retrieve the latest block information from the blockchain:

```swift
func getCurrentTip() async throws {
    let koios = try Koios(network: .mainnet)
    let response = try await koios.client.tip()
    let tipData = try response.ok.body.json
    
    guard let tip = tipData.first else { return }
    
    print("Current Chain Tip:")
    print("- Block Height: \\(tip.blockNo ?? 0)")
    print("- Epoch: \\(tip.epochNo ?? 0)")
    print("- Slot: \\(tip.absSlot ?? 0)")
    print("- Block Hash: \\(tip.hash ?? "unknown")")
    print("- Block Time: \\(tip.blockTime ?? 0)")
}
```

### Monitor Chain Progress

Create a real-time monitor for chain progress:

```swift
class ChainMonitor: ObservableObject {
    @Published var currentTip: TipResponse?
    @Published var isMonitoring = false
    
    private let koios: Koios
    private var monitorTask: Task<Void, Never>?
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    func startMonitoring(interval: TimeInterval = 20) {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        monitorTask = Task { [weak self] in
            while !Task.isCancelled && self?.isMonitoring == true {
                await self?.updateTip()
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
    private func updateTip() async {
        do {
            let response = try await koios.client.tip()
            let tipData = try response.ok.body.json
            currentTip = tipData.first
        } catch {
            print("Failed to update tip: \\(error)")
        }
    }
}
```

## Genesis Parameters

### Get Genesis Information

Retrieve fundamental network parameters set at genesis:

```swift
func getGenesisParameters() async throws {
    let koios = try Koios(network: .mainnet)
    let response = try await koios.client.genesis()
    let genesisData = try response.ok.body.json
    
    for genesis in genesisData {
        print("Genesis Parameters:")
        print("- Network ID: \\(genesis.networkid ?? "unknown")")
        print("- Network Magic: \\(genesis.networkmagic ?? 0)")
        print("- Epoch Length: \\(genesis.epochlength ?? 0) seconds")
        print("- Slot Length: \\(genesis.slotlength ?? 0)ms")
        print("- Max Lovelace Supply: \\(genesis.maxlovelacesupply ?? 0)")
        print("- System Start: \\(genesis.systemstart ?? "unknown")")
        
        // Protocol parameters
        if let minFeeA = genesis.minfeeA {
            print("- Min Fee A: \\(minFeeA)")
        }
        if let minFeeB = genesis.minfeeB {
            print("- Min Fee B: \\(minFeeB)")
        }
    }
}
```

### Validate Network

Use genesis parameters to validate you're connected to the correct network:

```swift
func validateNetwork(_ expectedNetworkId: String) async throws -> Bool {
    let koios = try Koios(network: .mainnet)
    let response = try await koios.client.genesis()
    let genesisData = try response.ok.body.json
    
    guard let genesis = genesisData.first,
          let networkId = genesis.networkid else {
        return false
    }
    
    return networkId == expectedNetworkId
}

// Usage
let isMainnet = try await validateNetwork("Mainnet")
print("Connected to mainnet: \\(isMainnet)")
```

## Network Totals

### Get Historical Tokenomics

Retrieve aggregate network statistics and tokenomics data:

```swift
func getNetworkTotals() async throws {
    let koios = try Koios(network: .mainnet)
    let response = try await koios.client.totals()
    let totalsData = try response.ok.body.json
    
    for totals in totalsData {
        print("Network Totals:")
        print("- Epoch: \\(totals.epochNo ?? 0)")
        print("- Circulating Supply: \\(totals.circulation ?? "0") ADA")
        print("- Treasury: \\(totals.treasury ?? "0") ADA")  
        print("- Reserves: \\(totals.reserves ?? "0") ADA")
        print("- Reward Accounts: \\(totals.rewardAccounts ?? "0")")
        print("- Total UTxOs: \\(totals.utxos ?? 0)")
    }
}
```

### Track Supply Changes

Monitor changes in ADA supply over time:

```swift
struct SupplyMetrics {
    let epoch: Int
    let circulation: String
    let treasury: String
    let reserves: String
    let timestamp: Date
}

class SupplyTracker {
    private let koios: Koios
    private var history: [SupplyMetrics] = []
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    func recordCurrentSupply() async throws {
        let response = try await koios.client.totals()
        let totalsData = try response.ok.body.json
        
        guard let totals = totalsData.first else { return }
        
        let metrics = SupplyMetrics(
            epoch: totals.epochNo ?? 0,
            circulation: totals.circulation ?? "0",
            treasury: totals.treasury ?? "0",
            reserves: totals.reserves ?? "0",
            timestamp: Date()
        )
        
        history.append(metrics)
    }
    
    func getSupplyChangeForLastEpochs(_ count: Int) -> [SupplyMetrics] {
        return Array(history.suffix(count))
    }
}
```

## Epoch Information

### Get Epoch Details

Retrieve detailed information about specific epochs:

```swift
func getEpochInfo(epochNo: Int? = nil) async throws {
    let koios = try Koios(network: .mainnet)
    
    let body: Components.Schemas.EpochInfoRequest?
    if let epoch = epochNo {
        body = Components.Schemas.EpochInfoRequest(
            _epochNo: [Components.Schemas.EpochInfoRequest.epochNoPayloadPayload(epoch)]
        )
    } else {
        body = nil
    }
    
    let response = try await koios.client.epochInfo(body: body)
    let epochData = try response.ok.body.json
    
    for epoch in epochData {
        print("Epoch \\(epoch.epochNo ?? 0):")
        print("- Start Time: \\(epoch.startTime ?? 0)")
        print("- End Time: \\(epoch.endTime ?? 0)")
        print("- First Block Time: \\(epoch.firstBlockTime ?? 0)")
        print("- Last Block Time: \\(epoch.lastBlockTime ?? 0)")
        print("- Block Count: \\(epoch.blkCount ?? 0)")
        print("- Transaction Count: \\(epoch.txCount ?? 0)")
        print("- Total Output: \\(epoch.sum ?? "0")")
        print("- Total Fees: \\(epoch.fees ?? "0")")
        print("- Active Stake: \\(epoch.activeStake ?? "0")")
    }
}
```

### Current Epoch Progress

Calculate progress through the current epoch:

```swift
func getCurrentEpochProgress() async throws -> Double {
    let koios = try Koios(network: .mainnet)
    
    // Get current tip
    let tipResponse = try await koios.client.tip()
    let tipData = try tipResponse.ok.body.json
    
    guard let tip = tipData.first,
          let currentEpoch = tip.epochNo,
          let currentSlot = tip.epochSlot else {
        return 0.0
    }
    
    // Get genesis to calculate epoch length
    let genesisResponse = try await koios.client.genesis()
    let genesisData = try genesisResponse.ok.body.json
    
    guard let genesis = genesisData.first,
          let epochLength = genesis.epochlength else {
        return 0.0
    }
    
    let slotsPerEpoch = epochLength / 1000 // Convert to slots (assuming 1s slots)
    let progress = Double(currentSlot) / Double(slotsPerEpoch)
    
    print("Epoch \\(currentEpoch) Progress: \\(String(format: "%.1f", progress * 100))%")
    return progress
}
```

## Parameter Updates

### Get Protocol Parameter Updates

Retrieve information about protocol parameter updates:

```swift
func getParameterUpdates() async throws {
    let koios = try Koios(network: .mainnet)
    let response = try await koios.client.paramUpdates()
    let updates = try response.ok.body.json
    
    for update in updates {
        print("Parameter Update:")
        print("- Transaction Hash: \\(update.txHash ?? "unknown")")
        print("- Block Height: \\(update.blockHeight ?? 0)")
        print("- Block Time: \\(update.blockTime ?? 0)")
        
        // Check for specific parameter changes
        if let minFeeA = update.minFeeA {
            print("- Updated Min Fee A: \\(minFeeA)")
        }
        if let maxBlockSize = update.maxBlockSize {
            print("- Updated Max Block Size: \\(maxBlockSize)")
        }
        if let poolDeposit = update.poolDeposit {
            print("- Updated Pool Deposit: \\(poolDeposit)")
        }
    }
}
```

### Monitor for Parameter Changes

Set up monitoring for protocol parameter changes:

```swift
class ParameterMonitor: ObservableObject {
    @Published var latestUpdate: ParamUpdateResponse?
    
    private let koios: Koios
    private var lastCheckTime: Date = Date()
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    func checkForUpdates() async {
        do {
            let response = try await koios.client.paramUpdates()
            let updates = try response.ok.body.json
            
            // Find updates since last check
            let recentUpdates = updates.filter { update in
                guard let blockTime = update.blockTime else { return false }
                let updateTime = Date(timeIntervalSince1970: TimeInterval(blockTime))
                return updateTime > lastCheckTime
            }
            
            if let latest = recentUpdates.first {
                await MainActor.run {
                    self.latestUpdate = latest
                }
                print("New parameter update detected!")
            }
            
            lastCheckTime = Date()
        } catch {
            print("Failed to check for parameter updates: \\(error)")
        }
    }
}
```

## Best Practices

### Efficient Network Queries

Cache network information that doesn't change frequently:

```swift
class NetworkInfoCache {
    private var genesisCache: [GenesisResponse]?
    private var genesisCacheTime: Date?
    private let cacheValidityPeriod: TimeInterval = 3600 // 1 hour
    
    private let koios: Koios
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    func getGenesis() async throws -> [GenesisResponse] {
        // Check if cache is still valid
        if let cached = genesisCache,
           let cacheTime = genesisCacheTime,
           Date().timeIntervalSince(cacheTime) < cacheValidityPeriod {
            return cached
        }
        
        // Fetch fresh data
        let response = try await koios.client.genesis()
        let genesisData = try response.ok.body.json
        
        // Update cache
        genesisCache = genesisData
        genesisCacheTime = Date()
        
        return genesisData
    }
}
```

### Error Handling

Implement robust error handling for network queries:

```swift
func safeNetworkQuery<T>(_ operation: () async throws -> T) async -> T? {
    do {
        return try await operation()
    } catch {
        print("Network query failed: \\(error)")
        
        // Log specific error types
        if let koiosError = error as? KoiosError {
            print("KoiosError: \\(koiosError.description)")
        } else if let urlError = error as? URLError {
            print("Network error: \\(urlError.localizedDescription)")
        }
        
        return nil
    }
}

// Usage
let tip = await safeNetworkQuery {
    let koios = try Koios(network: .mainnet)
    let response = try await koios.client.tip()
    return try response.ok.body.json
}
```

## See Also

- <doc:GettingStarted> - Basic setup and first network queries
- <doc:BlockEndpoints> - Query specific blocks and block information  
- <doc:TransactionEndpoints> - Access transaction data
- <doc:ErrorHandling> - Handle network-related errors
- [Koios Network API Documentation](https://api.koios.rest/)