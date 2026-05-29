// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {TKGasDelegate} from "../src/TKGasStation/TKGasDelegate.sol";
import {TKGasStation} from "../src/TKGasStation/TKGasStation.sol";

interface IImmutableCreate2Factory {
    function safeCreate2(bytes32 _salt, bytes calldata _initCode) external payable returns (address _deploymentAddress);
}

/// @notice One-shot: CREATE2 `TKGasStation` (owner-scoped salt, delegate unset), CREATE2 `TKGasDelegate` bound to that
/// station, then `TKGasStation.setDelegate`. No `TK_GAS_STATION` / `TK_GAS_DELEGATE` env vars required between steps.
/// @custom:security-contact security@turnkey.com
contract DeployTKGasStationAndDelegate is Script {
    address private constant IMMUTABLE_CREATE2_FACTORY = 0x0000000000FFe8B47B3e2130213B802212439497;

    bytes32 private constant DELEGATE_SALT =
        0x0000000000000000000000000000000000000000000000000000004761737379;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerPrivateKey);

        bytes32 stationSalt = bytes32((uint256(uint160(owner)) << 96) | uint256(0x4761737379));

        vm.startBroadcast(deployerPrivateKey);

        bytes memory stationInit = abi.encodePacked(type(TKGasStation).creationCode, abi.encode(address(0), owner));
        IImmutableCreate2Factory factory = IImmutableCreate2Factory(IMMUTABLE_CREATE2_FACTORY);
        address station = factory.safeCreate2(stationSalt, stationInit);

        bytes memory delegateInit = abi.encodePacked(type(TKGasDelegate).creationCode, abi.encode(station));
        address delegate = factory.safeCreate2(DELEGATE_SALT, delegateInit);

        TKGasStation(station).setDelegate(delegate);

        vm.stopBroadcast();

        console2.log("TKGasStation:", station);
        console2.log("TKGasDelegate:", delegate);
    }
}
