# Installation

Add SwiftKoios to your project using Swift Package Manager.

## Overview

SwiftKoios is distributed as a Swift Package Manager library, making it easy to integrate into iOS, macOS, watchOS, and tvOS projects.

## Requirements

- **iOS 14.0+** / **macOS 13.0+** / **watchOS 7.0+** / **tvOS 14.0+**
- **Swift 6.2+**
- **Xcode 15.0+**

## Swift Package Manager

### In Xcode

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies...**
3. In the search bar, enter: `https://github.com/Kingpin-Apps/swift-koios`
4. Select the version range (we recommend "Up to Next Major" starting from `1.0.0`)
5. Click **Add Package**
6. Select the **SwiftKoios** target for your app

### In Package.swift

Add SwiftKoios as a dependency in your `Package.swift` file:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "YourProject",
    platforms: [
        .iOS(.v14),
        .macOS(.v13),
        .watchOS(.v7),
        .tvOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/Kingpin-Apps/swift-koios", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: [
                .product(name: "SwiftKoios", package: "swift-koios")
            ]
        )
    ]
)
```

## Verification

After installation, verify SwiftKoios is working by adding this to your code:

```swift
import SwiftKoios

// This should compile without errors
let koios = try Koios(network: .mainnet)
```

## Dependencies

SwiftKoios automatically includes these dependencies:

- **OpenAPIRuntime** - Swift OpenAPI runtime support
- **OpenAPIURLSession** - URLSession transport for OpenAPI
- **OpenAPIGenerator** - Code generation from OpenAPI specs

No additional setup is required for these dependencies.

## See Also

- <doc:GettingStarted> - Next steps after installation
- <doc:NetworkConfiguration> - Configure your network settings