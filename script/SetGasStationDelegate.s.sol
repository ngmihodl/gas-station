// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {TKGasStation} from "../src/TKGasStation/TKGasStation.sol";

/// @notice Calls `TKGasStation.setDelegate` using `PRIVATE_KEY` as the owner broadcaster.
contract SetGasStationDelegate is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address gasStation = vm.envAddress("TK_GAS_STATION");
        address delegate = vm.envAddress("TK_GAS_DELEGATE");

        vm.startBroadcast(deployerPrivateKey);
        TKGasStation(gasStation).setDelegate(delegate);
        vm.stopBroadcast();

        console2.log("Gas station:", gasStation);
        console2.log("setDelegate to:", delegate);
    }
}
