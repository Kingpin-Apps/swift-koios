# Error Handling

Learn how to handle errors gracefully in SwiftKoios applications with comprehensive error handling patterns, retry strategies, and debugging techniques.

## Overview

SwiftKoios provides robust error handling for various failure scenarios that can occur when interacting with the Koios API. Understanding these error types and implementing proper error handling is crucial for building reliable Cardano applications.

## Error Types

### KoiosError

SwiftKoios defines specific error types for library-related issues:

```swift
public enum KoiosError: Error, CustomStringConvertible, Equatable {
    case invalidBasePath(String?)
    case missingAPIKey(String?)
    case valueError(String?)
    
    var description: String {
        switch self {
        case .invalidBasePath(let message):
            return message ?? "Invalid base path."
        case .missingAPIKey(let message):
            return message ?? "The API Key is missing."
        case .valueError(let message):
            return message ?? "The value is invalid."
        }
    }
}
```

#### KoiosError Cases

- **`invalidBasePath`**: Thrown when the provided base path URL is invalid or malformed
- **`missingAPIKey`**: Thrown when an API key is required but not provided or found
- **`valueError`**: Thrown when input parameters are invalid or don't meet requirements

### Network and Transport Errors

SwiftKoios uses Apple's OpenAPI transport layer, which can throw various network-related errors:

#### URLError Types

```swift
// Network connectivity issues
URLError.notConnectedToInternet
URLError.timedOut
URLError.cannotConnectToHost
URLError.networkConnectionLost

// DNS and server resolution
URLError.cannotFindHost
URLError.dnsLookupFailed

// HTTP response errors
URLError.badServerResponse
URLError.cannotParseResponse
```

#### HTTP Status Errors

The Koios API returns standard HTTP status codes:

- **400 Bad Request**: Invalid request parameters
- **401 Unauthorized**: Invalid or missing API key
- **403 Forbidden**: Access denied or rate limit exceeded
- **404 Not Found**: Endpoint or resource not found
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Server-side error
- **502 Bad Gateway**: Proxy or gateway error
- **503 Service Unavailable**: Server temporarily unavailable
- **504 Gateway Timeout**: Request timeout

### OpenAPI Response Errors

OpenAPI client generates typed responses, and accessing the wrong response type throws errors:

```swift
// This will throw if the response is not successful
let tipInfo = try response.ok.body.json

// Handle different response types
switch response {
case .ok(let success):
    let data = try success.body.json
case .badRequest(let error):
    // Handle 400 error
    break
case .unauthorized(let error):
    // Handle 401 error  
    break
case .undocumented(statusCode: let code, _):
    // Handle other status codes
    break
}
```

## Basic Error Handling

### Simple Try-Catch Pattern

```swift
import SwiftKoios

class CardanoService {
    private let koios: Koios
    
    init() throws {
        self.koios = try Koios(network: .mainnet)
    }
    
    func getChainTip() async throws -> ChainTipInfo {
        do {
            let response = try await koios.client.tip()
            return try response.ok.body.json
        } catch let error as KoiosError {
            // Handle SwiftKoios specific errors
            throw CardanoServiceError.koiosError(error)
        } catch let urlError as URLError {
            // Handle network errors
            throw CardanoServiceError.networkError(urlError)
        } catch {
            // Handle other errors
            throw CardanoServiceError.unknownError(error)
        }
    }
}

enum CardanoServiceError: Error {
    case koiosError(KoiosError)
    case networkError(URLError)
    case unknownError(Error)
}
```

### Result-Based Error Handling

For non-throwing APIs, use Result types:

```swift
class CardanoService {
    private let koios: Koios
    
    init() throws {
        self.koios = try Koios(network: .mainnet)
    }
    
    func getChainTip() async -> Result<ChainTipInfo, CardanoServiceError> {
        do {
            let response = try await koios.client.tip()
            let tipInfo = try response.ok.body.json
            return .success(tipInfo)
        } catch let error as KoiosError {
            return .failure(.koiosError(error))
        } catch let urlError as URLError {
            return .failure(.networkError(urlError))
        } catch {
            return .failure(.unknownError(error))
        }
    }
}

// Usage
let result = await cardanoService.getChainTip()
switch result {
case .success(let tipInfo):
    print("Current block height: \(tipInfo.blockHeight)")
case .failure(let error):
    handleError(error)
}
```

## Advanced Error Handling

### Custom Error Types

Create domain-specific error types for better error management:

```swift
enum CardanoError: Error, LocalizedError {
    case configurationError(KoiosError)
    case networkUnavailable
    case apiRateLimitExceeded
    case invalidAddress(String)
    case transactionNotFound(String)
    case insufficientFunds
    case serverError(Int, String?)
    
    var errorDescription: String? {
        switch self {
        case .configurationError(let koiosError):
            return "Configuration error: \(koiosError.description)"
        case .networkUnavailable:
            return "Network is currently unavailable"
        case .apiRateLimitExceeded:
            return "API rate limit exceeded. Please try again later."
        case .invalidAddress(let address):
            return "Invalid address: \(address)"
        case .transactionNotFound(let txHash):
            return "Transaction not found: \(txHash)"
        case .insufficientFunds:
            return "Insufficient funds for transaction"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .configurationError:
            return "Check your API key and network configuration"
        case .networkUnavailable:
            return "Check your internet connection and try again"
        case .apiRateLimitExceeded:
            return "Wait a moment before making more requests"
        case .invalidAddress:
            return "Verify the address format and try again"
        case .transactionNotFound:
            return "Verify the transaction hash and try again"
        case .insufficientFunds:
            return "Add more funds to your wallet"
        case .serverError:
            return "Try again later or contact support if the issue persists"
        }
    }
}
```

### Error Mapping

Map low-level errors to domain errors:

```swift
extension CardanoService {
    private func mapError(_ error: Error) -> CardanoError {
        if let koiosError = error as? KoiosError {
            return .configurationError(koiosError)
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .timedOut:
                return .serverError(408, "Request timeout")
            default:
                return .serverError(0, urlError.localizedDescription)
            }
        }
        
        // Handle OpenAPI response errors
        if let responseError = error as? OpenAPIError {
            switch responseError {
            case .transport(let transportError):
                return mapError(transportError)
            default:
                return .serverError(0, responseError.localizedDescription)
            }
        }
        
        return .serverError(0, error.localizedDescription)
    }
}
```

## Retry Strategies

### Basic Retry Logic

Implement retry logic for transient failures:

```swift
class RetryableCardanoService {
    private let koios: Koios
    private let maxRetries: Int
    private let retryDelay: TimeInterval
    
    init(maxRetries: Int = 3, retryDelay: TimeInterval = 1.0) throws {
        self.koios = try Koios(network: .mainnet)
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }
    
    func getChainTipWithRetry() async throws -> ChainTipInfo {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                let response = try await koios.client.tip()
                return try response.ok.body.json
            } catch {
                lastError = error
                
                // Don't retry for certain error types
                if shouldNotRetry(error) {
                    throw error
                }
                
                if attempt < maxRetries {
                    let delay = retryDelay * pow(2.0, Double(attempt - 1)) // Exponential backoff
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? CardanoError.serverError(0, "Max retries exceeded")
    }
    
    private func shouldNotRetry(_ error: Error) -> Bool {
        if let koiosError = error as? KoiosError {
            // Don't retry configuration errors
            return true
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .badURL, .unsupportedURL:
                return true // Don't retry malformed URLs
            default:
                return false
            }
        }
        
        // Add logic for HTTP status codes
        // Don't retry 4xx client errors (except 429)
        return false
    }
}
```

### Advanced Retry with Circuit Breaker

Implement a circuit breaker pattern for better resilience:

```swift
actor CircuitBreaker {
    enum State {
        case closed
        case open
        case halfOpen
    }
    
    private var state: State = .closed
    private var failureCount = 0
    private var lastFailureTime: Date?
    private let failureThreshold: Int
    private let recoveryTimeout: TimeInterval
    
    init(failureThreshold: Int = 5, recoveryTimeout: TimeInterval = 30.0) {
        self.failureThreshold = failureThreshold
        self.recoveryTimeout = recoveryTimeout
    }
    
    func execute<T>(_ operation: () async throws -> T) async throws -> T {
        switch state {
        case .open:
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > recoveryTimeout {
                state = .halfOpen
                return try await attemptOperation(operation)
            } else {
                throw CardanoError.serverError(503, "Circuit breaker is open")
            }
            
        case .halfOpen:
            return try await attemptOperation(operation)
            
        case .closed:
            return try await attemptOperation(operation)
        }
    }
    
    private func attemptOperation<T>(_ operation: () async throws -> T) async throws -> T {
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
        
        if failureCount >= failureThreshold {
            state = .open
        }
    }
}

// Usage with circuit breaker
class ResilientCardanoService {
    private let koios: Koios
    private let circuitBreaker = CircuitBreaker()
    
    init() throws {
        self.koios = try Koios(network: .mainnet)
    }
    
    func getChainTip() async throws -> ChainTipInfo {
        return try await circuitBreaker.execute {
            let response = try await koios.client.tip()
            return try response.ok.body.json
        }
    }
}
```

## Debugging and Logging

### Comprehensive Logging

Add detailed logging for debugging:

```swift
import OSLog

class LoggingCardanoService {
    private let koios: Koios
    private let logger = Logger(subsystem: "com.yourapp.cardano", category: "api")
    
    init() throws {
        self.koios = try Koios(network: .mainnet)
    }
    
    func getTransactionInfo(txHash: String) async throws -> TransactionInfo {
        logger.info("Fetching transaction info for: \(txHash)")
        
        do {
            let response = try await koios.client.tx_info(.init(
                body: .json([txHash])
            ))
            
            let transactions = try response.ok.body.json
            logger.info("Successfully fetched transaction info")
            
            guard let transaction = transactions.first else {
                logger.warning("Transaction not found: \(txHash)")
                throw CardanoError.transactionNotFound(txHash)
            }
            
            return transaction
            
        } catch let error as KoiosError {
            logger.error("Koios error: \(error.description)")
            throw CardanoError.configurationError(error)
            
        } catch let urlError as URLError {
            logger.error("Network error: \(urlError.localizedDescription)")
            throw CardanoError.networkUnavailable
            
        } catch {
            logger.error("Unexpected error: \(error.localizedDescription)")
            throw CardanoError.serverError(0, error.localizedDescription)
        }
    }
}
```

### Error Context and User Data

Add context to errors for better debugging:

```swift
struct ErrorContext {
    let timestamp: Date
    let endpoint: String
    let parameters: [String: Any]?
    let userID: String?
    let sessionID: String?
    
    init(endpoint: String, parameters: [String: Any]? = nil, userID: String? = nil) {
        self.timestamp = Date()
        self.endpoint = endpoint
        self.parameters = parameters
        self.userID = userID
        self.sessionID = UUID().uuidString
    }
}

enum ContextualError: Error {
    case cardanoError(CardanoError, ErrorContext)
    
    var localizedDescription: String {
        switch self {
        case .cardanoError(let cardanoError, let context):
            return """
            Error: \(cardanoError.localizedDescription ?? "Unknown error")
            Endpoint: \(context.endpoint)
            Timestamp: \(context.timestamp)
            Session: \(context.sessionID ?? "N/A")
            """
        }
    }
}

extension CardanoService {
    func getAccountInfoWithContext(stakeAddress: String, userID: String? = nil) async throws -> AccountInfo {
        let context = ErrorContext(
            endpoint: "account_info",
            parameters: ["stake_address": stakeAddress],
            userID: userID
        )
        
        do {
            let response = try await koios.client.account_info(.init(
                body: .json([stakeAddress])
            ))
            let accounts = try response.ok.body.json
            
            guard let account = accounts.first else {
                throw ContextualError.cardanoError(.invalidAddress(stakeAddress), context)
            }
            
            return account
            
        } catch let cardanoError as CardanoError {
            throw ContextualError.cardanoError(cardanoError, context)
        } catch {
            let mappedError = mapError(error)
            throw ContextualError.cardanoError(mappedError, context)
        }
    }
}
```

## UI Error Handling

### SwiftUI Error Handling

Handle errors gracefully in SwiftUI:

```swift
import SwiftUI

struct AccountView: View {
    @StateObject private var viewModel = AccountViewModel()
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let stakeAddress: String
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading account info...")
            } else if let account = viewModel.account {
                AccountDetailView(account: account)
            } else {
                Text("No account data available")
            }
        }
        .task {
            await loadAccountInfo()
        }
        .alert("Error", isPresented: $showingError) {
            Button("Retry") {
                Task { await loadAccountInfo() }
            }
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadAccountInfo() async {
        do {
            try await viewModel.loadAccount(stakeAddress: stakeAddress)
        } catch let contextualError as ContextualError {
            await MainActor.run {
                errorMessage = contextualError.localizedDescription
                showingError = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

@MainActor
class AccountViewModel: ObservableObject {
    @Published var account: AccountInfo?
    @Published var isLoading = false
    
    private let cardanoService: CardanoService
    
    init() {
        self.cardanoService = try! CardanoService()
    }
    
    func loadAccount(stakeAddress: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        account = try await cardanoService.getAccountInfoWithContext(stakeAddress: stakeAddress)
    }
}
```

### Error Recovery Strategies

Implement automatic recovery for common scenarios:

```swift
class RecoverableCardanoService {
    private let koios: Koios
    private var apiKeyRefreshCount = 0
    
    init() throws {
        self.koios = try Koios(network: .mainnet)
    }
    
    func getChainTipWithRecovery() async throws -> ChainTipInfo {
        do {
            return try await performRequest()
        } catch let error as CardanoError {
            switch error {
            case .apiRateLimitExceeded:
                // Wait and retry
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                return try await performRequest()
                
            case .configurationError(let koiosError) where koiosError == .missingAPIKey(""):
                // Attempt to refresh API key
                if apiKeyRefreshCount < 3 {
                    apiKeyRefreshCount += 1
                    try await refreshAPIKey()
                    return try await performRequest()
                }
                throw error
                
            case .networkUnavailable:
                // Check connectivity and retry
                if await NetworkMonitor.shared.isConnected {
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    return try await performRequest()
                }
                throw error
                
            default:
                throw error
            }
        }
    }
    
    private func performRequest() async throws -> ChainTipInfo {
        let response = try await koios.client.tip()
        return try response.ok.body.json
    }
    
    private func refreshAPIKey() async throws {
        // Implement API key refresh logic
        // This could involve refreshing OAuth tokens, etc.
    }
}
```

## Testing Error Scenarios

### Mock Error Responses

Create mocks for testing error conditions:

```swift
import XCTest
@testable import SwiftKoios

class MockCardanoService: CardanoService {
    var shouldThrowError = false
    var errorToThrow: Error?
    
    override func getChainTip() async throws -> ChainTipInfo {
        if shouldThrowError {
            throw errorToThrow ?? CardanoError.networkUnavailable
        }
        return ChainTipInfo(/* mock data */)
    }
}

class CardanoServiceTests: XCTestCase {
    func testNetworkErrorHandling() async throws {
        let mockService = MockCardanoService()
        mockService.shouldThrowError = true
        mockService.errorToThrow = CardanoError.networkUnavailable
        
        do {
            _ = try await mockService.getChainTip()
            XCTFail("Expected error to be thrown")
        } catch let error as CardanoError {
            XCTAssertEqual(error, .networkUnavailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testRetryLogic() async throws {
        let service = RetryableCardanoService(maxRetries: 3, retryDelay: 0.1)
        
        // Test successful retry after failure
        // Implementation depends on your mocking strategy
    }
}
```

## Best Practices

### Error Handling Guidelines

1. **Be Specific**: Use specific error types rather than generic errors
2. **Provide Context**: Include relevant information with errors
3. **Handle Gracefully**: Don't crash the app; provide recovery options
4. **Log Appropriately**: Log errors for debugging but don't expose sensitive data
5. **User-Friendly Messages**: Convert technical errors to user-friendly messages

### Error Classification

Classify errors by their handling strategy:

```swift
protocol ErrorClassifiable {
    var isRetryable: Bool { get }
    var requiresUserAction: Bool { get }
    var shouldLog: Bool { get }
}

extension CardanoError: ErrorClassifiable {
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .serverError(let code, _) where code >= 500:
            return true
        case .apiRateLimitExceeded:
            return true
        default:
            return false
        }
    }
    
    var requiresUserAction: Bool {
        switch self {
        case .invalidAddress, .insufficientFunds:
            return true
        case .configurationError:
            return true
        default:
            return false
        }
    }
    
    var shouldLog: Bool {
        // Log all errors except rate limiting (too noisy)
        switch self {
        case .apiRateLimitExceeded:
            return false
        default:
            return true
        }
    }
}
```

## Related Documentation

- <doc:Getting-Started> - Basic setup and configuration
- <doc:Client-Configuration> - Advanced client configuration
- <doc:Testing> - Testing strategies including error scenarios
- <doc:API-Reference> - Complete API reference

## Support

If you encounter persistent errors:
- Check the [Koios API status](https://status.koios.rest)
- Review the [Koios documentation](https://koios.rest) 
- Report issues on the project repository
- Join the community discussions for help