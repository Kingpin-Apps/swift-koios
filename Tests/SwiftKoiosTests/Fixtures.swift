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
            case "ogmios":
                let ogmiosResponse = [
                    "jsonrpc": "2.0",
                    "method": "evaluateTransaction",
                    "result": [
                        [
                            "validator": "spend:1",
                            "budget": [
                                "memory": 5236222,
                                "cpu": 1212353
                            ],
                        ],
                        [
                            "validator": "mint:0",
                            "budget": [
                                "memory": 5000,
                                "cpu": 42
                            ]
                        ]
                    ]
                ] as [String: Any]
                
                let data = try JSONSerialization.data(withJSONObject: ogmiosResponse)
                return (
                    HTTPResponse(
                        status: .ok,
                        headerFields: [.contentType: "application/json"]
                    ),
                    .init(data)
                )
            case "asset_addresses":
                let assetAddresses = [
                    "payment_address": "addr1qxkfe8s6m8qt5436lec3f0320hrmpppwqgs2gah4360krvyssntpwjcz303mx3h4avg7p29l3zd8u3jyglmewds9ezrqdc3cxp",
                    "stake_address": "stake1u8yxtugdv63wxafy9d00nuz6hjyyp4qnggvc9a3vxh8yl0ckml2uz",
                    "quantity": "23"
                ] as [String: Any]
                
                let data = try JSONSerialization.data(withJSONObject: [assetAddresses])
                return (
                    HTTPResponse(
                        status: .ok,
                        headerFields: [.contentType: "application/json"]
                    ),
                    .init(data)
                )
            case "pool_info":
                let poolInfos = [
                    [
                        "pool_id_bech32": "pool155efqn9xpcf73pphkk88cmlkdwx4ulkg606tne970qswczg3asc",
                        "pool_id_hex": "a532904ca60e13e88437b58e7c6ff66b8d5e7ec8d3f4b9e4be7820ec",
                        "active_epoch_no": 0,
                        "vrf_key_hash": "string",
                        "margin": 0,
                        "fixed_cost": "string",
                        "pledge": "string",
                        "deposit": "string",
                        "reward_addr": "string",
                        "reward_addr_delegated_drep": "string",
                        "owners": [
                            "stake1u8088wvudd7dp3rxl0v9xgng8r3j50s65ge3l3jvgd94keqfm3nv3"
                        ],
                        "relays": [
                            [
                                "dns": "string",
                                "srv": "string",
                                "ipv4": "string",
                                "ipv6": "string",
                                "port": 0
                            ]
                        ],
                        "meta_url": "string",
                        "meta_hash": "string",
                        "meta_json": [
                            "name": "Input Output Global (IOHK) - Private",
                            "ticker": "IOGP",
                            "homepage": "https://iohk.io",
                            "description": "Our mission is to provide economic identity to the billions of people who lack it. IOHK will not use the IOHK ticker."
                        ],
                        "pool_status": "registered",
                        "retiring_epoch": 0,
                        "op_cert": "string",
                        "op_cert_counter": 0,
                        "active_stake": "string",
                        "sigma": 0,
                        "block_count": 0,
                        "live_pledge": "string",
                        "live_stake": "string",
                        "live_delegators": 5,
                        "live_saturation": 0,
                        "voting_power": "string"
                    ]
                ] as [[String: Any]]
                
                let data = try JSONSerialization.data(withJSONObject: poolInfos)
                return (
                    HTTPResponse(
                        status: .ok,
                        headerFields: [.contentType: "application/json"]
                    ),
                    .init(data)
                )
            case "pool_list":
                let poolList = [
                    [
                        "pool_id_bech32": "pool155efqn9xpcf73pphkk88cmlkdwx4ulkg606tne970qswczg3asc",
                    ],
                    [
                        "pool_id_bech32": "pool1uq8l234306m76unyz8kuwnkvmtvazaks6vuvyx3a3khngavvcw0",
                    ],
                    [
                        "pool_id_bech32": "pool1ru2zh42397d6dyxdzslw5p6z4cewj38npl7prpjskv7fyl0gpga",
                    ],
                    [
                        "pool_id_bech32": "pool1ddgcpgjcyawxw95se9x8qnc8gxgwjr4fqrk4vk6v9x47s0ggpjp",
                    ],
                    [
                        "pool_id_bech32": "pool1rshru8pm6y0jy7jncmt6qzfs8u4f5qa5gvyh38kgec767t20z3d",
                    ],
                ] as [[String: Any]]
                
                let data = try JSONSerialization.data(withJSONObject: poolList)
                return (
                    HTTPResponse(
                        status: .ok,
                        headerFields: [.contentType: "application/json"]
                    ),
                    .init(data)
                )
            case "drep_info":
                let drepInfo = [
                    [
                        "drep_id": "drep1kqhhkv66a0egfw7uyz7u8dv7fcvr4ck0c3ad9k9urx3yzhefup0",
                        "hex": "b02f7b335aebf284bbdc20bdc3b59e4e183ae2cfc47ad2d8bc19a241",
                        "has_script": false,
                        "drep_status": "registered",
                        "deposit": "500000000",
                        "active": true,
                        "expires_epoch_no": 639,
                        "amount": "500000000",
                        "meta_url": "https://anchor.test",
                        "meta_hash": "35aeb21ba4be07cf9fda041b635f107ef978238b3fccae9be1b571518ce9d1b7"
                    ],
                ]
                
                let data = try JSONSerialization.data(withJSONObject: drepInfo)
                return (
                    HTTPResponse(
                        status: .ok,
                        headerFields: [.contentType: "application/json"]
                    ),
                    .init(data)
                )
                
            case "account_info":
                let accountInfo =
                [
                    [
                        "stake_address": "stake_test1upyz3gk6mw5he20apnwfn96cn9rscgvmmsxc9r86dh0k66gswf59n",
                        "status": "registered",
                        "delegated_pool": "pool1pu5jlj4q9w9jlxeu370a3c9myx47md5j5m2str0naunn2q3lkdy",
                        "delegated_drep": "drep15cfxz9exyn5rx0807zvxfrvslrjqfchrd4d47kv9e0f46uedqtc",
                        "total_balance": "619154618165",
                        "utxo": "300000000000",
                        "rewards": "319154618165",
                        "withdrawals": "12125369253",
                        "rewards_available": "319154618165"
                    ]
                ]
                
                let data = try JSONSerialization.data(withJSONObject: accountInfo)
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
