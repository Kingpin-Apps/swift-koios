# Authentication

Configure API key authentication to access enhanced Koios features and higher rate limits.

## Overview

While Koios provides a free tier without authentication, API keys unlock enhanced features including higher rate limits, priority access, and premium endpoints. SwiftKoios supports multiple authentication methods to securely manage your API credentials.

## API Key Benefits

With a Koios API key, you get:

- **Higher Rate Limits**: Increased requests per minute/hour
- **Priority Access**: Faster response times during high load
- **Premium Endpoints**: Access to additional data endpoints
- **Monitoring**: Request analytics and usage tracking
- **Support**: Enhanced technical support

## Getting an API Key

1. Visit [Koios Website](https://koios.rest/)
2. Sign up for an account
3. Navigate to your dashboard
4. Generate a new API key
5. Copy and securely store your key

## Basic Authentication

### Direct API Key

Pass your API key directly when creating a client:

```swift
let koios = try Koios(
    network: .mainnet,
    apiKey: "your-api-key-here"
)
```

> **⚠️ Security Warning**: Never hardcode API keys in your source code, especially in apps that will be distributed. Use environment variables or secure storage instead.

## Environment Variables

### Using Environment Variables

The recommended approach for development and CI/CD:

```swift
// Read from specific environment variable
let koios = try Koios(
    network: .mainnet,
    environmentVariable: "KOIOS_API_KEY"
)
```

Set your environment variable:

```bash
export KOIOS_API_KEY="your-api-key-here"
```

### Xcode Schemes

Configure environment variables in Xcode:

1. Edit your scheme (Product → Scheme → Edit Scheme...)
2. Select "Run" → "Arguments"
3. Add environment variable: `KOIOS_API_KEY = your-api-key-here`

### Custom Environment Variable Names

Use custom environment variable names for different environments:

```swift
enum Environment {
    case development
    case staging
    case production
    
    var apiKeyEnvironmentVariable: String {
        switch self {
        case .development:
            return "KOIOS_DEV_API_KEY"
        case .staging:
            return "KOIOS_STAGING_API_KEY"
        case .production:
            return "KOIOS_PROD_API_KEY"
        }
    }
}

func createAuthenticatedClient(environment: Environment) throws -> Koios {
    return try Koios(
        network: environment.network,
        environmentVariable: environment.apiKeyEnvironmentVariable
    )
}
```

## Secure Storage

### Keychain Access

For iOS/macOS apps, store API keys in the Keychain:

```swift
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private let service = "com.yourapp.koios"
    
    func store(apiKey: String, account: String) throws {
        let data = apiKey.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Update existing item
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        } else if status != errSecSuccess {
            throw KoiosError.valueError("Failed to store API key in keychain")
        }
    }
    
    func retrieve(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return apiKey
    }
    
    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// Usage
func createSecureKoiosClient(network: Network) throws -> Koios {
    guard let apiKey = try KeychainManager.shared.retrieve(account: "koios-api-key") else {
        // Fallback to non-authenticated client
        return try Koios(network: network)
    }
    
    return try Koios(network: network, apiKey: apiKey)
}
```

### SwiftUI Integration

Create a secure authentication flow in SwiftUI:

```swift
@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var apiKey: String = ""
    
    private let keychainManager = KeychainManager.shared
    
    init() {
        loadStoredAPIKey()
    }
    
    func loadStoredAPIKey() {
        do {
            if let storedKey = try keychainManager.retrieve(account: "koios-api-key") {
                apiKey = storedKey
                isAuthenticated = true
            }
        } catch {
            print("Failed to load stored API key: \\(error)")
        }
    }
    
    func saveAPIKey(_ key: String) {
        do {
            try keychainManager.store(apiKey: key, account: "koios-api-key")
            apiKey = key
            isAuthenticated = true
        } catch {
            print("Failed to save API key: \\(error)")
        }
    }
    
    func clearAPIKey() {
        do {
            try keychainManager.delete(account: "koios-api-key")
            apiKey = ""
            isAuthenticated = false
        } catch {
            print("Failed to clear API key: \\(error)")
        }
    }
    
    func createKoiosClient(network: Network) throws -> Koios {
        if isAuthenticated && !apiKey.isEmpty {
            return try Koios(network: network, apiKey: apiKey)
        } else {
            return try Koios(network: network)
        }
    }
}
```

## Authentication Validation

### Verify API Key

Test your API key before using it in production:

```swift
func validateAPIKey(_ apiKey: String, network: Network) async -> Bool {
    do {
        let koios = try Koios(network: network, apiKey: apiKey)
        let response = try await koios.client.tip()
        let _ = try response.ok.body.json
        return true
    } catch {
        return false
    }
}

// Usage
let isValid = await validateAPIKey("your-api-key", network: .mainnet)
print("API key is \\(isValid ? "valid" : "invalid")")
```

### Rate Limit Monitoring

Monitor your API usage to stay within limits:

```swift
class RateLimitMonitor {
    private var requestCount = 0
    private var resetTime = Date()
    private let maxRequests: Int
    
    init(maxRequests: Int) {
        self.maxRequests = maxRequests
    }
    
    func canMakeRequest() -> Bool {
        let now = Date()
        
        // Reset counter every hour
        if now.timeIntervalSince(resetTime) > 3600 {
            requestCount = 0
            resetTime = now
        }
        
        return requestCount < maxRequests
    }
    
    func recordRequest() {
        requestCount += 1
    }
    
    func remainingRequests() -> Int {
        return max(0, maxRequests - requestCount)
    }
}

// Usage with authenticated client
let rateLimiter = RateLimitMonitor(maxRequests: 1000) // Adjust based on your tier

func makeRateLimitedRequest() async throws {
    guard rateLimiter.canMakeRequest() else {
        throw KoiosError.valueError("Rate limit exceeded")
    }
    
    let koios = try Koios(network: .mainnet, apiKey: "your-api-key")
    let response = try await koios.client.tip()
    
    rateLimiter.recordRequest()
    
    // Process response
    let tipData = try response.ok.body.json
    print("Remaining requests: \\(rateLimiter.remainingRequests())")
}
```

## Best Practices

### Security Guidelines

1. **Never commit API keys** to version control
2. **Use environment variables** for development
3. **Store in Keychain** for production apps
4. **Rotate keys regularly** for security
5. **Use different keys** for different environments

### Key Management

```swift
struct KoiosAuthentication {
    private let apiKey: String?
    private let environment: Environment
    
    init(environment: Environment) throws {
        self.environment = environment
        
        // Try multiple sources in order of preference
        if let envKey = ProcessInfo.processInfo.environment[environment.apiKeyEnvironmentVariable] {
            self.apiKey = envKey
        } else if let keychainKey = try KeychainManager.shared.retrieve(account: "koios-\\(environment)") {
            self.apiKey = keychainKey
        } else {
            self.apiKey = nil
        }
    }
    
    func createClient() throws -> Koios {
        return try Koios(
            network: environment.network,
            apiKey: apiKey
        )
    }
    
    var isAuthenticated: Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
}
```

### Error Handling

Handle authentication-related errors gracefully:

```swift
func handleAuthenticationError(_ error: Error) {
    if case KoiosError.missingAPIKey(let message) = error {
        print("Authentication required: \\(message ?? "No API key provided")")
        // Prompt user to enter API key
    } else {
        print("Other error: \\(error)")
    }
}
```

## See Also

- <doc:NetworkConfiguration> - Configure different networks
- <doc:ErrorHandling> - Handle authentication errors
- <doc:BestPractices> - Security and usage guidelines
- [Koios API Documentation](https://api.koios.rest/)