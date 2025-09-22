# ``SwiftKoios``

A Swift client library for the Koios REST API, providing comprehensive access to Cardano blockchain data.

## Overview

SwiftKoios is a modern Swift library that wraps the Koios REST API, offering type-safe access to Cardano blockchain data. Built on Apple's OpenAPI runtime, it provides async/await support, comprehensive error handling, and strong typing for all API responses.

The Koios API is a decentralized and elastic RESTful query layer for exploring data on the Cardano blockchain, perfect for building applications, wallets, explorers, and other Cardano ecosystem tools.

```swift
import SwiftKoios

// Initialize the client
let koios = try Koios(network: .mainnet)

// Query the blockchain
let response = try await koios.client.tip()
let tipInfo = try response.ok.body.json

print("Current block height: \(tipInfo.blockHeight)")
```

## Topics

### Getting Started

Learn the basics of setting up and using SwiftKoios in your projects.

- <doc:GettingStarted>
- <doc:Installation>
- <doc:Swift-Package-Manager>
- <doc:Authentication>

### Configuration and Setup

Configure SwiftKoios for different environments and use cases.

- <doc:ClientConfiguration>
- <doc:NetworkConfiguration>
- <doc:Error-Handling>
- <doc:Testing>

### API Reference

Comprehensive reference for all available Koios endpoints.

- <doc:API-Reference>
- <doc:NetworkEndpoints>
- <doc:BlockEndpoints>
- <doc:TransactionEndpoints>
- <doc:AddressEndpoints>
- <doc:AssetEndpoints>
- <doc:PoolEndpoints>
- <doc:GovernanceEndpoints>
- <doc:ScriptEndpoints>

### Best Practices

Guidelines and patterns for building robust Cardano applications.

- <doc:BestPractices>
- <doc:Documentation>

## Key Features

### Type Safety
SwiftKoios uses generated Swift types from the OpenAPI specification, ensuring compile-time safety and reducing runtime errors.

### Async/Await Support
All API calls use modern Swift concurrency, making it easy to write efficient and readable asynchronous code.

### Comprehensive Error Handling
Detailed error types help you handle different failure scenarios gracefully.

### Multi-Network Support
Support for mainnet, preprod, preview, guild, and sancho networks with easy switching.

### Authentication
Built-in support for API key authentication with multiple configuration options.

## Supported Networks

- **Mainnet**: Production Cardano network
- **Preprod**: Pre-production testing network
- **Preview**: Development and testing network
- **Guild**: Community-run testing network  
- **Sancho**: Conway era governance testing network

## Quick Examples

### Query Chain Information

```swift
// Get current chain tip
let tipResponse = try await koios.client.tip()
let tip = try tipResponse.ok.body.json
print("Block \(tip.blockHeight) at epoch \(tip.epochNo)")

// Get genesis parameters
let genesisResponse = try await koios.client.genesis()
let genesis = try genesisResponse.ok.body.json
```

### Address and UTxO Queries

```swift
// Get address information
let addressResponse = try await koios.client.address_info(.init(
    body: .json(["addr1q9ag5tntq..."])
))
let addresses = try addressResponse.ok.body.json

// Get UTxOs for an address
let utxoResponse = try await koios.client.address_utxos(.init(
    body: .json(["addr1q9ag5tntq..."])
))
let utxos = try utxoResponse.ok.body.json
```

### Transaction Information

```swift
// Get transaction details
let txResponse = try await koios.client.tx_info(.init(
    body: .json(["tx_hash_here"])
))
let transactions = try txResponse.ok.body.json

// Submit a transaction
let submitResponse = try await koios.client.submittx(.init(
    body: .json("cbor_hex_string")
))
```

### Asset and Token Queries

```swift
// Get asset information
let assetResponse = try await koios.client.asset_info(.init(
    body: .json(["policy_id.asset_name"])
))
let assets = try assetResponse.ok.body.json

// List all assets for a policy
let policyResponse = try await koios.client.policy_asset_list(.init(
    query: .init(_asset_policy: "policy_id")
))
let policyAssets = try policyResponse.ok.body.json
```

### Stake Pool Information

```swift
// List all pools
let poolsResponse = try await koios.client.pool_list()
let pools = try poolsResponse.ok.body.json

// Get specific pool information
let poolInfoResponse = try await koios.client.pool_info(.init(
    body: .json(["pool_id"])
))
let poolInfo = try poolInfoResponse.ok.body.json
```

### Governance Queries (Conway Era)

```swift
// List all DReps
let drepsResponse = try await koios.client.drep_list()
let dreps = try drepsResponse.ok.body.json

// Get governance proposals
let proposalsResponse = try await koios.client.proposal_list()
let proposals = try proposalsResponse.ok.body.json
```

## Requirements

- **iOS**: 13.0+
- **macOS**: 10.15+
- **tvOS**: 13.0+
- **watchOS**: 6.0+
- **Swift**: 5.9+
- **Xcode**: 15.0+

## Installation

SwiftKoios is available through Swift Package Manager. Add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/[organization]/swift-koios.git", from: "1.0.0")
]
```

Or add it through Xcode's package manager interface.

## License

SwiftKoios is available under the [appropriate license]. See the LICENSE file for more info.

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

## Support

- [Koios API Documentation](https://koios.rest)
- [Koios Telegram Community](https://t.me/CardanoKoios)
- [GitHub Issues](https://github.com/[organization]/swift-koios)
- [API Status Page](https://status.koios.rest)

## Acknowledgments

SwiftKoios is built on top of the excellent Koios API service provided by the Cardano community. Special thanks to the Koios team for maintaining this invaluable infrastructure.