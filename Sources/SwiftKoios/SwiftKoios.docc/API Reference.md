# API Reference

The SwiftKoios API provides comprehensive access to Cardano blockchain data through the Koios REST API. This reference guide organizes all available endpoints by category, making it easy to find the functionality you need.

## Overview

SwiftKoios uses OpenAPI-generated client code to provide type-safe access to all Koios endpoints. Each API call returns strongly-typed Swift models that represent the blockchain data.

## Getting Started

First, create a Koios client instance:

```swift
// For mainnet
let koios = try Koios(network: .mainnet)

// For testnet with API key
let koios = try Koios(
    network: .preprod,
    apiKey: "your-api-key-here"
)

// Using environment variable for API key
let koios = try Koios(
    network: .mainnet,
    environmentVariable: "KOIOS_API_KEY"
)
```

## API Categories

### Network Endpoints

Query information about the Cardano network state and parameters.

- ``tip`` - Get the tip info about the latest block seen by chain
- ``genesis`` - Get the Genesis parameters used to start specific era on chain  
- ``totals`` - Get the circulating utxo, treasury, rewards, supply and reserves in lovelace for specified epoch
- ``param_updates`` - Get all parameter update proposals submitted to the chain starting Shelley era
- ``cli_protocol_params`` - Get the current protocol parameters for epoch
- ``reserve_withdrawals`` - Get all reserve withdrawals
- ``treasury_withdrawals`` - Get all treasury withdrawals

#### Example Usage

```swift
// Get chain tip
let response = try await koios.client.tip()
let tipInfo = try response.ok.body.json

// Get genesis parameters
let genesisResponse = try await koios.client.genesis()
let genesisInfo = try genesisResponse.ok.body.json
```

### Epoch Endpoints

Access epoch-specific information and parameters.

- ``epoch_info`` - Get the epoch information, all epochs if no epoch specified
- ``epoch_params`` - Get the protocol parameters for specific epoch
- ``epoch_block_protocols`` - Get the information about block protocol distribution in epoch

#### Example Usage

```swift
// Get current epoch info
let epochResponse = try await koios.client.epoch_info()
let epochInfo = try epochResponse.ok.body.json

// Get specific epoch parameters
let paramsResponse = try await koios.client.epoch_params(.init(
    query: .init(_epoch_no: 250)
))
let epochParams = try paramsResponse.ok.body.json
```

### Block Endpoints

Query information about blocks and their transactions.

- ``blocks`` - Get summarised details about all blocks (paginated - latest first)
- ``block_info`` - Get detailed information about a specific block
- ``block_txs`` - Get a list of all transactions hashes that are included in a provided block
- ``block_tx_cbor`` - Get raw transaction(s) in CBOR format for given block hash(es)
- ``block_tx_info`` - Get detailed information about transaction(s) for given block hash(es)

#### Example Usage

```swift
// Get latest blocks
let blocksResponse = try await koios.client.blocks()
let blocks = try blocksResponse.ok.body.json

// Get specific block info
let blockInfoResponse = try await koios.client.block_info(.init(
    body: .json(["block_hash_1", "block_hash_2"])
))
let blockInfo = try blockInfoResponse.ok.body.json
```

### Transaction Endpoints

Access detailed transaction information and utilities.

- ``utxo_info`` - Get UTxO set for requested UTxO references
- ``tx_cbor`` - Get raw transaction(s) in CBOR format for given TxHash(es)
- ``tx_info`` - Get detailed information about transaction(s)
- ``tx_metadata`` - Get metadata information for given transaction(s)
- ``tx_metalabels`` - Get a list of all transaction metalabels
- ``submittx`` - Submit an already serialized transaction to the network
- ``tx_status`` - Get the number of block confirmations for given transaction hash(es)
- ``tx_utxos`` - Get UTxO set (inputs/outputs) of transactions

#### Example Usage

```swift
// Get transaction info
let txResponse = try await koios.client.tx_info(.init(
    body: .json(["tx_hash_1", "tx_hash_2"])
))
let transactions = try txResponse.ok.body.json

// Submit transaction
let submitResponse = try await koios.client.submittx(.init(
    body: .json("cbor_hex_string")
))
let result = try submitResponse.ok.body.json
```

### Address Endpoints

Query address balances, UTxOs, and transaction history.

- ``address_info`` - Get address info - balance, associated stake address and UTxO set
- ``address_utxos`` - Get UTxO set for given addresses
- ``address_outputs`` - Get address outputs for given addresses
- ``credential_utxos`` - Get all UTxOs for given payment credentials
- ``address_txs`` - Get the transaction hash list for given addresses
- ``credential_txs`` - Get the transaction hash list for given payment credentials
- ``address_assets`` - Get the list of all native assets associated with given addresses

#### Example Usage

```swift
// Get address information
let addressResponse = try await koios.client.address_info(.init(
    body: .json(["addr1q9ag5tntq..."])
))
let addressInfo = try addressResponse.ok.body.json

// Get address UTxOs
let utxosResponse = try await koios.client.address_utxos(.init(
    body: .json(["addr1q9ag5tntq..."])
))
let utxos = try utxosResponse.ok.body.json
```

### Stake Account Endpoints

Manage stake accounts, delegations, and reward history.

- ``account_list`` - Get a list of all accounts
- ``account_info`` - Get the account info for given stake addresses
- ``account_info_cached`` - Get the cached account information for given stake addresses
- ``account_utxos`` - Get UTxO details for requested stake addresses
- ``account_txs`` - Get a list of all transactions for a given stake address
- ``account_rewards`` - Get the full rewards history for given stake addresses
- ``account_reward_history`` - Get the reward history for given stake addresses
- ``account_updates`` - Get the account updates for given stake addresses
- ``account_update_history`` - Get the account update history for given stake addresses
- ``account_addresses`` - Get all addresses associated with given stake addresses
- ``account_assets`` - Get the native asset balance for given stake addresses

#### Example Usage

```swift
// Get stake account info
let stakeResponse = try await koios.client.account_info(.init(
    body: .json(["stake1ux3g2c9dx2nhhehyrezyxpkstartcqmu9hk63qgfkccw5rqttygt7"])
))
let stakeInfo = try stakeResponse.ok.body.json

// Get account rewards
let rewardsResponse = try await koios.client.account_rewards(.init(
    body: .json(["stake1ux3g2c9dx2nhhehyrezyxpkstartcqmu9hk63qgfkccw5rqttygt7"])
))
let rewards = try rewardsResponse.ok.body.json
```

### Asset Endpoints

Query native tokens, NFTs, and asset metadata.

- ``asset_list`` - Get the list of all native assets (paginated)
- ``policy_asset_list`` - Get a list of assets for given policy IDs
- ``asset_token_registry`` - Get a list of assets registered via token registry
- ``asset_info`` - Get the information for all assets under the same policy
- ``asset_utxos`` - Get UTxO information for given asset list
- ``asset_history`` - Get the mint/burn history of an asset
- ``asset_addresses`` - Get all addresses holding the specified asset
- ``asset_nft_address`` - Get the address holding specified NFT
- ``policy_asset_addresses`` - Get all addresses holding any asset for given policy
- ``policy_asset_info`` - Get the information for all assets under requested policies
- ``policy_asset_mints`` - Get a list of mint transactions for requested policies
- ``asset_summary`` - Get the summary of an asset
- ``asset_txs`` - Get the list of all asset transaction hashes

#### Example Usage

```swift
// Get asset information
let assetResponse = try await koios.client.asset_info(.init(
    body: .json(["policy_id.asset_name"])
))
let assetInfo = try assetResponse.ok.body.json

// Get all assets for a policy
let policyResponse = try await koios.client.policy_asset_list(.init(
    query: .init(_asset_policy: "policy_id_here")
))
let policyAssets = try policyResponse.ok.body.json
```

### Pool Endpoints

Access stake pool information, delegators, and performance data.

- ``pool_list`` - Get a list of all currently registered stake pools
- ``pool_info`` - Get current pool status and details for specified pool
- ``pool_stake_snapshot`` - Get pool stake, block and reward history for specified epoch
- ``pool_delegators`` - Get a list of current delegators for specified pool
- ``pool_delegators_history`` - Get a list of historical delegators for specified pool and epoch
- ``pool_blocks`` - Get a list of blocks minted by a specified pool
- ``pool_owner_history`` - Get a list of pool ownership changes for specified pool
- ``pool_history`` - Get a list of pool performance history for specified pool
- ``pool_updates`` - Get a list of pool updates for specified pool
- ``pool_registrations`` - Get a list of pool registrations for specified pool
- ``pool_retirements`` - Get a list of pool retirements for specified pool
- ``pool_relays`` - Get a list of relays for all currently registered pools
- ``pool_groups`` - Get a list of pool groups for all currently registered pools
- ``pool_metadata`` - Get a list of pool metadata for specified pool(s)

#### Example Usage

```swift
// Get pool list
let poolsResponse = try await koios.client.pool_list()
let pools = try poolsResponse.ok.body.json

// Get specific pool info
let poolInfoResponse = try await koios.client.pool_info(.init(
    body: .json(["pool1pu5jlj4q9w9jlxeu370a3c9myx47md5j5m2str0naunn2q3lkdy"])
))
let poolInfo = try poolInfoResponse.ok.body.json
```

### Governance Endpoints

Query Conway era governance information including DReps, committees, and proposals.

- ``drep_epoch_summary`` - Get the DRep epoch summary for requested epoch
- ``drep_list`` - Get the list of all active delegated representatives (DReps)  
- ``drep_info`` - Get detailed information about requested delegated representatives
- ``drep_metadata`` - Get metadata information for requested DReps
- ``drep_updates`` - Get a list of updates for requested DReps
- ``drep_voting_power_history`` - Get DRep voting power history for specified DRep ID and epochs
- ``drep_votes`` - Get a list of all votes cast by specified DRep
- ``drep_delegators`` - Get a list of all delegators to specified DRep
- ``committee_info`` - Get current committee information
- ``committee_votes`` - Get a list of all committee votes cast by specified committee member
- ``proposal_list`` - Get a list of all governance proposals
- ``voter_proposal_list`` - Get a list of all governance proposals for specified DRep, SPO or Committee credential
- ``proposal_voting_summary`` - Get a summary of votes cast on specified governance proposal
- ``proposal_votes`` - Get a list of all votes cast on specified governance proposal
- ``vote_list`` - Get a list of all governance votes cast by any governance member

#### Example Usage

```swift
// Get all DReps
let drepsResponse = try await koios.client.drep_list()
let dreps = try drepsResponse.ok.body.json

// Get governance proposals
let proposalsResponse = try await koios.client.proposal_list()
let proposals = try proposalsResponse.ok.body.json

// Get DRep information
let drepInfoResponse = try await koios.client.drep_info(.init(
    body: .json(["drep1abc123..."])
))
let drepInfo = try drepInfoResponse.ok.body.json
```

### Script Endpoints

Query smart contracts, datums, and redeemers.

- ``script_info`` - Get information about native or Plutus scripts
- ``native_script_list`` - Get a list of all native scripts
- ``plutus_script_list`` - Get a list of all Plutus scripts
- ``script_redeemers`` - Get a list of all redeemers for a given script hash
- ``script_utxos`` - Get a list of all UTxOs for a given script hash
- ``datum_info`` - Get information about datums

#### Example Usage

```swift
// Get script information
let scriptResponse = try await koios.client.script_info(.init(
    body: .json(["script_hash_1", "script_hash_2"])
))
let scriptInfo = try scriptResponse.ok.body.json

// Get all Plutus scripts
let plutusResponse = try await koios.client.plutus_script_list()
let plutusScripts = try plutusResponse.ok.body.json
```

### Ogmios Integration

Access Ogmios WebSocket queries through the REST interface.

- ``ogmios`` - Ogmios Call - an RPC-2.0 endpoint that allows calling any ogmios query against the node via the REST API

#### Example Usage

```swift
// Query chain tip via Ogmios
let ogmiosResponse = try await koios.client.ogmios(.init(
    body: .json([
        "method": "queryNetwork/tip",
        "params": [:]
    ])
))
let ogmiosResult = try ogmiosResponse.ok.body.json
```

## Error Handling

All API calls can throw errors. SwiftKoios provides specific error types for different failure scenarios:

```swift
do {
    let response = try await koios.client.tip()
    let tipInfo = try response.ok.body.json
} catch let error as KoiosError {
    switch error {
    case .missingAPIKey(let message):
        print("API key error: \(message)")
    case .invalidBasePath(let message):
        print("Base path error: \(message)")
    }
} catch {
    print("Network or other error: \(error)")
}
```

## Query Parameters and Filtering

Most endpoints support PostgREST-style filtering and pagination parameters:

```swift
// Example with filtering (implementation varies by generated client)
// Note: Specific parameter syntax depends on the generated OpenAPI client
let filteredBlocks = try await koios.client.blocks(/* filtering parameters */)
```

## Best Practices

1. **Use appropriate network**: Choose the correct network (mainnet, preprod, preview) for your use case
2. **Handle errors gracefully**: Always wrap API calls in do-catch blocks
3. **Respect rate limits**: Be mindful of API rate limits, especially on public endpoints
4. **Use bulk queries**: When possible, use bulk endpoints instead of making many individual calls
5. **Cache responses**: Consider caching responses for data that doesn't change frequently

## Performance Tips

- Use pagination for large result sets
- Implement retry logic for transient network errors  
- Consider using the `account_info_cached` endpoint for frequently accessed stake account data
- Batch requests when querying multiple related items

## Related Documentation

- <doc:Getting-Started> - Basic setup and first steps
- <doc:Client-Configuration> - Advanced client configuration options
- <doc:Testing> - Testing strategies and mock data
- <doc:Governance-Endpoints> - Conway era governance detailed guide
- <doc:Script-Endpoints> - Smart contract interaction guide

## Support

For API-specific questions:
- [Koios Documentation](https://koios.rest)  
- [Koios Telegram](https://t.me/CardanoKoios)
- [GitHub Issues](https://github.com/cardano-community/koios-artifacts)

For SwiftKoios library questions:
- Check the repository issues and discussions
- Refer to the test files for usage examples