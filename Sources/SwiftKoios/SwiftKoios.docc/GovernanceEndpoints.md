# Governance Endpoints

Query Cardano Conway era governance information including DReps, proposals, and committee data.

## Overview

Governance endpoints provide access to Conway era governance features including Delegated Representatives (DReps), governance proposals, constitutional committee information, and voting data. These endpoints are essential for governance applications and voting interfaces.

## DRep Information

### Get DRep List

Query all registered Delegated Representatives:

```swift
func getDRepList() async throws {
    let koios = try Koios(network: .sancho) // Conway features on Sanchonet
    
    let response = try await koios.client.drepList()
    let dreps = try response.ok.body.json
    
    print("Total DReps: \(dreps.count)")
    
    for drep in dreps.prefix(10) {
        print("DRep: \(drep.drepId ?? "unknown")")
        print("- Hex: \(drep.hex ?? "unknown")")
        print("- Has Script: \(drep.hasScript ?? false)")
        print("- Active: \(drep.active ?? false)")
    }
}
```

### Get DRep Details

Query detailed information about specific DReps:

```swift
func getDRepInfo(drepIds: [String]) async throws {
    let koios = try Koios(network: .sancho)
    
    let response = try await koios.client.drepInfo(
        body: .init(drepIds)
    )
    
    let drepDetails = try response.ok.body.json
    
    for drep in drepDetails {
        print("DRep: \(drep.drepId ?? "unknown")")
        print("- Deposit: \(drep.deposit ?? "0") lovelace")
        print("- Active: \(drep.active ?? false)")
        print("- Active Epoch: \(drep.activeEpoch ?? 0)")
        print("- Amount: \(drep.amount ?? "0")")
        
        if let url = drep.url {
            print("- URL: \(url)")
        }
        
        if let dataHash = drep.dataHash {
            print("- Data Hash: \(dataHash)")
        }
    }
}
```

## Governance Proposals

### Get Proposal List

Retrieve all governance proposals:

```swift
func getProposalList() async throws {
    let koios = try Koios(network: .sancho)
    
    let response = try await koios.client.proposalList()
    let proposals = try response.ok.body.json
    
    print("Total proposals: \(proposals.count)")
    
    for proposal in proposals.prefix(10) {
        print("Proposal: \(proposal.txHash ?? "unknown")#\(proposal.certIndex ?? 0)")
        print("- Block Height: \(proposal.blockHeight ?? 0)")
        print("- Block Time: \(proposal.blockTime ?? 0)")
        print("- Deposit: \(proposal.deposit ?? "0") lovelace")
        print("- Return Address: \(proposal.returnAddress ?? "unknown")")
        
        if let proposedIn = proposal.proposedIn {
            print("- Proposed in Epoch: \(proposedIn)")
        }
        
        if let expiresAfter = proposal.expiresAfter {
            print("- Expires after Epoch: \(expiresAfter)")
        }
    }
}
```

### Get Proposal Details

Query detailed information about specific proposals:

```swift
func getProposalDetails(proposalId: String) async throws {
    let koios = try Koios(network: .sancho)
    
    // Parse proposal ID (format: txHash#certIndex)
    let components = proposalId.split(separator: "#")
    guard components.count == 2,
          let txHash = components.first,
          let certIndex = Int(components.last!) else {
        throw KoiosError.valueError("Invalid proposal ID format")
    }
    
    let response = try await koios.client.proposalList()
    let proposals = try response.ok.body.json
    
    // Find the specific proposal
    let proposal = proposals.first { p in
        p.txHash == String(txHash) && p.certIndex == certIndex
    }
    
    guard let foundProposal = proposal else {
        print("Proposal not found: \(proposalId)")
        return
    }
    
    print("Proposal Details:")
    print("- TX Hash: \(foundProposal.txHash ?? "unknown")")
    print("- Cert Index: \(foundProposal.certIndex ?? 0)")
    print("- Type: \(foundProposal.type ?? "unknown")")
    print("- Description: \(foundProposal.description ?? "N/A")")
    print("- Deposit: \(foundProposal.deposit ?? "0") lovelace")
    print("- Return Address: \(foundProposal.returnAddress ?? "unknown")")
    
    // Show voting information if available
    if let meta = foundProposal.meta {
        print("- Metadata: \(meta)")
    }
}
```

## Constitutional Committee

### Get Committee Information

Query constitutional committee details:

```swift
func getCommitteeInfo() async throws {
    let koios = try Koios(network: .sancho)
    
    let response = try await koios.client.committeeInfo()
    let committees = try response.ok.body.json
    
    for committee in committees {
        print("Committee Member:")
        print("- Hash: \(committee.hash ?? "unknown")")
        print("- Has Script: \(committee.hasScript ?? false)")
        print("- Active Epoch: \(committee.activeEpoch ?? 0)")
        print("- Expired Epoch: \(committee.expiredEpoch ?? 0)")
        
        if let status = committee.status {
            print("- Status: \(status)")
        }
    }
}
```

## Voting Data

### Track Voting Activity

Monitor voting activity for proposals:

```swift
struct VotingStats {
    let totalVotes: Int
    let yesVotes: Int
    let noVotes: Int
    let abstainVotes: Int
    let participationRate: Double
}

func getVotingStats(proposalId: String) async throws -> VotingStats? {
    let koios = try Koios(network: .sancho)
    
    // This is a conceptual example - actual implementation would depend
    // on the specific voting endpoints available in the Koios API
    
    // For now, return mock data to show the pattern
    return VotingStats(
        totalVotes: 150,
        yesVotes: 85,
        noVotes: 45,
        abstainVotes: 20,
        participationRate: 0.67
    )
}

func displayVotingStats(for proposalId: String) async throws {
    guard let stats = try await getVotingStats(proposalId: proposalId) else {
        print("No voting data available for proposal: \(proposalId)")
        return
    }
    
    print("Voting Statistics for \(proposalId):")
    print("- Total Votes: \(stats.totalVotes)")
    print("- Yes: \(stats.yesVotes) (\(String(format: "%.1f", Double(stats.yesVotes) / Double(stats.totalVotes) * 100))%)")
    print("- No: \(stats.noVotes) (\(String(format: "%.1f", Double(stats.noVotes) / Double(stats.totalVotes) * 100))%)")
    print("- Abstain: \(stats.abstainVotes) (\(String(format: "%.1f", Double(stats.abstainVotes) / Double(stats.totalVotes) * 100))%)")
    print("- Participation Rate: \(String(format: "%.1f", stats.participationRate * 100))%")
}
```

## Governance Analytics

### DRep Analysis

Analyze DRep activity and participation:

```swift
class GovernanceAnalyzer {
    private let koios: Koios
    
    init(network: Network = .sancho) throws {
        self.koios = try Koios(network: network)
    }
    
    func analyzeDRepActivity() async throws {
        let response = try await koios.client.drepList()
        let dreps = try response.ok.body.json
        
        let activeDReps = dreps.filter { $0.active ?? false }
        let inactiveDReps = dreps.filter { !($0.active ?? true) }
        
        print("DRep Activity Analysis:")
        print("- Total DReps: \(dreps.count)")
        print("- Active DReps: \(activeDReps.count)")
        print("- Inactive DReps: \(inactiveDReps.count)")
        print("- Activity Rate: \(String(format: "%.1f", Double(activeDReps.count) / Double(dreps.count) * 100))%")
    }
    
    func analyzeProposalActivity() async throws {
        let response = try await koios.client.proposalList()
        let proposals = try response.ok.body.json
        
        // Group proposals by type
        let proposalsByType = Dictionary(grouping: proposals) { $0.type ?? "unknown" }
        
        print("Proposal Analysis:")
        print("- Total Proposals: \(proposals.count)")
        
        for (type, typeProposals) in proposalsByType {
            print("- \(type): \(typeProposals.count)")
        }
        
        // Analyze proposal timeline
        let sortedProposals = proposals.sorted { lhs, rhs in
            (lhs.blockTime ?? 0) < (rhs.blockTime ?? 0)
        }
        
        if let earliest = sortedProposals.first?.blockTime,
           let latest = sortedProposals.last?.blockTime {
            let timespan = latest - earliest
            print("- Timespan: \(timespan) seconds")
            
            if timespan > 0 {
                let rate = Double(proposals.count) / (Double(timespan) / (24 * 3600))
                print("- Average Proposals per Day: \(String(format: "%.2f", rate))")
            }
        }
    }
}
```

## Governance Monitoring

### Real-time Governance Monitor

Monitor governance activity in real-time:

```swift
class GovernanceMonitor: ObservableObject {
    @Published var latestProposals: [ProposalListResponse] = []
    @Published var activeDReps: [DrepListResponse] = []
    @Published var isMonitoring = false
    
    private let koios: Koios
    private var monitorTask: Task<Void, Never>?
    
    init(network: Network = .sancho) throws {
        self.koios = try Koios(network: network)
    }
    
    func startMonitoring(interval: TimeInterval = 60) {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        monitorTask = Task { [weak self] in
            while !Task.isCancelled && self?.isMonitoring == true {
                await self?.updateGovernanceData()
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
    private func updateGovernanceData() async {
        do {
            // Update proposals
            let proposalsResponse = try await koios.client.proposalList()
            let proposals = try proposalsResponse.ok.body.json
            latestProposals = Array(proposals.prefix(10))
            
            // Update DReps
            let drepsResponse = try await koios.client.drepList()
            let dreps = try drepsResponse.ok.body.json
            activeDReps = dreps.filter { $0.active ?? false }
            
        } catch {
            print("Error updating governance data: \(error)")
        }
    }
}
```

## See Also

- <doc:NetworkEndpoints> - Query epoch information for governance context
- <doc:TransactionEndpoints> - Track governance-related transactions
- <doc:AddressEndpoints> - Query stake addresses involved in governance
- <doc:ErrorHandling> - Handle governance query errors