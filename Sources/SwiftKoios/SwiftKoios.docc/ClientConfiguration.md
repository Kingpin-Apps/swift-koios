# Client Configuration

Configure SwiftKoios client settings, timeouts, transport options, and middleware.

## Overview

SwiftKoios provides flexible client configuration options allowing you to customize network behavior, timeouts, transport settings, and middleware for your specific use case. This guide covers advanced configuration patterns for production applications.

## Basic Client Configuration

### Default Configuration

The simplest way to create a Koios client uses default settings:

```swift
// Basic client with default configuration
let koios = try Koios(network: .mainnet)
```

### Custom Base URL

Configure a custom Koios instance endpoint:

```swift
let koios = try Koios(
    network: .mainnet,
    basePath: "https://your-koios-instance.example.com/api/v1"
)
```

## Custom Transport Configuration

### URLSession Configuration

Customize the underlying URLSession for advanced networking needs:

```swift
import Foundation
import OpenAPIURLSession

func createCustomKoiosClient() throws -> Koios {
    // Create custom URLSession configuration
    let sessionConfig = URLSessionConfiguration.default
    sessionConfig.timeoutIntervalForRequest = 30.0
    sessionConfig.timeoutIntervalForResource = 120.0
    sessionConfig.urlCache = URLCache(
        memoryCapacity: 10 * 1024 * 1024, // 10MB memory cache
        diskCapacity: 100 * 1024 * 1024,  // 100MB disk cache
        diskPath: nil
    )
    
    // Configure additional headers
    sessionConfig.httpAdditionalHeaders = [
        "User-Agent": "SwiftKoios/1.0.0 MyApp/1.0.0"
    ]
    
    // Create URLSession with custom configuration
    let urlSession = URLSession(configuration: sessionConfig)
    
    // Create transport with custom session
    let transport = URLSessionTransport(session: urlSession)
    
    // Create OpenAPI client with custom transport
    let serverURL = try Network.mainnet.url()
    let client = Client(
        serverURL: serverURL,
        transport: transport,
        middlewares: []
    )
    
    return Koios(client: client, network: .mainnet, apiKey: nil)
}
```

### Connection Pool Settings

Configure connection pooling for high-throughput applications:

```swift
func createHighThroughputClient() throws -> Koios {
    let sessionConfig = URLSessionConfiguration.default
    
    // Configure connection limits
    sessionConfig.httpMaximumConnectionsPerHost = 10
    sessionConfig.httpShouldUsePipelining = true
    
    // Enable HTTP/2
    sessionConfig.httpProtocolClass = NSHTTPProtocol.self
    
    let urlSession = URLSession(configuration: sessionConfig)
    let transport = URLSessionTransport(session: urlSession)
    
    let serverURL = try Network.mainnet.url()
    let client = Client(
        serverURL: serverURL,
        transport: transport,
        middlewares: []
    )
    
    return Koios(client: client, network: .mainnet, apiKey: nil)
}
```

## Middleware Configuration

### Authentication Middleware

Configure API key authentication middleware:

```swift
func createAuthenticatedClient(apiKey: String) throws -> Koios {
    let authMiddleware = AuthenticationMiddleware(
        authorizationHeaderFieldValue: apiKey
    )
    
    let serverURL = try Network.mainnet.url()
    let client = Client(
        serverURL: serverURL,
        transport: URLSessionTransport(),
        middlewares: [authMiddleware]
    )
    
    return Koios(client: client, network: .mainnet, apiKey: apiKey)
}
```

### Logging Middleware

Add request/response logging for debugging:

```swift
import OpenAPIRuntime
import os.log

struct LoggingMiddleware: ClientMiddleware {
    private let logger = Logger(subsystem: "com.yourapp.koios", category: "networking")
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        
        let startTime = Date()
        
        logger.info("🚀 Starting request: \(operationID)")
        logger.debug("  Method: \(request.method.rawValue)")
        logger.debug("  Path: \(request.path ?? "unknown")")
        
        do {
            let (response, responseBody) = try await next(request, body, baseURL)
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("✅ Completed request: \(operationID) in \(duration)s")
            logger.debug("  Status: \(response.status.code)")
            
            return (response, responseBody)
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("❌ Failed request: \(operationID) after \(duration)s - \(error)")
            throw error
        }
    }
}

// Usage
func createLoggingClient() throws -> Koios {
    let loggingMiddleware = LoggingMiddleware()
    
    let serverURL = try Network.mainnet.url()
    let client = Client(
        serverURL: serverURL,
        transport: URLSessionTransport(),
        middlewares: [loggingMiddleware]
    )
    
    return Koios(client: client, network: .mainnet, apiKey: nil)
}
```

### Rate Limiting Middleware

Implement client-side rate limiting:

```swift
actor RateLimitingMiddleware: ClientMiddleware {
    private let maxRequestsPerSecond: Double
    private let requestTimes: [Date] = []
    
    init(maxRequestsPerSecond: Double) {
        self.maxRequestsPerSecond = maxRequestsPerSecond
    }
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        
        await enforceRateLimit()
        
        return try await next(request, body, baseURL)
    }
    
    private func enforceRateLimit() async {
        let now = Date()
        let oneSecondAgo = now.addingTimeInterval(-1.0)
        
        // Remove requests older than 1 second
        let recentRequests = requestTimes.filter { $0 > oneSecondAgo }
        
        // Check if we're at the rate limit
        if Double(recentRequests.count) >= maxRequestsPerSecond {
            let oldestRequest = recentRequests.min() ?? now
            let delay = 1.0 - now.timeIntervalSince(oldestRequest)
            
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
        }
        
        // Record this request
        requestTimes.append(now)
    }
}
```

## Advanced Configuration Patterns

### Environment-Based Configuration

Create configuration based on the deployment environment:

```swift
struct KoiosClientConfig {
    let network: Network
    let apiKey: String?
    let timeout: TimeInterval
    let cachePolicy: URLRequest.CachePolicy
    let enableLogging: Bool
    let maxConcurrentRequests: Int
    
    static func development() -> KoiosClientConfig {
        return KoiosClientConfig(
            network: .preview,
            apiKey: ProcessInfo.processInfo.environment["KOIOS_DEV_API_KEY"],
            timeout: 30.0,
            cachePolicy: .reloadIgnoringLocalCacheData,
            enableLogging: true,
            maxConcurrentRequests: 5
        )
    }
    
    static func production() -> KoiosClientConfig {
        return KoiosClientConfig(
            network: .mainnet,
            apiKey: ProcessInfo.processInfo.environment["KOIOS_PROD_API_KEY"],
            timeout: 60.0,
            cachePolicy: .useProtocolCachePolicy,
            enableLogging: false,
            maxConcurrentRequests: 20
        )
    }
}

func createConfiguredClient(_ config: KoiosClientConfig) throws -> Koios {
    // Create URLSession configuration
    let sessionConfig = URLSessionConfiguration.default
    sessionConfig.timeoutIntervalForRequest = config.timeout
    sessionConfig.httpMaximumConnectionsPerHost = config.maxConcurrentRequests
    sessionConfig.requestCachePolicy = config.cachePolicy
    
    let urlSession = URLSession(configuration: sessionConfig)
    let transport = URLSessionTransport(session: urlSession)
    
    // Build middleware stack
    var middlewares: [ClientMiddleware] = []
    
    if let apiKey = config.apiKey {
        middlewares.append(AuthenticationMiddleware(authorizationHeaderFieldValue: apiKey))
    }
    
    if config.enableLogging {
        middlewares.append(LoggingMiddleware())
    }
    
    let serverURL = try config.network.url()
    let client = Client(
        serverURL: serverURL,
        transport: transport,
        middlewares: middlewares
    )
    
    return Koios(client: client, network: config.network, apiKey: config.apiKey)
}
```

### Configuration Factory

Create a factory for managing different client configurations:

```swift
enum KoiosClientFactory {
    static func standard(network: Network, apiKey: String? = nil) throws -> Koios {
        return try Koios(network: network, apiKey: apiKey)
    }
    
    static func development(apiKey: String? = nil) throws -> Koios {
        let config = KoiosClientConfig.development()
        return try createConfiguredClient(config)
    }
    
    static func production(apiKey: String) throws -> Koios {
        var config = KoiosClientConfig.production()
        config = KoiosClientConfig(
            network: config.network,
            apiKey: apiKey,
            timeout: config.timeout,
            cachePolicy: config.cachePolicy,
            enableLogging: config.enableLogging,
            maxConcurrentRequests: config.maxConcurrentRequests
        )
        return try createConfiguredClient(config)
    }
    
    static func testing() throws -> Koios {
        let mockTransport = MockKoiosTransport.withSampleData()
        let client = Client(
            serverURL: URL(string: "https://api.koios.rest/api/v1")!,
            transport: mockTransport
        )
        
        return Koios(client: client, network: .mainnet, apiKey: nil)
    }
}
```

## Performance Optimization

### Connection Reuse

Configure clients for optimal connection reuse:

```swift
class KoiosClientManager {
    static let shared = KoiosClientManager()
    
    private var clients: [Network: Koios] = [:]
    private let lock = NSLock()
    
    private init() {}
    
    func client(for network: Network, apiKey: String? = nil) throws -> Koios {
        lock.lock()
        defer { lock.unlock() }
        
        if let existingClient = clients[network] {
            return existingClient
        }
        
        let newClient = try createOptimizedClient(network: network, apiKey: apiKey)
        clients[network] = newClient
        
        return newClient
    }
    
    private func createOptimizedClient(network: Network, apiKey: String?) throws -> Koios {
        let sessionConfig = URLSessionConfiguration.default
        
        // Optimize for connection reuse
        sessionConfig.httpMaximumConnectionsPerHost = 8
        sessionConfig.httpShouldSetCookies = false
        sessionConfig.httpCookieAcceptPolicy = .never
        sessionConfig.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: nil
        )
        
        let urlSession = URLSession(configuration: sessionConfig)
        let transport = URLSessionTransport(session: urlSession)
        
        var middlewares: [ClientMiddleware] = []
        
        if let apiKey = apiKey {
            middlewares.append(AuthenticationMiddleware(authorizationHeaderFieldValue: apiKey))
        }
        
        let serverURL = try network.url()
        let client = Client(
            serverURL: serverURL,
            transport: transport,
            middlewares: middlewares
        )
        
        return Koios(client: client, network: network, apiKey: apiKey)
    }
}
```

## See Also

- <doc:Authentication> - Configure API key authentication
- <doc:NetworkConfiguration> - Choose appropriate networks
- <doc:BestPractices> - Performance and reliability patterns
- <doc:Testing> - Configure clients for testing