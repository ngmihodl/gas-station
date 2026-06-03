// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {TKGasDelegate} from "../src/TKGasStation/TKGasDelegate.sol";
import {TKGasStation} from "../src/TKGasStation/TKGasStation.sol";

interface IImmutableCreate2Factory {
    function safeCreate2(bytes32 _salt, bytes calldata _initCode) external payable returns (address _deploymentAddress);
}

/// @notice One-shot: CREATE2 `TKGasDelegate` with `GAS_STATION = address(0)`, then CREATE2 `TKGasStation` bound to that
/// delegate with `owner = address(0)` (ownerless). Because the station has no owner, the delegate is wired in at
/// construction (it can never be changed afterwards via `setDelegate`). Both are deployed via the
/// `ImmutableCreate2Factory`.
/// @custom:security-contact security@turnkey.com
contract DeployTKGasDelegateAndStationNoOwner is Script {
    address private constant IMMUTABLE_CREATE2_FACTORY = 0x0000000000FFe8B47B3e2130213B802212439497;

    bytes32 private constant SALT = 0x0000000000000000000000000000000000000000000000000000004761737379;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        IImmutableCreate2Factory factory = IImmutableCreate2Factory(IMMUTABLE_CREATE2_FACTORY);

        // 1. Delegate first, with the gas station immutable set to address(0).
        bytes memory delegateInit = abi.encodePacked(type(TKGasDelegate).creationCode, abi.encode(address(0)));
        address delegate = factory.safeCreate2(SALT, delegateInit);

        // 2. Gas station, ownerless (owner = address(0)) with the delegate set at construction.
        bytes memory stationInit = abi.encodePacked(type(TKGasStation).creationCode, abi.encode(delegate, address(0)));
        address station = factory.safeCreate2(SALT, stationInit);

        vm.stopBroadcast();

        console2.log("TKGasDelegate deployed at:", delegate);
        console2.log("TKGasDelegate GAS_STATION (immutable):", address(0));
        console2.log("TKGasStation deployed at:", station);
        console2.log("TKGasStation owner:", address(0));
        console2.log("TKGasStation tkGasDelegate:", delegate);
    }
}
