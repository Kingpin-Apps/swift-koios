# Asset Endpoints

Query Cardano native assets, tokens, and NFT information.

## Overview

Asset endpoints provide comprehensive information about Cardano native assets including fungible tokens, NFTs, and their metadata. These endpoints are essential for token explorers, wallet applications, and DeFi integrations.

## Asset Information

### Get Asset Details

Query detailed information about specific assets:

```swift
func getAssetInfo(policyId: String, assetName: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    let assetFingerprint = "\(policyId).\(assetName)"
    
    let response = try await koios.client.assetInfo(
        body: .init([assetFingerprint])
    )
    
    let assets = try response.ok.body.json
    
    for asset in assets {
        print("Asset: \(asset.policyId ?? "unknown").\(asset.assetName ?? "")")
        print("- Fingerprint: \(asset.fingerprint ?? "unknown")")
        print("- Total Supply: \(asset.totalSupply ?? "0")")
        print("- Mint Count: \(asset.mintCnt ?? 0)")
        print("- Burn Count: \(asset.burnCnt ?? 0)")
        print("- Creation Time: \(asset.creationTime ?? 0)")
        
        // Metadata information
        if let metadataJson = asset.metadataJson {
            print("- Has Metadata: Yes")
            print("- Metadata: \(metadataJson)")
        }
    }
}
```

### Get Asset List

Retrieve a list of all native assets:

```swift
func getAssetList(limit: Int = 100, offset: Int = 0) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.assetList(
        query: .init(
            limit: limit,
            offset: offset
        )
    )
    
    let assets = try response.ok.body.json
    
    print("Assets (showing \(assets.count)):")
    
    for asset in assets {
        print("- \(asset.policyId ?? "unknown").\(asset.assetName ?? "")")
        print("  Supply: \(asset.totalSupply ?? "0")")
        print("  Holders: \(asset.holderCount ?? 0)")
    }
}
```

## Asset History

### Get Mint/Burn History

Track asset minting and burning events:

```swift
func getAssetHistory(policyId: String, assetName: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    let assetFingerprint = "\(policyId).\(assetName)"
    
    let response = try await koios.client.assetHistory(
        body: .init([assetFingerprint])
    )
    
    let history = try response.ok.body.json
    
    print("Asset history for \(assetFingerprint):")
    
    for event in history {
        print("- Transaction: \(event.txHash ?? "unknown")")
        print("  Action: \(event.action ?? "unknown")")
        print("  Amount: \(event.amount ?? "0")")
        print("  Block Height: \(event.blockHeight ?? 0)")
        print("  Block Time: \(event.blockTime ?? 0)")
    }
}
```

## Asset Holders

### Get Asset Holder Addresses

Find all addresses that hold a specific asset:

```swift
func getAssetHolders(policyId: String, assetName: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    let assetFingerprint = "\(policyId).\(assetName)"
    
    let response = try await koios.client.assetAddresses(
        body: .init([assetFingerprint])
    )
    
    let holders = try response.ok.body.json
    
    print("Holders of \(assetFingerprint):")
    
    for holder in holders {
        print("- Address: \(holder.paymentAddr ?? "unknown")")
        print("  Quantity: \(holder.quantity ?? "0")")
    }
    
    print("Total holders: \(holders.count)")
}
```

### Asset Distribution Analysis

Analyze the distribution of an asset across holders:

```swift
struct AssetDistribution {
    let totalHolders: Int
    let totalSupply: String
    let largestHolders: [(address: String, quantity: String, percentage: Double)]
    let concentrationIndex: Double // Gini coefficient approximation
}

func analyzeAssetDistribution(policyId: String, assetName: String) async throws -> AssetDistribution {
    let koios = try Koios(network: .mainnet)
    let assetFingerprint = "\(policyId).\(assetName)"
    
    // Get asset info
    let infoResponse = try await koios.client.assetInfo(
        body: .init([assetFingerprint])
    )
    let assetInfo = try infoResponse.ok.body.json
    
    guard let asset = assetInfo.first,
          let totalSupplyStr = asset.totalSupply,
          let totalSupply = Double(totalSupplyStr) else {
        throw KoiosError.valueError("Could not get asset supply")
    }
    
    // Get all holders
    let holdersResponse = try await koios.client.assetAddresses(
        body: .init([assetFingerprint])
    )
    let holders = try holdersResponse.ok.body.json
    
    // Sort holders by quantity
    let sortedHolders = holders.compactMap { holder -> (address: String, quantity: Double)? in
        guard let address = holder.paymentAddr,
              let quantityStr = holder.quantity,
              let quantity = Double(quantityStr) else { return nil }
        return (address: address, quantity: quantity)
    }.sorted { $0.quantity > $1.quantity }
    
    // Calculate top holders with percentages
    let topHolders = sortedHolders.prefix(10).map { holder in
        let percentage = (holder.quantity / totalSupply) * 100
        return (
            address: holder.address,
            quantity: String(Int(holder.quantity)),
            percentage: percentage
        )
    }
    
    // Simple concentration index (percentage held by top 10%)
    let top10Percent = Int(max(1, sortedHolders.count / 10))
    let top10Holdings = sortedHolders.prefix(top10Percent).reduce(0) { $0 + $1.quantity }
    let concentrationIndex = (top10Holdings / totalSupply) * 100
    
    return AssetDistribution(
        totalHolders: holders.count,
        totalSupply: totalSupplyStr,
        largestHolders: topHolders,
        concentrationIndex: concentrationIndex
    )
}
```

## NFT Utilities

### NFT Collection Browser

Create utilities for browsing NFT collections:

```swift
class NFTCollectionBrowser {
    private let koios: Koios
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    struct NFTInfo {
        let policyId: String
        let assetName: String
        let fingerprint: String
        let metadata: [String: Any]?
        let supply: String
        let holderAddress: String?
    }
    
    func browseCollection(policyId: String, limit: Int = 100) async throws -> [NFTInfo] {
        // Get all assets for this policy
        let response = try await koios.client.assetList(
            query: .init(
                policyId: policyId,
                limit: limit
            )
        )
        
        let assets = try response.ok.body.json
        var nfts: [NFTInfo] = []
        
        for asset in assets {
            guard let assetPolicyId = asset.policyId,
                  let assetName = asset.assetName,
                  let fingerprint = asset.fingerprint else { continue }
            
            // Get detailed info including metadata
            let infoResponse = try await koios.client.assetInfo(
                body: .init([fingerprint])
            )
            let detailInfo = try infoResponse.ok.body.json
            
            if let detail = detailInfo.first {
                // Get holder info (for NFTs, usually just one holder)
                let holdersResponse = try await koios.client.assetAddresses(
                    body: .init([fingerprint])
                )
                let holders = try holdersResponse.ok.body.json
                let holderAddress = holders.first?.paymentAddr
                
                let nft = NFTInfo(
                    policyId: assetPolicyId,
                    assetName: assetName,
                    fingerprint: fingerprint,
                    metadata: nil, // Would need to parse JSON metadata
                    supply: detail.totalSupply ?? "1",
                    holderAddress: holderAddress
                )
                
                nfts.append(nft)
            }
            
            // Add small delay to avoid rate limiting
            try await Task.sleep(for: .seconds(0.1))
        }
        
        return nfts
    }
}
```

## Asset Search and Filtering

### Asset Search Helper

Create utilities for searching and filtering assets:

```swift
class AssetSearchEngine {
    private let koios: Koios
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    struct AssetSearchResult {
        let fingerprint: String
        let policyId: String
        let assetName: String
        let totalSupply: String
        let holderCount: Int
        let hasMetadata: Bool
    }
    
    func searchAssets(
        policyId: String? = nil,
        minSupply: String? = nil,
        maxSupply: String? = nil,
        hasMetadata: Bool? = nil,
        limit: Int = 100
    ) async throws -> [AssetSearchResult] {
        
        var query = Components.Schemas.AssetListQuery()
        query.limit = limit
        
        if let policyId = policyId {
            query.policyId = policyId
        }
        
        let response = try await koios.client.assetList(query: query)
        var assets = try response.ok.body.json
        
        // Apply filters
        if let minSupplyStr = minSupply, let minSupply = Double(minSupplyStr) {
            assets = assets.filter { asset in
                guard let supplyStr = asset.totalSupply,
                      let supply = Double(supplyStr) else { return false }
                return supply >= minSupply
            }
        }
        
        if let maxSupplyStr = maxSupply, let maxSupply = Double(maxSupplyStr) {
            assets = assets.filter { asset in
                guard let supplyStr = asset.totalSupply,
                      let supply = Double(supplyStr) else { return false }
                return supply <= maxSupply
            }
        }
        
        return assets.compactMap { asset in
            guard let fingerprint = asset.fingerprint,
                  let policyId = asset.policyId,
                  let assetName = asset.assetName else { return nil }
            
            return AssetSearchResult(
                fingerprint: fingerprint,
                policyId: policyId,
                assetName: assetName,
                totalSupply: asset.totalSupply ?? "0",
                holderCount: asset.holderCount ?? 0,
                hasMetadata: false // Would need additional API call to determine
            )
        }
    }
}
```

## See Also

- <doc:AddressEndpoints> - Query assets held by specific addresses
- <doc:TransactionEndpoints> - Track asset transfers in transactions
- <doc:NetworkEndpoints> - Access network-wide asset statistics
- <doc:ErrorHandling> - Handle asset query errors