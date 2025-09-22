# Best Practices

Guidelines for building robust and efficient applications with SwiftKoios.

## Overview

Follow these best practices to build reliable, performant, and maintainable applications using SwiftKoios. These guidelines cover API usage patterns, error handling, performance optimization, and security considerations.

## API Usage Patterns

### Rate Limiting

Implement rate limiting to stay within API quotas:

```swift
class RateLimitedKoiosClient {
    private let koios: Koios
    private let semaphore: DispatchSemaphore
    private let requestDelay: TimeInterval
    
    init(network: Network, requestsPerSecond: Double = 10) throws {
        self.koios = try Koios(network: network)
        self.semaphore = DispatchSemaphore(value: 1)
        self.requestDelay = 1.0 / requestsPerSecond
    }
    
    func makeRequest<T>(_ operation: (Koios) async throws -> T) async throws -> T {
        semaphore.wait()
        defer { semaphore.signal() }
        
        let result = try await operation(koios)
        
        // Add delay between requests
        try await Task.sleep(for: .seconds(requestDelay))
        
        return result
    }
}
```

### Batch Operations

Batch multiple requests when possible:

```swift
// ✅ Good: Batch multiple addresses
func getMultipleAddressInfo(addresses: [String]) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.addressInfo(
        body: .init(addresses.map { .init($0) })
    )
    
    let addressData = try response.ok.body.json
    // Process all addresses at once
}

// ❌ Avoid: Individual requests for each address
func getSingleAddressInfo(addresses: [String]) async throws {
    let koios = try Koios(network: .mainnet)
    
    for address in addresses {
        let response = try await koios.client.addressInfo(
            body: .init([.init(address)])
        )
        // This creates unnecessary API calls
    }
}
```

## Caching Strategies

### Implement Intelligent Caching

Cache data based on its volatility:

```swift
class KoiosDataCache {
    private var cache: [String: (data: Any, timestamp: Date)] = [:]
    private let cacheTTL: [String: TimeInterval] = [
        "genesis": 86400,        // 24 hours - never changes
        "tip": 20,               // 20 seconds - changes frequently
        "pools": 3600,           // 1 hour - changes occasionally
        "addresses": 300         // 5 minutes - moderate changes
    ]
    
    func getCachedData<T>(key: String, type: T.Type) -> T? {
        guard let cached = cache[key],
              let ttl = cacheTTL[key],
              Date().timeIntervalSince(cached.timestamp) < ttl else {
            return nil
        }
        
        return cached.data as? T
    }
    
    func setCachedData<T>(key: String, data: T) {
        cache[key] = (data: data, timestamp: Date())
    }
}
```

### Genesis Information Caching

Cache genesis parameters as they never change:

```swift
class GenesisCache {
    private static var cachedGenesis: [GenesisResponse]?
    
    static func getGenesis(koios: Koios) async throws -> [GenesisResponse] {
        if let cached = cachedGenesis {
            return cached
        }
        
        let response = try await koios.client.genesis()
        let genesis = try response.ok.body.json
        cachedGenesis = genesis
        
        return genesis
    }
}
```

## Performance Optimization

### Pagination Handling

Handle large datasets with pagination:

```swift
func getAllPoolsWithPagination() async throws -> [PoolListResponse] {
    let koios = try Koios(network: .mainnet)
    var allPools: [PoolListResponse] = []
    var offset = 0
    let limit = 1000
    
    repeat {
        let response = try await koios.client.poolList(
            query: .init(
                offset: offset,
                limit: limit
            )
        )
        
        let pools = try response.ok.body.json
        allPools.append(contentsOf: pools)
        
        offset += limit
        
        // Break if we got fewer results than requested
        if pools.count < limit {
            break
        }
        
        // Add small delay between requests
        try await Task.sleep(for: .seconds(0.1))
        
    } while true
    
    return allPools
}
```

### Connection Reuse

Reuse Koios clients instead of creating new ones:

```swift
// ✅ Good: Singleton pattern for shared client
class KoiosManager {
    static let shared = try! KoiosManager()
    
    private let mainnetClient: Koios
    private let testnetClient: Koios
    
    private init() throws {
        mainnetClient = try Koios(network: .mainnet)
        testnetClient = try Koios(network: .preprod)
    }
    
    func client(for network: Network) -> Koios {
        switch network {
        case .mainnet:
            return mainnetClient
        default:
            return testnetClient
        }
    }
}

// ❌ Avoid: Creating new clients repeatedly
func makeMultipleRequests() async throws {
    for i in 0..<10 {
        let koios = try Koios(network: .mainnet) // Don't do this
        let response = try await koios.client.tip()
    }
}
```

## Error Handling Strategies

### Graceful Degradation

Implement fallback strategies:

```swift
func getTipWithFallbacks() async throws -> [TipResponse] {
    let networks: [Network] = [.mainnet, .preprod, .preview]
    
    for network in networks {
        do {
            let koios = try Koios(network: network)
            let response = try await koios.client.tip()
            return try response.ok.body.json
        } catch {
            print("Failed to get tip from \\(network): \\(error)")
            continue
        }
    }
    
    throw KoiosError.valueError("All networks failed")
}
```

### Circuit Breaker Implementation

Protect against cascading failures:

```swift
class KoiosCircuitBreaker {
    private enum State {
        case closed, open, halfOpen
    }
    
    private var state: State = .closed
    private var failureCount = 0
    private var lastFailureTime = Date.distantPast
    private let threshold = 5
    private let timeout: TimeInterval = 60
    
    func execute<T>(_ operation: () async throws -> T) async throws -> T {
        switch state {
        case .open:
            if Date().timeIntervalSince(lastFailureTime) > timeout {
                state = .halfOpen
            } else {
                throw KoiosError.valueError("Circuit breaker is open")
            }
            
        case .halfOpen, .closed:
            break
        }
        
        do {
            let result = try await operation()
            onSuccess()
            return result
        } catch {
            onFailure()
            throw error
        }
    }
    
    private func onSuccess() {
        failureCount = 0
        state = .closed
    }
    
    private func onFailure() {
        failureCount += 1
        lastFailureTime = Date()
        
        if failureCount >= threshold {
            state = .open
        }
    }
}
```

## Security Best Practices

### API Key Management

Never hardcode API keys:

```swift
// ✅ Good: Environment variables
class SecureKoiosConfig {
    static func createClient() throws -> Koios {
        guard let apiKey = ProcessInfo.processInfo.environment["KOIOS_API_KEY"] else {
            // Use unauthenticated client for development
            return try Koios(network: .mainnet)
        }
        
        return try Koios(network: .mainnet, apiKey: apiKey)
    }
}

// ❌ Bad: Hardcoded keys
let koios = try Koios(
    network: .mainnet, 
    apiKey: "sk_live_123456..." // Never do this!
)
```

### Input Validation

Validate all inputs before making API calls:

```swift
func validateAndQueryAddress(_ address: String) async throws {
    // Basic validation
    guard !address.isEmpty else {
        throw KoiosError.valueError("Address cannot be empty")
    }
    
    guard address.count >= 50 && address.count <= 120 else {
        throw KoiosError.valueError("Invalid address length")
    }
    
    // Check address format (basic)
    let validPrefixes = ["addr", "addr_test", "stake", "stake_test"]
    guard validPrefixes.contains(where: address.hasPrefix) else {
        throw KoiosError.valueError("Invalid address format")
    }
    
    let koios = try Koios(network: .mainnet)
    let response = try await koios.client.addressInfo(
        body: .init([.init(address)])
    )
    
    // Process response...
}
```

## Testing Strategies

### Mock Responses

Create mock responses for testing:

```swift
#if DEBUG
class MockKoiosTransport: HTTPClientTransport {
    private let mockResponses: [String: Data] = [
        "tip": """
        [{"hash":"abc123","epoch_no":450,"abs_slot":12345}]
        """.data(using: .utf8)!
    ]
    
    func send(_ request: HTTPRequest, body: HTTPBody?) async throws -> HTTPResponse {
        // Return mock response based on endpoint
        let endpoint = request.path?.components(separatedBy: "/").last ?? ""
        
        guard let mockData = mockResponses[endpoint] else {
            throw URLError(.badServerResponse)
        }
        
        return HTTPResponse(
            status: .ok,
            headerFields: [.contentType: "application/json"],
            body: HTTPBody(mockData)
        )
    }
}

// Usage in tests
let mockClient = Client(
    serverURL: URL(string: "https://api.koios.rest/api/v1")!,
    transport: MockKoiosTransport()
)
let koios = Koios(client: mockClient, network: .mainnet)
#endif
```

## Monitoring and Logging

### Request Logging

Log API requests for debugging:

```swift
import os.log

extension Logger {
    static let koiosAPI = Logger(subsystem: "com.yourapp.koios", category: "api")
}

func loggedRequest<T>(_ endpoint: String, operation: () async throws -> T) async throws -> T {
    let startTime = Date()
    Logger.koiosAPI.info("Starting \\(endpoint) request")
    
    do {
        let result = try await operation()
        let duration = Date().timeIntervalSince(startTime)
        Logger.koiosAPI.info("Completed \\(endpoint) in \\(duration, privacy: .public)s")
        return result
    } catch {
        let duration = Date().timeIntervalSince(startTime)
        Logger.koiosAPI.error("Failed \\(endpoint) after \\(duration, privacy: .public)s: \\(error, privacy: .public)")
        throw error
    }
}
```

## Resource Management

### Memory Management

Be mindful of memory usage with large datasets:

```swift
func processLargeDataset() async throws {
    let koios = try Koios(network: .mainnet)
    
    // Process in chunks to avoid memory issues
    let chunkSize = 1000
    var offset = 0
    
    repeat {
        autoreleasepool {
            let response = try await koios.client.txInfo(
                query: .init(
                    offset: offset,
                    limit: chunkSize
                )
            )
            
            let transactions = try response.ok.body.json
            
            // Process chunk
            processTransactionChunk(transactions)
            
            offset += chunkSize
        }
    } while true
}
```

## See Also

- <doc:ErrorHandling> - Comprehensive error handling strategies
- <doc:Authentication> - Secure API key management
- <doc:NetworkConfiguration> - Network-specific best practices
- <doc:Testing> - Testing patterns and mock implementations