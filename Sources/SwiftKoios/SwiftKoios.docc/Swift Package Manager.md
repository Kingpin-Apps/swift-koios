# Swift Package Manager

Learn how to install, configure, and use SwiftKoios with Swift Package Manager in your projects.

## Overview

SwiftKoios is distributed as a Swift Package, making it easy to integrate into any Swift project that supports the Swift Package Manager. This includes iOS apps, macOS apps, command-line tools, server-side Swift applications, and more.

## Installation

### Adding SwiftKoios to Your Project

#### Xcode Project

1. Open your Xcode project
2. Select your project file in the navigator
3. Choose your app target
4. Click the "Package Dependencies" tab
5. Click the "+" button to add a package dependency
6. Enter the SwiftKoios repository URL:
   ```
   https://github.com/[organization]/swift-koios
   ```
7. Choose your desired version rule (recommend "Up to Next Major Version")
8. Click "Add Package"
9. Select the `SwiftKoios` library and click "Add Package"

#### Package.swift

For Swift Package projects, add SwiftKoios as a dependency in your `Package.swift` file:

```swift
// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MyCardanoApp",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "MyCardanoApp",
            targets: ["MyCardanoApp"]
        ),
        .executable(
            name: "MyCardanoTool",
            targets: ["MyCardanoTool"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/[organization]/swift-koios.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "MyCardanoApp",
            dependencies: [
                .product(name: "SwiftKoios", package: "swift-koios")
            ]
        ),
        .executableTarget(
            name: "MyCardanoTool",
            dependencies: [
                .product(name: "SwiftKoios", package: "swift-koios")
            ]
        ),
        .testTarget(
            name: "MyCardanoAppTests",
            dependencies: ["MyCardanoApp"]
        )
    ]
)
```

## Platform Support

SwiftKoios supports the following platforms:

- **iOS**: 13.0+
- **macOS**: 10.15+
- **tvOS**: 13.0+
- **watchOS**: 6.0+
- **Linux**: Ubuntu 18.04+

### Platform-Specific Considerations

#### iOS and iPadOS
SwiftKoios works seamlessly in iOS applications, including:
- UIKit-based apps
- SwiftUI apps
- Background processing
- Network-dependent features

```swift
import SwiftKoios
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CardanoDataViewModel()
    
    var body: some View {
        VStack {
            Text("Chain Tip: \(viewModel.blockHeight)")
                .onAppear {
                    viewModel.fetchChainTip()
                }
        }
    }
}

class CardanoDataViewModel: ObservableObject {
    @Published var blockHeight: UInt64 = 0
    private let koios = try! Koios(network: .mainnet)
    
    func fetchChainTip() {
        Task {
            do {
                let response = try await koios.client.tip()
                let tipInfo = try response.ok.body.json
                await MainActor.run {
                    // Update UI with tip information
                }
            } catch {
                print("Error fetching tip: \(error)")
            }
        }
    }
}
```

#### macOS
Perfect for desktop applications, menu bar apps, and developer tools:

```swift
import SwiftKoios
import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private let koios = try! Koios(network: .mainnet)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        Task {
            await fetchNetworkStatus()
        }
    }
    
    private func fetchNetworkStatus() async {
        // Implement network status checking
    }
}
```

#### Linux Server
Excellent for server-side applications and backend services:

```swift
import SwiftKoios
import Vapor

func routes(_ app: Application) throws {
    let koios = try Koios(
        network: .mainnet,
        environmentVariable: "KOIOS_API_KEY"
    )
    
    app.get("tip") { req async throws -> Response in
        let response = try await koios.client.tip()
        let tipInfo = try response.ok.body.json
        return Response(status: .ok, body: .init(data: tipInfo))
    }
}
```

## Version Management

### Semantic Versioning

SwiftKoios follows semantic versioning (SemVer):

- **Major versions** (1.0.0 → 2.0.0): Breaking changes that may require code updates
- **Minor versions** (1.0.0 → 1.1.0): New features that are backward compatible  
- **Patch versions** (1.0.0 → 1.0.1): Bug fixes and small improvements

### Recommended Version Rules

#### For Applications
```swift
.package(
    url: "https://github.com/[organization]/swift-koios.git",
    from: "1.0.0"  // Allows minor and patch updates
)
```

#### For Libraries
```swift
.package(
    url: "https://github.com/[organization]/swift-koios.git",
    "1.0.0"..<"2.0.0"  // More restrictive for library dependencies
)
```

#### For Exact Versions
```swift
.package(
    url: "https://github.com/[organization]/swift-koios.git",
    exact: "1.2.3"  // Use when you need a specific version
)
```

## Dependencies

SwiftKoios depends on the following packages, which are automatically managed by Swift Package Manager:

### Core Dependencies

- **[swift-openapi-runtime](https://github.com/apple/swift-openapi-runtime)**: OpenAPI runtime for Swift
- **[swift-openapi-urlsession](https://github.com/apple/swift-openapi-urlsession)**: URLSession transport for OpenAPI

### Build-Time Dependencies

- **[swift-openapi-generator](https://github.com/apple/swift-openapi-generator)**: Generates Swift code from OpenAPI specifications

### Example Resolved Dependencies

Your `Package.resolved` file might look like this:

```json
{
  "pins" : [
    {
      "identity" : "swift-koios",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/[organization]/swift-koios.git",
      "state" : {
        "revision" : "abc123...",
        "version" : "1.0.0"
      }
    },
    {
      "identity" : "swift-openapi-runtime",
      "kind" : "remoteSourceControl", 
      "location" : "https://github.com/apple/swift-openapi-runtime.git",
      "state" : {
        "revision" : "def456...",
        "version" : "1.0.0"
      }
    }
  ],
  "version" : 2
}
```

## Build Configuration

### Standard Configuration

Most projects can use SwiftKoios without additional build configuration:

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "SwiftKoios", package: "swift-koios")
    ]
)
```

### Advanced Configuration

For projects with specific requirements:

```swift
.target(
    name: "MyAdvancedTarget",
    dependencies: [
        .product(name: "SwiftKoios", package: "swift-koios")
    ],
    swiftSettings: [
        .define("DEBUG", .when(configuration: .debug)),
        .define("KOIOS_LOGGING", .when(configuration: .debug))
    ]
)
```

## Development and Testing

### Development Dependencies

For local development and testing:

```swift
dependencies: [
    .package(url: "https://github.com/[organization]/swift-koios.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-testing.git", from: "0.1.0")
],
targets: [
    .testTarget(
        name: "MyAppTests",
        dependencies: [
            "MyApp",
            .product(name: "Testing", package: "swift-testing")
        ]
    )
]
```

### Mock Dependencies for Testing

Create test doubles for network dependencies:

```swift
// TestTarget
.testTarget(
    name: "MyAppTests",
    dependencies: [
        "MyApp",
        .product(name: "SwiftKoios", package: "swift-koios")
    ],
    resources: [
        .copy("MockData/")
    ]
)
```

## Environment Setup

### Development Environment

1. **Xcode**: Version 15.0+ (for iOS/macOS development)
2. **Swift**: Version 5.9+ 
3. **Command Line Tools**: Latest version

```bash
# Verify Swift version
swift --version

# Update command line tools
xcode-select --install
```

### CI/CD Configuration

#### GitHub Actions

```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    - name: Build
      run: swift build
    - name: Run tests
      run: swift test
```

#### Docker for Linux

```dockerfile
FROM swift:5.9-focal

WORKDIR /app
COPY . .

RUN swift build
RUN swift test
```

## Common Issues and Solutions

### Build Issues

#### Missing OpenAPI Dependencies

If you encounter missing OpenAPI dependencies:

```bash
# Clear package cache
swift package reset

# Update dependencies  
swift package update

# Clean build
swift package clean
```

#### Version Conflicts

For dependency resolution conflicts:

```swift
// In Package.swift, specify exact versions if needed
.package(
    url: "https://github.com/apple/swift-openapi-runtime.git",
    exact: "1.0.0"
)
```

### Network Issues

#### API Key Configuration

Set up API keys using environment variables:

```bash
# For development
export KOIOS_API_KEY="your-api-key-here"

# For production (use secure key management)
export KOIOS_API_KEY="$PRODUCTION_KOIOS_KEY"
```

#### Network Configuration

Configure for different environments:

```swift
// Development
let koios = try Koios(
    network: .preview,
    apiKey: ProcessInfo.processInfo.environment["KOIOS_API_KEY"]
)

// Production  
let koios = try Koios(
    network: .mainnet,
    apiKey: ProcessInfo.processInfo.environment["KOIOS_PRODUCTION_KEY"]
)
```

## Performance Optimization

### Build Performance

#### Incremental Builds

Optimize build times in development:

```bash
# Use incremental builds
swift build --enable-code-coverage

# Parallel builds (adjust based on your CPU)
swift build --jobs 4
```

#### Release Builds

For production builds:

```bash
# Optimized release build
swift build -c release

# With size optimization  
swift build -c release -Xswiftc -Osize
```

### Runtime Performance

#### Connection Pooling

Configure URLSession for optimal performance:

```swift
let config = URLSessionConfiguration.default
config.httpMaximumConnectionsPerHost = 10
config.timeoutIntervalForRequest = 30
config.timeoutIntervalForResource = 60

let koios = try Koios(
    network: .mainnet,
    client: Client(
        serverURL: try Network.mainnet.url(),
        transport: URLSessionTransport(configuration: .init(session: URLSession(configuration: config)))
    )
)
```

## Migration Guide

### Updating Between Versions

#### From 1.x to 2.x (Breaking Changes)

```swift
// Old way (1.x)
let koios = KoiosClient(network: .mainnet)

// New way (2.x)
let koios = try Koios(network: .mainnet)
```

#### Minor Version Updates

Minor version updates should be seamless:

```bash
# Update to latest compatible version
swift package update
```

## Best Practices

### Dependency Management

1. **Lock versions for releases**: Use exact versions for production
2. **Regular updates**: Update dependencies regularly for security
3. **Test updates**: Always test dependency updates in a staging environment
4. **Monitor for vulnerabilities**: Keep track of security advisories

### Project Structure

```
MyCardanoApp/
├── Package.swift
├── Sources/
│   ├── MyCardanoApp/
│   │   ├── Models/
│   │   ├── Services/
│   │   │   └── KoiosService.swift
│   │   └── App.swift
│   └── MyCardanoTool/
│       └── main.swift
├── Tests/
│   └── MyCardanoAppTests/
└── README.md
```

### Service Layer Pattern

```swift
protocol CardanoService {
    func getChainTip() async throws -> ChainTip
    func getAccountInfo(stakeAddress: String) async throws -> AccountInfo
}

class KoiosCardanoService: CardanoService {
    private let koios: Koios
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    func getChainTip() async throws -> ChainTip {
        let response = try await koios.client.tip()
        return try response.ok.body.json
    }
}
```

## Related Documentation

- <doc:Getting-Started> - Quick start guide
- <doc:Client-Configuration> - Advanced client setup
- <doc:Testing> - Testing strategies and mocking
- <doc:Error-Handling> - Comprehensive error handling

## Support

For Swift Package Manager specific issues:
- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [Swift Forums - Package Manager](https://forums.swift.org/c/swift-package-manager)
- [Apple Developer Documentation](https://developer.apple.com/documentation/swift_packages)

For SwiftKoios specific issues:
- Check the repository issues
- Review the example projects
- Join community discussions