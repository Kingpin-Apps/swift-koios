# Getting Started

Learn how to integrate SwiftKoios into your project and make your first API call.

## Overview

This guide walks you through adding SwiftKoios to your project, creating a client, and making your first query to the Cardano blockchain via Koios API.

## Installation

### Swift Package Manager

Add SwiftKoios to your project using Swift Package Manager:

#### In Xcode:
1. Go to **File → Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/Kingpin-Apps/swift-koios`
3. Select the version range and click **Add Package**
4. Add SwiftKoios to your target

#### In Package.swift:
```swift
dependencies: [
    .package(url: "https://github.com/Kingpin-Apps/swift-koios", from: "1.0.0")
]
```

Then add it to your target dependencies:
```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftKoios", package: "swift-koios")
    ]
)
```

## Your First Query

### Basic Setup

Import SwiftKoios and create a client:

```swift
import SwiftKoios

// Create a Koios client for Mainnet
let koios = try Koios(network: .mainnet)
```

### Query Chain Information

Let's start with a simple query to get the current blockchain tip:

```swift
import SwiftKoios

func getCurrentTip() async throws {
    // Initialize client
    let koios = try Koios(network: .mainnet)
    
    // Query the current chain tip
    let response = try await koios.client.tip()
    let tipData = try response.ok.body.json
    
    guard let tip = tipData.first else {
        print("No tip data available")
        return
    }
    
    print("Current Blockchain State:")
    print("- Epoch: \(tip.epochNo ?? 0)")
    print("- Block: \(tip.blockNo ?? 0)")
    print("- Slot: \(tip.absSlot ?? 0)")
    print("- Hash: \(tip.hash ?? "unknown")")
}

// Usage
Task {
    do {
        try await getCurrentTip()
    } catch {
        print("Error fetching tip: \(error)")
    }
}
```

### Query Address Information

Here's how to get information about a specific address:

```swift
func getAddressInfo(address: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.addressInfo(
        body: .init([.init(address)])
    )
    
    let addresses = try response.ok.body.json
    
    for addressInfo in addresses {
        print("Address: \(addressInfo.address ?? "unknown")")
        print("Balance: \(addressInfo.balance ?? "0") lovelace")
        print("Stake Address: \(addressInfo.stakeAddress ?? "none")")
    }
}

// Example usage
Task {
    try await getAddressInfo(
        address: "addr1qx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwq2ytjqp"
    )
}
```

## Network Selection

SwiftKoios supports multiple Cardano networks:

```swift
// Mainnet (production)
let mainnet = try Koios(network: .mainnet)

// Preprod testnet
let preprod = try Koios(network: .preprod)

// Preview testnet  
let preview = try Koios(network: .preview)

// Guild network
let guild = try Koios(network: .guild)

// Sanchonet (Conway era testnet)
let sancho = try Koios(network: .sancho)
```

## Error Handling

Always wrap API calls in do-catch blocks:

```swift
do {
    let koios = try Koios(network: .mainnet)
    let response = try await koios.client.tip()
    let tipData = try response.ok.body.json
    
    // Process data
    print("Success: \(tipData.count) records")
    
} catch let error as KoiosError {
    switch error {
    case .invalidBasePath(let message):
        print("Invalid base path: \(message ?? "unknown")")
    case .missingAPIKey(let message):
        print("Missing API key: \(message ?? "unknown")")
    case .valueError(let message):
        print("Value error: \(message ?? "unknown")")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

## Next Steps

Now that you have SwiftKoios working, explore more advanced features:

- <doc:NetworkConfiguration> - Configure different Cardano networks
- <doc:Authentication> - Add API key authentication for enhanced rate limits  
- <doc:NetworkEndpoints> - Query blockchain network information
- <doc:TransactionEndpoints> - Access transaction data
- <doc:AddressEndpoints> - Explore address and UTxO information

## See Also

- [Koios API Documentation](https://api.koios.rest/)
- [Cardano Developer Portal](https://developers.cardano.org/)
- <doc:ErrorHandling>