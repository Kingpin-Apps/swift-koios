import Testing
import Foundation
import OpenAPIRuntime
import HTTPTypes
@testable import SwiftKoios

@Suite("Koios Tests")
struct KoiosTests {
    let koios = try! Koios(
        network: .mainnet,
        apiKey: "fake-api-key",
        client: Client(
            serverURL: URL(string: "https://api.koios.rest/api/v1")!,
            transport: MockTransport()
        )
    )
    
    @Test("Test tip")
    func tip() async throws {
        let tip = try await koios.client.tip()
        let tipData = try tip.ok.body.json
        
        // Validate we have exactly one tip record
        #expect(tipData.count == 1)
        
        let tipPayload = tipData[0]
        
        // Validate tip data
        #expect(tipPayload.hash == "abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567")
        #expect(tipPayload.epochNo == 300)
        #expect(tipPayload.absSlot == 3653)
        #expect(tipPayload.epochSlot == 153)
        #expect(tipPayload.blockNo == 12345678)
        #expect(tipPayload.blockTime == 1696118400)
        
        print("Tip test passed! Block: \(tipPayload.blockNo ?? 0), Epoch: \(tipPayload.epochNo ?? 0)")
    }
    
    @Test("Test genesis")
    func genesis() async throws {
        let genesis = try await koios.client.genesis()
        let genesisData = try genesis.ok.body.json
        
        // Validate we have exactly one genesis record
        #expect(genesisData.count == 1)
        
        let genesisPayload = genesisData[0]
        
        // Validate key genesis parameters
        #expect(genesisPayload.networkmagic == "764824073")
        #expect(genesisPayload.networkid == "Mainnet")
        #expect(genesisPayload.epochlength == "432000")
        #expect(genesisPayload.slotlength == "1")
        #expect(genesisPayload.maxlovelacesupply == "45000000000000000")
        #expect(genesisPayload.systemstart == 1506203091)
        #expect(genesisPayload.activeslotcoeff == "0.05")
        #expect(genesisPayload.slotsperkesperiod == "129600")
        #expect(genesisPayload.maxkesrevolutions == "62")
        #expect(genesisPayload.securityparam == "2160")
        #expect(genesisPayload.updatequorum == "5")
        
        // Validate Alonzo genesis is present
        #expect(genesisPayload.alonzogenesis != nil)
        #expect(genesisPayload.alonzogenesis!.contains("lovelacePerUTxOWord"))
        
        print("Genesis test passed! Network: \(genesisPayload.networkid ?? "unknown")")
    }
    
    @Test("Test cliProtocolParams")
    func cliProtocolParams() async throws {
        let cliProtocolParams = try await koios.client.cliProtocolParams()
        let protocolParams = try cliProtocolParams.ok.body.json
        
        // Validate key protocol parameters by accessing the value property directly
        #expect(protocolParams.value["collateralPercentage"] as? Int == 150)
        #expect(protocolParams.value["maxTxSize"] as? Int == 16384)
        #expect(protocolParams.value["minFeeRefScriptCostPerByte"] as? Int == 15)
        #expect(protocolParams.value["minPoolCost"] as? Int == 170000000)
        #expect(protocolParams.value["monetaryExpansion"] as? Double == 0.003)
        #expect(protocolParams.value["poolPledgeInfluence"] as? Double == 0.3)
        #expect(protocolParams.value["poolRetireMaxEpoch"] as? Int == 18)
        #expect(protocolParams.value["stakeAddressDeposit"] as? Int == 2000000)
        #expect(protocolParams.value["stakePoolDeposit"] as? Int == 500000000)
        #expect(protocolParams.value["stakePoolTargetNum"] as? Int == 500)
        #expect(protocolParams.value["treasuryCut"] as? Double == 0.2)
        #expect(protocolParams.value["txFeeFixed"] as? Int == 155381)
        #expect(protocolParams.value["txFeePerByte"] as? Int == 44)
        #expect(protocolParams.value["utxoCostPerByte"] as? Int == 4310)
        
        // Validate Conway era parameters
        #expect(protocolParams.value["dRepActivity"] as? Int == 20)
        #expect(protocolParams.value["dRepDeposit"] as? Int == 500000000)
        #expect(protocolParams.value["govActionDeposit"] as? Int == 100000000000)
        #expect(protocolParams.value["govActionLifetime"] as? Int == 6)
        
        // Validate nested objects exist
        let protocolVersionDict = protocolParams.value["protocolVersion"] as? [String: Any]
        #expect(protocolVersionDict != nil)
        #expect(protocolVersionDict!["major"] as? Int == 10)
        #expect(protocolVersionDict!["minor"] as? Int == 0)
        
        let executionPricesDict = protocolParams.value["executionUnitPrices"] as? [String: Any]
        #expect(executionPricesDict != nil)
        #expect(executionPricesDict!["priceMemory"] as? Double == 0.0577)
        #expect(executionPricesDict!["priceSteps"] as? Double == 0.0000721)
        
        print("CLI Protocol Params test passed! Protocol version: \(protocolVersionDict!["major"] as? Int ?? 0).\(protocolVersionDict!["minor"] as? Int ?? 0)")
    }
    
    @Test("Test ogmios EvaluateTx")
    func ogmiosEvaluateTx() async throws {
        let result = try await koios.client.ogmios(
            Operations.Ogmios.Input(
                body: Components.RequestBodies.Ogmios.json(
                    .init(
                        jsonrpc: "2.0",
                        method: .evaluateTransaction,
                        params: .init(unvalidatedValue: [
                            "transaction": [
                                "cbor": "800a0004d81825820aabbccddeeff00112233445566778899aabbccddeeff001122334455667788990120a0"
                            ]
                        ])
                    )
                )
            )
        )
        
        let evaluationResult  = try result.ok.body.json
        
        #expect(evaluationResult.value["jsonrpc"] as! String == "2.0")
        #expect(evaluationResult.value["method"] as! String == "evaluateTransaction")
        
        if let evaluationResults = evaluationResult.value["result"] as? [[String: Any]] {
            
            let ev1 = evaluationResults[0]
            let ev2 = evaluationResults[1]
            
            #expect(ev1["validator"] as! String == "spend:1")
            #expect(ev2["validator"] as! String == "mint:0")
            
            let budget1 = ev1["budget"] as! [String: Int]
            let budget2 = ev2["budget"] as! [String: Int]
            
            #expect(budget1["memory"] == 5236222)
            #expect(budget1["cpu"] == 1212353)
            #expect(budget2["memory"] == 5000)
            #expect(budget2["cpu"] == 42)
        }
    }
    
    @Test("Test assetAddresses")
    func assetAddresses() async throws {
        let response = try await koios.client.assetAddresses(
            Operations.AssetAddresses.Input(
                query: .init(
                    _assetPolicy: "750900e4999ebe0d58f19b634768ba25e525aaf12403bfe8fe130501",
                    _assetName: "424f4f4b",
                )
            )
        )
        
        let assetAddresses = try response.ok.body.json
        
        let first = assetAddresses[0]
        
        #expect(
            first.paymentAddress == "addr1qxkfe8s6m8qt5436lec3f0320hrmpppwqgs2gah4360krvyssntpwjcz303mx3h4avg7p29l3zd8u3jyglmewds9ezrqdc3cxp"
        )
        #expect(
            first.stakeAddress == "stake1u8yxtugdv63wxafy9d00nuz6hjyyp4qnggvc9a3vxh8yl0ckml2uz"
        )
        #expect(first.quantity == "23")
    }
    
    @Test("Test poolInfo")
    func poolInfo() async throws {
        let response = try await koios.client.poolInfo(
            Operations.PoolInfo.Input(
                body: .json(.init(
                    _poolBech32Ids: [
                        "pool155efqn9xpcf73pphkk88cmlkdwx4ulkg606tne970qswczg3asc"
                    ]
                ))
            )
        )
        
        let poolInfos = try response.ok.body.json
        
        guard let first = poolInfos.first else {
            Issue.record("No pool info returned")
            return
        }
        
        #expect(
            first.poolIdBech32 == "pool155efqn9xpcf73pphkk88cmlkdwx4ulkg606tne970qswczg3asc"
        )
        #expect(
            first.poolIdHex == "a532904ca60e13e88437b58e7c6ff66b8d5e7ec8d3f4b9e4be7820ec"
        )
        #expect(first.owners?.isEmpty == false)
    }
}
