# Testing

Test your SwiftKoios integrations with mock data, unit tests, and integration patterns.

## Overview

Effective testing is crucial for applications using SwiftKoios. This guide covers testing strategies including mock implementations, unit testing patterns, and integration testing approaches to ensure your Cardano blockchain integrations work reliably.

## Mock Transport

### Creating Mock Responses

Implement a mock transport for testing without real API calls:

```swift
#if DEBUG
import Foundation
import HTTPTypes
import OpenAPIRuntime

class MockKoiosTransport: HTTPClientTransport {
    private var mockResponses: [String: (statusCode: HTTPResponse.Status, data: Data)] = [:]
    private var requestLog: [(method: HTTPRequest.Method, path: String)] = []
    
    // MARK: - Mock Data Setup
    
    func setMockResponse(for endpoint: String, statusCode: HTTPResponse.Status = .ok, data: Data) {
        mockResponses[endpoint] = (statusCode: statusCode, data: data)
    }
    
    func setMockResponse<T: Codable>(for endpoint: String, statusCode: HTTPResponse.Status = .ok, object: T) {
        do {
            let data = try JSONEncoder().encode(object)
            setMockResponse(for: endpoint, statusCode: statusCode, data: data)
        } catch {
            print("Failed to encode mock object: \(error)")
        }
    }
    
    // MARK: - Transport Implementation
    
    func send(_ request: HTTPRequest, body: HTTPBody?) async throws -> (HTTPResponse, HTTPBody?) {
        // Log the request for verification
        requestLog.append((method: request.method, path: request.path ?? ""))
        
        // Extract endpoint from path
        let endpoint = extractEndpoint(from: request.path ?? "")
        
        guard let mockResponse = mockResponses[endpoint] else {
            throw MockTransportError.noMockResponse(endpoint: endpoint)
        }
        
        let httpResponse = HTTPResponse(
            status: mockResponse.statusCode,
            headerFields: [
                .contentType: "application/json",
                .contentLength: "\(mockResponse.data.count)"
            ]
        )
        
        let responseBody = HTTPBody(mockResponse.data)
        
        return (httpResponse, responseBody)
    }
    
    // MARK: - Helper Methods
    
    private func extractEndpoint(from path: String) -> String {
        // Extract the last component of the path as the endpoint identifier
        return path.components(separatedBy: "/").last ?? path
    }
    
    func getRequestLog() -> [(method: HTTPRequest.Method, path: String)] {
        return requestLog
    }
    
    func clearRequestLog() {
        requestLog.removeAll()
    }
}

enum MockTransportError: Error, LocalizedError {
    case noMockResponse(endpoint: String)
    
    var errorDescription: String? {
        switch self {
        case .noMockResponse(let endpoint):
            return "No mock response configured for endpoint: \(endpoint)"
        }
    }
}
#endif
```

### Sample Mock Data

Create realistic mock data for testing:

```swift
#if DEBUG
extension MockKoiosTransport {
    static func withSampleData() -> MockKoiosTransport {
        let transport = MockKoiosTransport()
        
        // Mock tip response
        let tipResponse = [
            TipResponse(
                hash: "abc123def456789",
                epochNo: 450,
                absSlot: 12345678,
                epochSlot: 123456,
                blockNo: 9876543,
                blockTime: 1692123456
            )
        ]
        transport.setMockResponse(for: "tip", object: tipResponse)
        
        // Mock genesis response
        let genesisResponse = [
            GenesisResponse(
                networkid: "Mainnet",
                networkmagic: 764824073,
                epochlength: 432000,
                slotlength: 1000,
                maxlovelacesupply: "45000000000000000",
                systemstart: "2017-09-23T21:44:51Z",
                minfeeA: 44,
                minfeeB: 155381
            )
        ]
        transport.setMockResponse(for: "genesis", object: genesisResponse)
        
        // Mock address info response
        let addressResponse = [
            AddressInfoResponse(
                address: "addr1qx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwq2ytjqp",
                balance: "1000000000",
                stakeAddress: "stake1u9ylzsgxaa6xctf4juup682ar3juj85n8tx3hthnljg47zctvm3rc",
                scriptAddress: false,
                utxoSet: [
                    UTxOInfo(
                        txHash: "def789abc123456",
                        txIndex: 0,
                        value: "1000000000",
                        blockHeight: 9876543,
                        blockTime: 1692123456,
                        assetList: []
                    )
                ]
            )
        ]
        transport.setMockResponse(for: "address_info", object: addressResponse)
        
        return transport
    }
}
#endif
```

## Unit Testing

### Testing Koios Client

Create unit tests for Koios client functionality:

```swift
import XCTest
@testable import SwiftKoios

#if DEBUG
final class KoiosClientTests: XCTestCase {
    var koios: Koios!
    var mockTransport: MockKoiosTransport!
    
    override func setUp() {
        super.setUp()
        mockTransport = MockKoiosTransport.withSampleData()
        
        let mockClient = Client(
            serverURL: URL(string: "https://api.koios.rest/api/v1")!,
            transport: mockTransport
        )
        
        koios = Koios(client: mockClient, network: .mainnet, apiKey: nil)
    }
    
    override func tearDown() {
        koios = nil
        mockTransport = nil
        super.tearDown()
    }
    
    // MARK: - Network Endpoint Tests
    
    func testGetTip() async throws {
        // Given: Mock transport is configured with tip data
        
        // When: We request the current tip
        let response = try await koios.client.tip()
        let tipData = try response.ok.body.json
        
        // Then: We should get the expected data
        XCTAssertEqual(tipData.count, 1)
        XCTAssertEqual(tipData[0].hash, "abc123def456789")
        XCTAssertEqual(tipData[0].epochNo, 450)
        XCTAssertEqual(tipData[0].blockNo, 9876543)
    }
    
    func testGetGenesis() async throws {
        // Given: Mock transport is configured with genesis data
        
        // When: We request genesis information
        let response = try await koios.client.genesis()
        let genesisData = try response.ok.body.json
        
        // Then: We should get the expected genesis parameters
        XCTAssertEqual(genesisData.count, 1)
        XCTAssertEqual(genesisData[0].networkid, "Mainnet")
        XCTAssertEqual(genesisData[0].networkmagic, 764824073)
    }
    
    func testGetAddressInfo() async throws {
        // Given: Mock transport is configured with address data
        let testAddress = "addr1qx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwq2ytjqp"
        
        // When: We request address information
        let response = try await koios.client.addressInfo(
            body: .init([.init(testAddress)])
        )
        let addressData = try response.ok.body.json
        
        // Then: We should get the expected address information
        XCTAssertEqual(addressData.count, 1)
        XCTAssertEqual(addressData[0].address, testAddress)
        XCTAssertEqual(addressData[0].balance, "1000000000")
        XCTAssertEqual(addressData[0].utxoSet?.count, 1)
    }
}

// MARK: - Error Handling Tests

extension KoiosClientTests {
    func testErrorHandling() async throws {
        // Given: Mock transport with error response
        mockTransport.setMockResponse(
            for: "tip",
            statusCode: .internalServerError,
            data: Data()
        )
        
        // When/Then: Request should throw an error
        do {
            _ = try await koios.client.tip()
            XCTFail("Should have thrown an error")
        } catch {
            // Error was thrown as expected
            XCTAssertNotNil(error)
        }
    }
    
    func testRequestLogging() async throws {
        // Given: Clean request log
        mockTransport.clearRequestLog()
        
        // When: We make multiple requests
        _ = try await koios.client.tip()
        _ = try await koios.client.genesis()
        
        // Then: Requests should be logged
        let requests = mockTransport.getRequestLog()
        XCTAssertEqual(requests.count, 2)
        XCTAssertTrue(requests[0].path.contains("tip"))
        XCTAssertTrue(requests[1].path.contains("genesis"))
    }
}
#endif
```

### Testing Utilities and Helpers

Test custom utilities built on top of SwiftKoios:

```swift
import XCTest
@testable import SwiftKoios

final class KoiosUtilitiesTests: XCTestCase {
    
    func testAddressValidation() {
        // Test valid addresses
        let validAddresses = [
            "addr1qx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwq2ytjqp",
            "addr_test1qz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwqcz8sxx"
        ]
        
        for address in validAddresses {
            XCTAssertNoThrow(try validateCardanoAddress(address))
        }
        
        // Test invalid addresses
        let invalidAddresses = [
            "",
            "invalid",
            "addr1_too_short",
            "not_an_address_at_all"
        ]
        
        for address in invalidAddresses {
            XCTAssertThrowsError(try validateCardanoAddress(address))
        }
    }
    
    func testLovelaceConversion() {
        // Test conversion from lovelace to ADA
        XCTAssertEqual(lovelaceToADA("1000000"), 1.0)
        XCTAssertEqual(lovelaceToADA("1500000"), 1.5)
        XCTAssertEqual(lovelaceToADA("0"), 0.0)
        
        // Test conversion from ADA to lovelace
        XCTAssertEqual(adaToLovelace(1.0), "1000000")
        XCTAssertEqual(adaToLovelace(1.5), "1500000")
        XCTAssertEqual(adaToLovelace(0.0), "0")
    }
}

// Helper functions for testing
func validateCardanoAddress(_ address: String) throws {
    guard !address.isEmpty else {
        throw KoiosError.valueError("Address cannot be empty")
    }
    
    guard address.count >= 50 && address.count <= 120 else {
        throw KoiosError.valueError("Invalid address length")
    }
    
    let validPrefixes = ["addr", "addr_test", "stake", "stake_test"]
    guard validPrefixes.contains(where: address.hasPrefix) else {
        throw KoiosError.valueError("Invalid address format")
    }
}

func lovelaceToADA(_ lovelace: String) -> Double {
    return (Double(lovelace) ?? 0) / 1_000_000
}

func adaToLovelace(_ ada: Double) -> String {
    return String(Int(ada * 1_000_000))
}
```

## Integration Testing

### Testing Against Real API

Create integration tests that can run against the actual Koios API:

```swift
import XCTest
@testable import SwiftKoios

final class KoiosIntegrationTests: XCTestCase {
    var koios: Koios!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Use preview network for integration tests
        koios = try Koios(network: .preview)
        
        // Skip tests if no network connectivity
        try await verifyNetworkConnectivity()
    }
    
    private func verifyNetworkConnectivity() async throws {
        do {
            _ = try await koios.client.tip()
        } catch {
            throw XCTSkip("No network connectivity to Koios API")
        }
    }
    
    func testRealNetworkEndpoints() async throws {
        // Test tip endpoint
        let tipResponse = try await koios.client.tip()
        let tipData = try tipResponse.ok.body.json
        
        XCTAssertFalse(tipData.isEmpty, "Tip data should not be empty")
        XCTAssertNotNil(tipData[0].hash, "Block hash should not be nil")
        XCTAssertNotNil(tipData[0].epochNo, "Epoch number should not be nil")
        
        // Test genesis endpoint
        let genesisResponse = try await koios.client.genesis()
        let genesisData = try genesisResponse.ok.body.json
        
        XCTAssertFalse(genesisData.isEmpty, "Genesis data should not be empty")
        XCTAssertEqual(genesisData[0].networkid, "Preview", "Should be preview network")
    }
    
    func testRateLimiting() async throws {
        let startTime = Date()
        
        // Make multiple rapid requests
        for _ in 0..<5 {
            _ = try await koios.client.tip()
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Should complete within reasonable time (not be heavily rate limited)
        XCTAssertLessThan(duration, 10.0, "Requests should complete within 10 seconds")
    }
}
```

### Performance Testing

Test the performance characteristics of your Koios integration:

```swift
final class KoiosPerformanceTests: XCTestCase {
    
    func testTipRequestPerformance() async throws {
        let koios = try Koios(network: .preview)
        
        measure {
            let expectation = XCTestExpectation(description: "Tip request")
            
            Task {
                do {
                    _ = try await koios.client.tip()
                    expectation.fulfill()
                } catch {
                    XCTFail("Request failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testBatchAddressRequests() async throws {
        let koios = try Koios(network: .preview)
        
        // Test with increasing batch sizes
        let batchSizes = [1, 5, 10, 20]
        let testAddresses = Array(repeating: "addr_test1qz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwqcz8sxx", count: 20)
        
        for batchSize in batchSizes {
            let addresses = Array(testAddresses.prefix(batchSize))
            
            let startTime = Date()
            
            do {
                _ = try await koios.client.addressInfo(
                    body: .init(addresses.map { .init($0) })
                )
                
                let duration = Date().timeIntervalSince(startTime)
                print("Batch size \(batchSize): \(duration)s")
                
                // Larger batches should be more efficient per item
                XCTAssertLessThan(duration, Double(batchSize) * 0.5, "Batch should be efficient")
                
            } catch {
                print("Batch size \(batchSize) failed: \(error)")
            }
        }
    }
}
```

## Test Utilities

### Mock Data Builders

Create builders for consistent test data:

```swift
struct MockDataBuilder {
    static func tipResponse(
        hash: String = "abc123",
        epochNo: Int = 450,
        blockNo: Int = 9876543
    ) -> [TipResponse] {
        return [
            TipResponse(
                hash: hash,
                epochNo: epochNo,
                absSlot: 12345678,
                epochSlot: 123456,
                blockNo: blockNo,
                blockTime: 1692123456
            )
        ]
    }
    
    static func addressInfoResponse(
        address: String = "addr1test123",
        balance: String = "1000000000"
    ) -> [AddressInfoResponse] {
        return [
            AddressInfoResponse(
                address: address,
                balance: balance,
                stakeAddress: "stake1test456",
                scriptAddress: false,
                utxoSet: []
            )
        ]
    }
}
```

### Test Configuration

Manage test configurations and environments:

```swift
enum TestConfiguration {
    static let defaultTimeout: TimeInterval = 5.0
    static let integrationTestsEnabled = ProcessInfo.processInfo.environment["INTEGRATION_TESTS"] == "1"
    static let testNetwork: Network = .preview
    
    static func skipIfIntegrationTestsDisabled() throws {
        guard integrationTestsEnabled else {
            throw XCTSkip("Integration tests disabled. Set INTEGRATION_TESTS=1 to enable.")
        }
    }
}
```

## See Also

- <doc:BestPractices> - Testing strategies and patterns
- <doc:ErrorHandling> - Test error scenarios thoroughly
- <doc:Authentication> - Test authentication flows and error cases
- <doc:NetworkConfiguration> - Test different network configurations