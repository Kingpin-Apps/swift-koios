# Network Configuration

Configure SwiftKoios to connect to different Cardano networks for development and production use.

## Overview

SwiftKoios supports all major Cardano networks, allowing you to develop against testnets and deploy to mainnet seamlessly. Each network has different characteristics and use cases.

## Supported Networks

### Mainnet
The production Cardano network where real ADA and native tokens exist.

```swift
let koios = try Koios(network: .mainnet)
```

**Use for:**
- Production applications
- Real transactions and data
- Live stake pool information
- Production dApps

### Preprod
A stable testnet environment that closely mirrors mainnet functionality.

```swift
let koios = try Koios(network: .preprod)
```

**Use for:**
- Pre-production testing
- Integration testing
- Stake pool operator testing
- Final validation before mainnet

### Preview
A testing environment for new features and protocol updates.

```swift
let koios = try Koios(network: .preview)
```

**Use for:**
- Testing new protocol features
- Early development
- Feature validation
- Experimental functionality

### Guild
A network maintained by the community and stake pool operators.

```swift
let koios = try Koios(network: .guild)
```

**Use for:**
- Community-driven testing
- Stake pool operator coordination
- Alternative testing environment

### Sanchonet (Conway Era)
A specialized testnet for testing Conway era governance features.

```swift
let koios = try Koios(network: .sancho)
```

**Use for:**
- Governance feature testing
- Conway era functionality
- Voting and proposal testing
- Constitutional committee operations

## Environment-Based Configuration

### Using Environment Variables

Configure networks based on build environment:

```swift
enum Environment {
    case development
    case staging  
    case production
    
    var network: Network {
        switch self {
        case .development:
            return .preview
        case .staging:
            return .preprod
        case .production:
            return .mainnet
        }
    }
}

func createKoiosClient(for environment: Environment) throws -> Koios {
    return try Koios(network: environment.network)
}
```

### Build Configuration

Use build configurations to automatically select networks:

```swift
#if DEBUG
let defaultNetwork: Network = .preview
#elseif STAGING
let defaultNetwork: Network = .preprod
#else
let defaultNetwork: Network = .mainnet
#endif

let koios = try Koios(network: defaultNetwork)
```

### SwiftUI Environment Integration

Inject network configuration through SwiftUI environment:

```swift
struct NetworkEnvironmentKey: EnvironmentKey {
    static let defaultValue: Network = .mainnet
}

extension EnvironmentValues {
    var koiosNetwork: Network {
        get { self[NetworkEnvironmentKey.self] }
        set { self[NetworkEnvironmentKey.self] = newValue }
    }
}

// Usage in SwiftUI
struct ContentView: View {
    @Environment(\.koiosNetwork) var network
    
    var body: some View {
        // Use network for Koios client creation
        Text("Connected to \\(network)")
    }
}

// App setup
WindowGroup {
    ContentView()
        .environment(\.koiosNetwork, .preprod)
}
```

## Custom Base URLs

For self-hosted Koios instances or custom endpoints:

```swift
let koios = try Koios(
    network: .mainnet,
    basePath: "https://your-custom-koios.example.com/api/v1"
)
```

## Network-Specific Considerations

### Data Differences

Each network contains different data:

```swift
func getNetworkSpecificData(network: Network) async throws {
    let koios = try Koios(network: network)
    
    switch network {
    case .mainnet:
        // Real transaction data, live stake pools
        let pools = try await koios.client.poolList()
        print("Live pools: \\(try pools.ok.body.json.count)")
        
    case .preprod, .preview:
        // Test data, may be reset periodically
        let genesis = try await koios.client.genesis()
        let params = try genesis.ok.body.json
        print("Network ID: \\(params.first?.networkid ?? \"unknown\")")
        
    case .sancho:
        // Conway governance features available
        let dreps = try await koios.client.drepList()
        print("DReps: \\(try dreps.ok.body.json.count)")
        
    case .guild:
        // Community-maintained data
        break
    }
}
```

### Rate Limits

Different networks may have different rate limits:

```swift
struct NetworkConfig {
    let network: Network
    let maxRequestsPerMinute: Int
    let requiresAPIKey: Bool
    
    static let configurations = [
        Network.mainnet: NetworkConfig(
            network: .mainnet,
            maxRequestsPerMinute: 100,
            requiresAPIKey: false
        ),
        Network.preprod: NetworkConfig(
            network: .preprod,
            maxRequestsPerMinute: 200,
            requiresAPIKey: false
        )
    ]
}
```

## Testing with Multiple Networks

### Network Switching

Create a helper for easy network switching during development:

```swift
class KoiosManager: ObservableObject {
    @Published var currentNetwork: Network = .preview
    private var koios: Koios?
    
    func switchNetwork(_ network: Network) throws {
        currentNetwork = network
        koios = try Koios(network: network)
    }
    
    func getClient() throws -> Koios {
        if let koios = koios {
            return koios
        }
        
        let newKoios = try Koios(network: currentNetwork)
        self.koios = newKoios
        return newKoios
    }
}
```

### Network Health Checks

Verify network connectivity:

```swift
func checkNetworkHealth(_ network: Network) async throws -> Bool {
    let koios = try Koios(network: network)
    
    do {
        let response = try await koios.client.tip()
        let tipData = try response.ok.body.json
        return !tipData.isEmpty
    } catch {
        return false
    }
}

// Check all networks
let networks: [Network] = [.mainnet, .preprod, .preview, .guild, .sancho]
for network in networks {
    let healthy = try await checkNetworkHealth(network)
    print("\\(network): \\(healthy ? "✅" : "❌")")
}
```

## Best Practices

### Development Workflow

1. **Development**: Use `.preview` for rapid iteration
2. **Testing**: Use `.preprod` for comprehensive testing  
3. **Staging**: Use `.preprod` for final validation
4. **Production**: Use `.mainnet` for live applications

### Configuration Management

```swift
struct KoiosConfig {
    let network: Network
    let apiKey: String?
    let timeout: TimeInterval
    
    static func development() -> KoiosConfig {
        return KoiosConfig(
            network: .preview,
            apiKey: nil,
            timeout: 30
        )
    }
    
    static func production() -> KoiosConfig {
        return KoiosConfig(
            network: .mainnet,
            apiKey: ProcessInfo.processInfo.environment["KOIOS_API_KEY"],
            timeout: 60
        )
    }
}
```

## See Also

- <doc:Authentication> - Configure API key authentication
- <doc:GettingStarted> - Basic setup and first queries
- <doc:ErrorHandling> - Handle network-specific errors
- [Koios Network Status](https://koios.rest/)