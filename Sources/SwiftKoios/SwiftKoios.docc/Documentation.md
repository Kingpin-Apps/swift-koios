# ``SwiftKoios``

A Swift library providing type-safe, async/await access to Cardano blockchain data through the Koios API.

## Overview

SwiftKoios is a comprehensive Swift Package Manager library that enables iOS, macOS, watchOS, and tvOS applications to interact with the Cardano blockchain through the [Koios API](https://koios.rest/). Built using Swift OpenAPI Generator, it offers type-safe access to blockchain data including transactions, blocks, addresses, stake pools, governance information, and native assets.

### What is Koios?

[Koios](https://koios.rest/) is a decentralized and elastic RESTful query layer for Cardano blockchain data, providing:

- **Comprehensive Access**: Query all aspects of Cardano blockchain data
- **Multiple Networks**: Mainnet, Preprod, Preview, Guild, and Sanchonet support
- **High Performance**: Optimized queries with caching and load balancing
- **Community-Driven**: Open source and community maintained
- **Flexible Authentication**: Free tier available, enhanced features with API keys

### Quick Example

Get the current chain tip information:

```swift
import SwiftKoios

// Create client for Mainnet
let koios = try Koios(network: .mainnet)

// Query current chain tip
let response = try await koios.client.tip()
let tipData = try response.ok.body.json

print("Current epoch: \(tipData[0].epochNo)")
print("Block height: \(tipData[0].blockNo)")
```

## Topics

### Getting Started

- <doc:GettingStarted>
- <doc:Installation>

### Configuration

- <doc:NetworkConfiguration>
- <doc:Authentication>
- <doc:ClientConfiguration>

### Core API Usage

- <doc:NetworkEndpoints>
- <doc:BlockEndpoints> 
- <doc:TransactionEndpoints>
- <doc:AddressEndpoints>
- <doc:AssetEndpoints>
- <doc:PoolEndpoints>
- <doc:GovernanceEndpoints>
- <doc:ScriptEndpoints>

### Error Handling and Best Practices

- <doc:ErrorHandling>
- <doc:BestPractices>
- <doc:Testing>

### Advanced Usage

- <doc:CustomTransport>
- <doc:Middleware>
- <doc:Performance>

### API Reference

- ``Koios``
- ``Network``
- ``KoiosError``
- ``AuthenticationMiddleware``
