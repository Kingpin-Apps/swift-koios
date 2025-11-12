# Vertical Filtering

Optimize API performance by selecting only the fields you need.

## Overview

SwiftKoios supports the `select` query parameter for vertical filtering, allowing you to specify which fields to return in API responses. This follows PostgREST's vertical filtering semantics and is available on all GET endpoints that return data.

Vertical filtering provides several key benefits:
- **Reduce bandwidth**: Only fetch the fields you need
- **Improve performance**: Smaller response payloads mean faster processing
- **Optimize memory**: Less data to parse and store
- **Make your code clearer**: Explicitly state which data you're using

## Basic Usage

### Requesting Specific Fields

Use the `select` parameter to specify which fields you want returned:

```swift
import SwiftKoios

let koios = try Koios(network: .mainnet)

// Request only specific fields
let response = try await koios.client.tip(
    Operations.Tip.Input(
        query: .init(
            select: ["hash", "epoch_no", "block_height"]
        )
    )
)
```

This generates the following HTTP request:
```
GET https://api.koios.rest/api/v1/tip?select=hash,epoch_no,block_height
```

### Default Behavior (All Fields)

If you omit the `select` parameter, all fields are returned:

```swift
let response = try await koios.client.tip(
    Operations.Tip.Input()
)
// Returns all available fields in the response
```

## Common Use Cases

### Minimal Data Queries

When you only need to check basic information:

```swift
// Just get the current block height
let tip = try await koios.client.tip(
    Operations.Tip.Input(
        query: .init(select: ["block_height"])
    )
)

// Just get pool tickers
let pools = try await koios.client.poolList(
    Operations.PoolList.Input(
        query: .init(select: ["pool_id_bech32", "ticker"])
    )
)
```

### Summary Views

Perfect for displaying lists or summaries:

```swift
// Get block summary for a list view
let blocks = try await koios.client.blocks(
    Operations.Blocks.Input(
        query: .init(
            select: ["hash", "epoch_no", "block_height", "block_time", "tx_count"]
        )
    )
)

// Display in UI
for block in blocks {
    print("Block \(block.block_height ?? 0) - \(block.tx_count ?? 0) transactions")
}
```

### Combining with Other Parameters

Use `select` alongside other query parameters:

```swift
// Get pool delegators with only essential fields
let delegators = try await koios.client.poolDelegators(
    Operations.PoolDelegators.Input(
        query: .init(
            select: ["stake_address", "amount", "active_epoch_no"],
            _pool_bech32: "pool1..."
        )
    )
)
```

## Performance Optimization

### Creating Reusable Field Sets

Define commonly used field selections as constants:

```swift
extension Operations.Tip.Input.Query {
    static let minimal = Self(select: ["hash", "block_height"])
    static let summary = Self(select: ["hash", "epoch_no", "block_height", "block_time"])
    static let complete = Self() // All fields
}

// Usage
let tip = try await koios.client.tip(
    Operations.Tip.Input(query: .minimal)
)
```

### Pagination with Filtering

Combine with pagination for efficient large dataset processing:

```swift
func getAllPoolsSummary() async throws -> [PoolSummary] {
    var allPools: [PoolSummary] = []
    var offset = 0
    let limit = 1000
    
    repeat {
        let response = try await koios.client.poolList(
            Operations.PoolList.Input(
                query: .init(
                    select: ["pool_id_bech32", "ticker", "active_stake"],
                    offset: offset,
                    limit: limit
                )
            )
        )
        
        guard case .ok(let result) = response,
              case .json(let pools) = result.body else {
            break
        }
        
        // Process reduced dataset
        allPools.append(contentsOf: pools.compactMap { pool in
            PoolSummary(
                id: pool.pool_id_bech32 ?? "",
                ticker: pool.ticker ?? "",
                stake: pool.active_stake ?? ""
            )
        })
        
        offset += limit
        
        if pools.count < limit {
            break
        }
    } while true
    
    return allPools
}
```

## Available Endpoints

The `select` parameter is available on all GET endpoints that return data, including:

### Network Endpoints
- `tip()` - Chain tip information
- `genesis()` - Genesis parameters
- `totals()` - Historical tokenomics
- `paramUpdates()` - Parameter updates
- `cliProtocolParams()` - Protocol parameters
- `reserveWithdrawals()` - Reserve withdrawals
- `treasuryWithdrawals()` - Treasury withdrawals

### Epoch Endpoints
- `epochInfo()` - Epoch information
- `epochParams()` - Epoch parameters
- `epochBlockProtocols()` - Block protocol distribution

### Block Endpoints
- `blocks()` - Block list

### Transaction Endpoints
- `txMetalabels()` - Transaction metadata labels

### Account Endpoints
- `accountList()` - All stake accounts
- `accountTxs()` - Account transactions

### Asset Endpoints
- `assetList()` - All native assets
- `policyAssetList()` - Assets under policy
- `assetTokenRegistry()` - Token registry entries
- `assetHistory()` - Mint/burn history
- `assetAddresses()` - Asset holder addresses
- `assetNftAddress()` - NFT current address
- `policyAssetAddresses()` - Policy asset addresses
- `policyAssetInfo()` - Policy asset information
- `policyAssetMints()` - Policy asset mints
- `assetSummary()` - Asset summary
- `assetTxs()` - Asset transactions

### Governance Endpoints
- `drepEpochSummary()` - DRep epoch summary
- `drepList()` - All DReps
- `drepUpdates()` - DRep updates
- `drepVotingPowerHistory()` - DRep voting power
- `drepDelegators()` - DRep delegators
- `committeeInfo()` - Committee information
- `committeeVotes()` - Committee votes
- `proposalList()` - All proposals
- `voterProposalList()` - Voter proposals
- `proposalVotingSummary()` - Proposal voting summary
- `proposalVotes()` - Proposal votes
- `voteList()` - All votes

### Pool Endpoints
- `poolList()` - All pools
- `poolStakeSnapshot()` - Pool stake snapshot
- `poolDelegators()` - Pool delegators
- `poolDelegatorsHistory()` - Pool delegator history
- `poolBlocks()` - Pool blocks
- `poolHistory()` - Pool history
- `poolUpdates()` - Pool updates
- `poolRegistrations()` - Pool registrations
- `poolRetirements()` - Pool retirements
- `poolRelays()` - Pool relays
- `poolVotingPowerHistory()` - Pool voting power
- `poolGroups()` - Pool groups
- `poolCalidusKeys()` - Pool Calidus keys

### Script Endpoints
- `nativeScriptList()` - Native scripts
- `plutusScriptList()` - Plutus scripts
- `scriptRedeemers()` - Script redeemers
- `scriptUtxos()` - Script UTXOs

## Field Names

You are responsible for knowing the correct field names for each endpoint. Field names should match the response schema defined in the API specification.

### Common Field Names

- `hash` - Transaction or block hash
- `epoch_no` - Epoch number
- `block_height` - Block height
- `block_time` - Block timestamp
- `tx_hash` - Transaction hash
- `address` - Payment address
- `stake_address` - Stake address
- `pool_id` / `pool_id_bech32` - Pool identifier
- `asset_name` - Asset name
- `policy_id` - Policy identifier
- `amount` - Amount value
- `balance` - Balance value

### Finding Field Names

Refer to the [Koios API documentation](https://api.koios.rest/) for complete field listings per endpoint. You can also examine the response schemas in the generated Swift types.

## Technical Details

### Implementation

The `select` parameter is:
- Defined as `[String]` (array of strings) in Swift
- Serialized as comma-separated values in the URL (using `style: form, explode: false`)
- Optional on all applicable GET endpoints
- Automatically generated from the OpenAPI specification

### PostgREST Semantics

This implementation follows PostgREST's vertical filtering specification:
- Field names are comma-separated in the query string
- Only specified fields are returned in the response
- Invalid field names are silently ignored by the server
- Works for top-level fields in the response schema

### Example URL Generation

```swift
// Input: select: ["hash", "epoch_no", "block_height"]
// Generated URL: /tip?select=hash,epoch_no,block_height

// Input: select: ["pool_id_bech32", "ticker", "active_stake"]
// Generated URL: /pool_list?select=pool_id_bech32,ticker,active_stake
```

## Limitations

- Only supports top-level field selection
- Nested field selection (e.g., `select=object.field`) is not currently supported
- Field name validation is done server-side only
- The client trusts the caller to provide valid field names
- Invalid field names are silently ignored by the API

## Migration Guide

Existing code without the `select` parameter continues to work unchanged - all fields are returned by default.

### Migration Steps

1. **Identify optimization opportunities**: Find endpoints where you only use a subset of response fields
2. **Add the select parameter**: Specify only the fields you actually use
3. **Test thoroughly**: Verify the response contains the expected data
4. **Measure improvements**: Compare bandwidth usage and response times

### Before and After Example

```swift
// Before: Getting all fields
let response = try await koios.client.poolList(
    Operations.PoolList.Input()
)
// Bandwidth: ~500KB for 1000 pools

// After: Getting only needed fields
let response = try await koios.client.poolList(
    Operations.PoolList.Input(
        query: .init(
            select: ["pool_id_bech32", "ticker", "active_stake"]
        )
    )
)
// Bandwidth: ~150KB for 1000 pools (70% reduction)
```

## Best Practices

### Be Specific

Request only the fields you actually use in your application:

```swift
// ✅ Good: Only request what you need
let pools = try await koios.client.poolList(
    Operations.PoolList.Input(
        query: .init(select: ["pool_id_bech32", "ticker"])
    )
)

// ❌ Avoid: Requesting all fields when you only use a few
let pools = try await koios.client.poolList(
    Operations.PoolList.Input()
)
// Then only using pool_id_bech32 and ticker
```

### Profile Your Usage

Measure the impact of vertical filtering:

```swift
import Foundation

func measureQueryPerformance() async throws {
    let koios = try Koios(network: .mainnet)
    
    // Without filtering
    let start1 = Date()
    let full = try await koios.client.poolList(Operations.PoolList.Input())
    let duration1 = Date().timeIntervalSince(start1)
    
    // With filtering
    let start2 = Date()
    let filtered = try await koios.client.poolList(
        Operations.PoolList.Input(
            query: .init(select: ["pool_id_bech32", "ticker"])
        )
    )
    let duration2 = Date().timeIntervalSince(start2)
    
    print("Full query: \(duration1)s")
    print("Filtered query: \(duration2)s")
    print("Improvement: \(Int((1 - duration2/duration1) * 100))%")
}
```

### Document Your Field Usage

When defining reusable queries, document why those specific fields are needed:

```swift
extension Operations.PoolList.Input.Query {
    /// Minimal fields for pool search/autocomplete
    static let search = Self(select: ["pool_id_bech32", "ticker"])
    
    /// Fields for pool list view
    static let listView = Self(select: [
        "pool_id_bech32",
        "ticker",
        "active_stake",
        "live_stake",
        "live_delegators"
    ])
    
    /// Fields for detailed pool view
    static let detailView = Self(select: [
        "pool_id_bech32",
        "ticker",
        "active_stake",
        "live_stake",
        "live_delegators",
        "live_saturation",
        "pool_status",
        "margin",
        "fixed_cost"
    ])
}
```

## See Also

- ``BestPractices``
- ``ClientConfiguration``
- ``NetworkConfiguration``
- [Koios API Documentation](https://api.koios.rest/)
- [PostgREST Vertical Filtering](https://postgrest.org/en/stable/api.html#vertical-filtering-columns)
