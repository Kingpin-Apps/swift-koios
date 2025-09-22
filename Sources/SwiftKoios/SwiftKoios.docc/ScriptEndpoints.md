# Script Endpoints

Query Cardano smart contract scripts, datums, and redeemer information.

## Overview

Script endpoints provide access to Cardano smart contract data including Plutus scripts, native scripts, datum information, and redeemer data. These endpoints are essential for DApp developers, script analyzers, and smart contract auditing tools.

## Script Information

### Get Script Details

Query information about specific scripts by their hash:

```swift
func getScriptInfo(scriptHashes: [String]) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.scriptInfo(
        body: .init(scriptHashes)
    )
    
    let scripts = try response.ok.body.json
    
    for script in scripts {
        print("Script: \(script.scriptHash ?? "unknown")")
        print("- Type: \(script.type ?? "unknown")")
        print("- Serialised Size: \(script.serialisedSize ?? 0)")
        
        if let creationTxHash = script.creationTxHash {
            print("- Creation TX: \(creationTxHash)")
        }
        
        // Show script content based on type
        if script.type == "plutusV1" || script.type == "plutusV2" {
            if let bytes = script.bytes {
                print("- Script Size: \(bytes.count / 2) bytes") // Hex string
            }
        } else if script.type == "timelock" {
            if let json = script.json {
                print("- Timelock JSON: \(json)")
            }
        }
    }
}
```

### List Scripts by Type

Query scripts filtered by type:

```swift
func getScriptsByType(type: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    // Note: This would depend on available filtering options in the API
    let response = try await koios.client.scriptInfo(
        body: .init([]) // This would need proper filtering support
    )
    
    let scripts = try response.ok.body.json
    
    // Filter by type locally for now
    let filteredScripts = scripts.filter { $0.type == type }
    
    print("\(type) Scripts:")
    
    for script in filteredScripts {
        print("- \(script.scriptHash ?? "unknown")")
        print("  Size: \(script.serialisedSize ?? 0) bytes")
        
        if let creationTx = script.creationTxHash {
            print("  Created in: \(creationTx)")
        }
    }
    
    print("Total \(type) scripts: \(filteredScripts.count)")
}
```

## Datum Information

### Get Datum Details

Query datum information by hash:

```swift
func getDatumInfo(datumHashes: [String]) async throws {
    let koios = try Koios(network: .mainnet)
    
    let response = try await koios.client.datumInfo(
        body: .init(datumHashes)
    )
    
    let datums = try response.ok.body.json
    
    for datum in datums {
        print("Datum: \(datum.datumHash ?? "unknown")")
        print("- Creation TX: \(datum.creationTxHash ?? "unknown")")
        
        if let value = datum.value {
            print("- Value: \(value)")
        }
        
        if let bytes = datum.bytes {
            print("- Size: \(bytes.count / 2) bytes") // Hex string length / 2
        }
    }
}
```

### Find Datums by Transaction

Find all datums created in a specific transaction:

```swift
func getDatumsInTransaction(txHash: String) async throws {
    let koios = try Koios(network: .mainnet)
    
    // Get transaction details to find datum hashes
    let txResponse = try await koios.client.txInfo(
        body: .init(.init(txHashes: [txHash]))
    )
    
    let transactions = try txResponse.ok.body.json
    
    guard let transaction = transactions.first else {
        print("Transaction not found: \(txHash)")
        return
    }
    
    // Extract datum hashes from transaction outputs
    var datumHashes: [String] = []
    
    if let outputs = transaction.outputs {
        for output in outputs {
            if let datumHash = output.datumHash {
                datumHashes.append(datumHash)
            }
        }
    }
    
    guard !datumHashes.isEmpty else {
        print("No datums found in transaction: \(txHash)")
        return
    }
    
    // Get datum information
    try await getDatumInfo(datumHashes: datumHashes)
}
```

## Script Analysis

### Script Usage Statistics

Analyze script usage patterns:

```swift
struct ScriptStats {
    let totalScripts: Int
    let plutusV1Count: Int
    let plutusV2Count: Int
    let nativeScriptCount: Int
    let averageSize: Double
    let mostUsedScripts: [(hash: String, usageCount: Int)]
}

class ScriptAnalyzer {
    private let koios: Koios
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    func analyzeScriptUsage(scriptHashes: [String]) async throws -> ScriptStats {
        let response = try await koios.client.scriptInfo(
            body: .init(scriptHashes)
        )
        
        let scripts = try response.ok.body.json
        
        let plutusV1 = scripts.filter { $0.type == "plutusV1" }
        let plutusV2 = scripts.filter { $0.type == "plutusV2" }
        let native = scripts.filter { $0.type == "timelock" }
        
        let totalSize = scripts.reduce(0) { total, script in
            total + (script.serialisedSize ?? 0)
        }
        
        let averageSize = scripts.isEmpty ? 0 : Double(totalSize) / Double(scripts.count)
        
        // For usage count, we'd need additional API calls to count references
        // This is a simplified example
        let mostUsed = scripts.map { script in
            (hash: script.scriptHash ?? "unknown", usageCount: 1)
        }.sorted { $0.usageCount > $1.usageCount }
        
        return ScriptStats(
            totalScripts: scripts.count,
            plutusV1Count: plutusV1.count,
            plutusV2Count: plutusV2.count,
            nativeScriptCount: native.count,
            averageSize: averageSize,
            mostUsedScripts: Array(mostUsed.prefix(10))
        )
    }
    
    func displayScriptStats(_ stats: ScriptStats) {
        print("Script Analysis:")
        print("- Total Scripts: \(stats.totalScripts)")
        print("- Plutus V1: \(stats.plutusV1Count)")
        print("- Plutus V2: \(stats.plutusV2Count)")
        print("- Native Scripts: \(stats.nativeScriptCount)")
        print("- Average Size: \(String(format: "%.1f", stats.averageSize)) bytes")
        
        print("\nMost Used Scripts:")
        for (index, script) in stats.mostUsedScripts.enumerated() {
            print("\(index + 1). \(script.hash) (Used \(script.usageCount) times)")
        }
    }
}
```

## Smart Contract Utilities

### Script Validator

Create utilities for validating and analyzing scripts:

```swift
class ScriptValidator {
    private let koios: Koios
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    func validateScript(scriptHash: String) async throws -> Bool {
        let response = try await koios.client.scriptInfo(
            body: .init([scriptHash])
        )
        
        let scripts = try response.ok.body.json
        
        guard let script = scripts.first else {
            print("Script not found: \(scriptHash)")
            return false
        }
        
        // Basic validation checks
        var isValid = true
        var issues: [String] = []
        
        // Check if script has content
        if script.bytes == nil && script.json == nil {
            issues.append("Script has no content")
            isValid = false
        }
        
        // Check size limits
        if let size = script.serialisedSize, size > 16384 { // 16KB limit example
            issues.append("Script exceeds size limit (\(size) bytes)")
            isValid = false
        }
        
        // Type-specific validation
        switch script.type {
        case "plutusV1", "plutusV2":
            if script.bytes == nil {
                issues.append("Plutus script missing bytecode")
                isValid = false
            }
            
        case "timelock":
            if script.json == nil {
                issues.append("Native script missing JSON definition")
                isValid = false
            }
            
        default:
            issues.append("Unknown script type: \(script.type ?? "nil")")
            isValid = false
        }
        
        // Report validation results
        if isValid {
            print("✅ Script \(scriptHash) is valid")
        } else {
            print("❌ Script \(scriptHash) has issues:")
            for issue in issues {
                print("  - \(issue)")
            }
        }
        
        return isValid
    }
}
```

### Datum Parser

Create utilities for parsing and analyzing datums:

```swift
class DatumParser {
    private let koios: Koios
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    func analyzeDatum(datumHash: String) async throws {
        let response = try await koios.client.datumInfo(
            body: .init([datumHash])
        )
        
        let datums = try response.ok.body.json
        
        guard let datum = datums.first else {
            print("Datum not found: \(datumHash)")
            return
        }
        
        print("Datum Analysis for \(datumHash):")
        print("- Creation TX: \(datum.creationTxHash ?? "unknown")")
        
        if let bytes = datum.bytes {
            print("- Raw Size: \(bytes.count / 2) bytes")
            print("- Raw Data: \(bytes)")
        }
        
        if let value = datum.value {
            print("- Parsed Value: \(value)")
            
            // Try to determine datum structure
            analyzeDatumStructure(value)
        }
    }
    
    private func analyzeDatumStructure(_ value: String) {
        // This is a simplified example - real implementation would
        // need proper CBOR/Plutus data parsing
        
        if value.contains("constructor") {
            print("- Type: Constructor-based datum")
        } else if value.contains("list") {
            print("- Type: List-based datum")
        } else if value.contains("map") {
            print("- Type: Map-based datum")
        } else {
            print("- Type: Simple value datum")
        }
        
        // Estimate complexity
        let complexity = value.count / 100 // Rough estimate
        print("- Complexity: \(complexity > 10 ? "High" : complexity > 5 ? "Medium" : "Low")")
    }
}
```

## Script Monitoring

### Smart Contract Activity Monitor

Monitor smart contract activity:

```swift
class ContractMonitor: ObservableObject {
    @Published var recentScripts: [ScriptInfoResponse] = []
    @Published var recentDatums: [DatumInfoResponse] = []
    @Published var isMonitoring = false
    
    private let koios: Koios
    private var monitorTask: Task<Void, Never>?
    private var knownScripts: Set<String> = []
    private var knownDatums: Set<String> = []
    
    init(network: Network = .mainnet) throws {
        self.koios = try Koios(network: network)
    }
    
    func startMonitoring(interval: TimeInterval = 30) {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        monitorTask = Task { [weak self] in
            while !Task.isCancelled && self?.isMonitoring == true {
                await self?.checkForNewContracts()
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitorTask?.cancel()
        monitorTask = nil
    }
    
    @MainActor
    private func checkForNewContracts() async {
        // This would need to be implemented based on available endpoints
        // to discover new scripts and datums
        
        // For now, this is a conceptual implementation
        print("Checking for new smart contract activity...")
    }
}
```

## See Also

- <doc:TransactionEndpoints> - Query transactions containing scripts
- <doc:AddressEndpoints> - Query script addresses and UTxOs
- <doc:NetworkEndpoints> - Access network information for script context
- <doc:ErrorHandling> - Handle script query errors