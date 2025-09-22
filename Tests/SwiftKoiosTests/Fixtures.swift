import Testing
import OpenAPIRuntime
import Foundation
import HTTPTypes
@testable import SwiftKoios

struct MockTransport: ClientTransport {
    func send(_ request: HTTPTypes.HTTPRequest, body: OpenAPIRuntime.HTTPBody?, baseURL: URL, operationID: String) async throws -> (
        HTTPTypes.HTTPResponse,
        OpenAPIRuntime.HTTPBody?
    ) {
        print("MockTransport sending request for operationID: \(operationID)")
        switch operationID {
            case "tip":
                let tip = Components.Schemas.Tip([
                    Components.Schemas.TipPayload(
                        hash: "abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567",
                        epochNo: 300,
                        absSlot: 3653,
                        epochSlot: 153,
                        blockNo: 12345678,
                        blockTime: 1696118400,
                    )
                ])
                
                let data = try JSONEncoder().encode(tip)
                return (
                    HTTPResponse(
                        status: .ok,
                        headerFields: [.contentType: "application/json"]
                    ),
                    .init(data)
                )
                
            case "genesis":
                let genesis = Components.Schemas.Genesis([
                    Components.Schemas.GenesisPayload(
                        networkmagic: "764824073",
                        networkid: "Mainnet",
                        epochlength: "432000",
                        slotlength: "1",
                        maxlovelacesupply: "45000000000000000",
                        systemstart: 1506203091,
                        activeslotcoeff: "0.05",
                        slotsperkesperiod: "129600",
                        maxkesrevolutions: "62",
                        securityparam: "2160",
                        updatequorum: "5",
                        alonzogenesis: "{\"lovelacePerUTxOWord\":34482,\"executionPrices\":{\"prSteps\":{\"numerator\":721,\"denominator\":10000000},\"prMem\":{\"numerator\":577,\"denominator\":10000}},\"maxTxExUnits\":{\"exUnitsMem\":10000000,\"exUnitsSteps\":10000000000},\"maxBlockExUnits\":{\"exUnitsMem\":50000000,\"exUnitsSteps\":40000000000},\"maxValueSize\":5000,\"collateralPercentage\":150,\"maxCollateralInputs\":3}"
                    )
                ])
                
                let data = try JSONEncoder().encode(genesis)
                return (
                    HTTPResponse(
                        status: .ok,
                        headerFields: [.contentType: "application/json"]
                    ),
                    .init(data)
                )
                
            case "cli_protocol_params":
                // CLI Protocol Params returns a raw JSON object (OpenAPIObjectContainer)
                let mockCliParams = [
                    "collateralPercentage": 150,
                    "maxTxSize": 16384,
                    "minFeeRefScriptCostPerByte": 15,
                    "minPoolCost": 170000000,
                    "monetaryExpansion": 0.003,
                    "poolPledgeInfluence": 0.3,
                    "poolRetireMaxEpoch": 18,
                    "stakeAddressDeposit": 2000000,
                    "stakePoolDeposit": 500000000,
                    "stakePoolTargetNum": 500,
                    "treasuryCut": 0.2,
                    "txFeeFixed": 155381,
                    "txFeePerByte": 44,
                    "utxoCostPerByte": 4310,
                    "maxBlockBodySize": 90112,
                    "maxBlockHeaderSize": 1100,
                    "maxCollateralInputs": 3,
                    "maxValueSize": 5000,
                    "dRepActivity": 20,
                    "dRepDeposit": 500000000,
                    "govActionDeposit": 100000000000,
                    "govActionLifetime": 6,
                    "protocolVersion": [
                        "major": 10,
                        "minor": 0
                    ],
                    "executionUnitPrices": [
                        "priceMemory": 0.0577,
                        "priceSteps": 0.0000721
                    ],
                    "maxTxExecutionUnits": [
                        "memory": 14000000,
                        "steps": 10000000000
                    ],
                    "maxBlockExecutionUnits": [
                        "memory": 62000000,
                        "steps": 20000000000
                    ]
                ] as [String: Any]
                
                let data = try JSONSerialization.data(withJSONObject: mockCliParams)
                return (
                    HTTPResponse(
                        status: .ok,
                        headerFields: [.contentType: "application/json"]
                    ),
                    .init(data)
                )
                
            default:
                return (
                    HTTPResponse(status: .notFound),
                    nil
                )
        }
    }
}
