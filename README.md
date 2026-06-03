TK Gas Station lets a user have all their gas paid for by another party using metatransactions.

## Deployments V1.1 (Ownerless)

A variant where the delegate is deployed first with its `GAS_STATION` set to `address(0)` (accepts any caller), and the gas station is deployed with `owner = address(0)` (no owner) and the delegate set at construction. Because the station has no owner, `setDelegate`/`pause`/`unpause` can never be called.

#### Base Mainnet
- **TKGasStation**: [0xfDAB60F7c5Bdc7b3687C9b0a8C661EC843Caa899](https://basescan.org/address/0xfDAB60F7c5Bdc7b3687C9b0a8C661EC843Caa899)
- **TKGasDelegate**: [0x06FB0Ee53c3D6e22697a3d6C83124E9A64b32a93](https://basescan.org/address/0x06FB0Ee53c3D6e22697a3d6C83124E9A64b32a93)

## Overall Flow
1. The user signs a type 4 transaction to delegate access to TKGasDelegate (EIP-7702). This can be broadcasted by the paymaster
2. The user then signs a metatransaction (EIP-712) to give permissions to the paymaster to initiate a transaction on behalf of the user
3. The paymaster then submits the metatransaction to the TKGasStation
![Transaction Flow Diagram](./flow.png)

## Security Design Decisions
* Contracts are immutable
* There are no re-entry protections by design. Re-entrancy should be guarded by the contracts the user is interacting with (as in a normal EoA)
    - The nonce for execute and batch execute will naturally protect against re-entrancy, but this should not be relied upon 
* Both the delegate and the gas station are not using DRY. This is a purpsoseful design choice to save gas during run time
* Paymasters (and anyone else) can interact with TKGasDelegate through the TKGasStation or directly through the delegate itself
* The gas station has helper external functions for hashing for the type hash. This is just to help for external development and testing, and are not used during execution
* The standard execution metatransactions should limit by nonce, deadline, interacting contract, and arguments
* Batch transactions for standard execution should share one nonce per batch and one signature that includes the whole batch
* There is no limit (other than uint8 max) on batch transaction size. It's the signer and relayer's responsibility to make sure the transaction is not too large or reverts for other reasons.
* All execute will revert if it gets a failure. Anything interacting with the gas station should be able to handle that
* Burning a nonce only burns the current nonce. Ones that are premade will be valid
* Nonces are sequential and can only be used sequentially
* A user can burn their own nonce without a 712
* The gas delegate implements recievers for ERC-721 and ERC-1155
* There is no requirement for the paymaster to interact with the gas station. The paymaster can interact with the delegate directly if they trust that the user is using the right delegate by doing off-chain validation. 
* The delegate does not implement EIP-7821[https://eips.ethereum.org/EIPS/eip-7821] as described since the execute function is _payable_. As a security measure to not drain the paymaster, no execute functions by design are allowed to be payable
* An attack that can be pulled off to reset/modify the nonce is as follows:
    1. A user delegates and uses it as normal. The nonce iterates up
    2. The user then delegates to a contract that changes the nonce or resets it to 0 since that storage slot stays with the user's address, not the delegated contract
    3. The user then delegates back to TKGasDelegate
    4. Since the nonce is reset, old transactions can be replayed.
    This is accepted because we have a deadline transactions and on step 2, if you delegate to a malicious contract the attacker already has control.  

# Reporting A Vulnerability/Bug Bounty

See our documentation[https://docs.turnkey.com/security/reporting-a-vulnerability] about our bug bounty program.


# Deployment

All contracts are deployed with the create2 factory with the zero address as the deployer
Anyone can canonically deploy this to a new network

The deploy scripts have the salt for bot the delegate and the gas station purposefully hardcoded 

The delegate should be deployed before the gas station


1. Install Foundry if you haven't already
Go to https://getfoundry.sh/introduction/installation/ and install if needed 


2. Clone the repo and checkout the version

```
git clone https://github.com/tkhq/gas-station.git

cd gas-station

git checkout v1.0.0

```

3. Add the RPC configuration to the foundry.toml

Fill ```<networkName>``` with your desired network name. I.e. Base

```
[rpc_endpoints]
<networkName> = "<PUBLIC-RPC-URL>

[etherscan]
<networkName> = { key = "${ETHERSCAN_API_KEY}", url = "<NETWORK-ETHERSCAN-URL>" }
```


4. Create an .env file, and add your private key and etherscan API key
Create the file
```
cp ./env.example ./.env
```

In the file add your keys (and contract addresses **after** you deploy — see step 5):

```
PRIVATE_KEY=your_private_key_here

# API Key for contract verification (works for both Base and Ethereum)
ETHERSCAN_API_KEY=your_etherscan_api_key_here

# Filled in order when using the per-step scripts (not needed for the combined script):
# 1) After deploying the gas station — required before `DeployTKGasDelegate`
TK_GAS_STATION=
# 2) After deploying the delegate — required before `SetGasStationDelegate`
TK_GAS_DELEGATE=
```


5. Install, build, and deploy

``` 
cd ./gas-station

forge install

forge build
```

Deploy using **either** the combined script (simplest) **or** the three-step flow.

**Option A — combined script (recommended)**  
Deploys the gas station (CREATE2, owner-scoped salt), the delegate bound to that station, and calls `setDelegate` in one broadcast. Copy the logged lines into `.env` for other tooling.

```
forge script script/DeployTKGasStationAndDelegate.s.sol:DeployTKGasStationAndDelegate --rpc-url <networkName> --broadcast --verify
```

**Option B — combined ownerless script**  
Deploys the delegate first with `GAS_STATION = address(0)`, then the gas station with `owner = address(0)` and the delegate set at construction, in one broadcast. The station is permanently ownerless, so `setDelegate`/`pause`/`unpause` can never be called.

```
forge script script/DeployTKGasDelegateAndStationNoOwner.s.sol:DeployTKGasDelegateAndStationNoOwner --rpc-url <networkName> --broadcast --verify
```

**Option C — manual scripts**  
Order matters: station first, then delegate, then link.

1. Deploy `TKGasStation` with `tkGasDelegate` initially unset (`address(0)`):

```
forge script script/DeployTKGasStation.s.sol:DeployTKGasStation --rpc-url <networkName> --broadcast --verify
```

From the script logs, set **`TK_GAS_STATION`** in `.env` to the deployed station address.

2. Deploy `TKGasDelegate` with its immutable `GAS_STATION` set to that address (`TK_GAS_STATION` must be set in `.env`):

*Note:*  If you set the delegate to have the gas station as the zero address, it will accept from any gas station

```
forge script script/DeployTKGasDelegate.s.sol:DeployTKGasDelegate --rpc-url <networkName> --broadcast --verify
```

Set **`TK_GAS_DELEGATE`** in `.env` to the deployed delegate address.

3. Point the station at the delegate (owner-only; uses both env vars):

```
forge script script/SetGasStationDelegate.s.sol:SetGasStationDelegate --rpc-url <networkName> --broadcast
```

After a successful deploy, record the canonical contract addresses for the chain (e.g. in docs or your ops repo).
