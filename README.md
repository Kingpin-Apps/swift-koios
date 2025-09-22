# SwiftKoios

A Swift library for accessing the Koios API, providing comprehensive access to Cardano blockchain data.

[![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-blue.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview

SwiftKoios is a Swift Package Manager library that provides a type-safe, async/await interface to the [Koios API](https://koios.rest/). It allows iOS, macOS, watchOS, and tvOS applications to easily access Cardano blockchain data including transactions, blocks, addresses, stake pools, governance information, and more.

The library is built using Swift OpenAPI Generator, ensuring type safety and automatic code generation from the official Koios OpenAPI specification.

## What is Koios?

[Koios](https://koios.rest/) is a decentralized and elastic RESTful query layer for exploring Cardano blockchain data. It provides:

- **Comprehensive Data Access**: Query transactions, blocks, addresses, UTxOs, stake pools, governance data, and more
- **Multiple Networks**: Support for Mainnet, Preprod, Preview, Guild, and Sanchonet
- **High Performance**: Optimized queries with caching and load balancing
- **Open Source**: Community-driven development and maintenance
- **Premium Features**: Enhanced rate limits and priority support with API keys

## Features

- ✅ **Complete API Coverage**: Access to all Koios endpoints
- ✅ **Type-Safe**: Generated Swift types from OpenAPI specification
- ✅ **Async/Await**: Modern Swift concurrency support
- ✅ **Multi-Platform**: iOS 14+, macOS 13+, watchOS 7+, tvOS 14+
- ✅ **Network Support**: Mainnet, Preprod, Preview, Guild, Sanchonet
- ✅ **Authentication**: Optional API key support for enhanced limits
- ✅ **Error Handling**: Comprehensive error types and handling
- ✅ **Testing**: Mock transport for unit testing

## Installation

### Swift Package Manager

Add SwiftKoios to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Kingpin-Apps/swift-koios", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select version and add to your target

## Quick Start

### Basic Usage (No API Key)

```swift
import SwiftKoios

// Create a client for Mainnet
let koios = try Koios(network: .mainnet)

// Query chain tip
let tip = try await koios.client.tip()
let tipData = try tip.ok.body.json
print("Current epoch: \(tipData[0].epochNo)")

// Query genesis parameters
let genesis = try await koios.client.genesis()
let genesisData = try genesis.ok.body.json
print("Network: \(genesisData[0].networkid)")
```

### Using API Key

```swift
// With explicit API key
let koios = try Koios(
    network: .mainnet,
    apiKey: "your-api-key-here"
)

// From environment variable
let koios = try Koios(
    network: .mainnet,
    environmentVariable: "KOIOS_API_KEY"
)
```

### Querying Address Information

```swift
// Get address information
let addressInfo = try await koios.client.addressInfo(
    body: .init([
        .init("addr1qy2jt0qpqz2z2z3z2z2z2z2z2z2z2z2z2z2z2z2z2z2z2z2z2z2z2z2z")
    ])
)
let addresses = try addressInfo.ok.body.json

for address in addresses {
    print("Balance: \(address.balance ?? "0") lovelace")
    print("UTxO count: \(address.utxoSet?.count ?? 0)")
}
```

### Pool Information

```swift
// Get pool information
let poolInfo = try await koios.client.poolInfo(
    body: .init([
        .init("pool1abc123...")  // Bech32 pool ID
    ])
)
let pools = try poolInfo.ok.body.json

for pool in pools {
    print("Pool: \(pool.poolIdBech32 ?? "unknown")")
    print("Ticker: \(pool.metaJson?.ticker ?? "N/A")")
    print("Live stake: \(pool.liveStake ?? "0")")
}
```

### Transaction Details

```swift
// Get transaction information
let txInfo = try await koios.client.txInfo(
    body: .init(.init(txHashes: [
        "abc123def456..."  // Transaction hash
    ]))
)
let transactions = try txInfo.ok.body.json

for tx in transactions {
    print("TX Hash: \(tx.txHash)")
    print("Fee: \(tx.fee ?? "0") lovelace")
    print("Block height: \(tx.blockHeight)")
}
```

## Networks

SwiftKoios supports multiple Cardano networks:

```swift
// Mainnet (default)
let mainnet = try Koios(network: .mainnet)

// Preprod testnet
let preprod = try Koios(network: .preprod)

// Preview testnet
let preview = try Koios(network: .preview)

// Guild network
let guild = try Koios(network: .guild)

// Sanchonet (Conway testnet)
let sancho = try Koios(network: .sancho)
```

## Custom Base URL

```swift
// Use custom Koios instance
let koios = try Koios(
    network: .mainnet,
    basePath: "https://your-custom-koios-instance.com/api/v1"
)
```

## Error Handling

```swift
do {
    let tip = try await koios.client.tip()
    let tipData = try tip.ok.body.json
    // Handle success
} catch let error as KoiosError {
    switch error {
    case .invalidBasePath(let message):
        print("Invalid base path: \(message)")
    case .missingAPIKey(let message):
        print("Missing API key: \(message)")
    case .valueError(let message):
        print("Value error: \(message)")
    }
} catch {
    print("Other error: \(error)")
}
```

## Available Endpoints

SwiftKoios provides access to all Koios API endpoints:

### Network
- `tip()` - Get current chain tip
- `genesis()` - Get genesis parameters
- `totals()` - Get historical tokenomics
- `paramUpdates()` - Get parameter updates
- `epochInfo()` - Get epoch information

### Blocks
- `blocks()` - Get block list
- `blockInfo()` - Get block information
- `blockTxs()` - Get block transactions

### Transactions
- `txInfo()` - Get transaction details
- `txMetadata()` - Get transaction metadata
- `txCbor()` - Get raw transaction CBOR
- `txStatus()` - Get transaction confirmations

### Addresses
- `addressInfo()` - Get address information
- `addressTxs()` - Get address transactions
- `addressAssets()` - Get address assets

### Assets
- `assetList()` - Get native asset list
- `assetInfo()` - Get asset information
- `assetHistory()` - Get asset mint/burn history
- `assetAddresses()` - Get asset holder addresses

### Pool
- `poolList()` - Get all pools
- `poolInfo()` - Get pool information
- `poolDelegators()` - Get pool delegators
- `poolHistory()` - Get pool history
- `poolMetadata()` - Get pool metadata

### Governance (Conway Era)
- `drepList()` - Get DRep list
- `drepInfo()` - Get DRep information
- `proposalList()` - Get governance proposals
- `committeeInfo()` - Get committee information

### Scripts
- `scriptInfo()` - Get script information
- `datumInfo()` - Get datum information

## Testing

SwiftKoios includes comprehensive test support with mock data:

```swift
import SwiftKoios

// Create mock client for testing
let mockKoios = try Koios(
    network: .mainnet,
    apiKey: "test-key",
    client: Client(
        serverURL: URL(string: "https://api.koios.rest/api/v1")!,
        transport: MockTransport()  // Your mock transport
    )
)
```

Run tests:

```bash
swift test
```


## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

### Development Setup

```bash
# Clone the repository
git clone https://github.com/Kingpin-Apps/swift-koios
cd swift-koios

# Run tests
swift test

# Build the project
swift build
```

## Documentation

### Official Koios Documentation
- [Koios Website](https://koios.rest/)
- [API Documentation](https://api.koios.rest/)
- [Koios GitHub](https://github.com/koios-official)
- [Discord Community](https://discord.gg/JUbmRFrBaP)

### Cardano Resources
- [Cardano Developer Portal](https://developers.cardano.org/)
- [Cardano Foundation](https://cardanofoundation.org/)
- [IOHK Research](https://iohk.io/en/research/)

### Swift OpenAPI
- [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator)
- [OpenAPI Runtime](https://github.com/apple/swift-openapi-runtime)


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Koios Team](https://koios.rest/) for providing the excellent API
- [Cardano Community](https://cardano.org/) for the amazing ecosystem
- [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator) for code generation tools

## Support

- **Issues**: [GitHub Issues](https://github.com/Kingpin-Apps/swift-koios/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Kingpin-Apps/swift-koios/discussions)

---

