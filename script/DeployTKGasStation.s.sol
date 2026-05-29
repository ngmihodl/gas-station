// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {TKGasStation} from "../src/TKGasStation/TKGasStation.sol";

interface IImmutableCreate2Factory {
    function safeCreate2(bytes32 _salt, bytes calldata _initCode) external payable returns (address _deploymentAddress);
}

/// @custom:security-contact security@turnkey.com
contract DeployTKGasStation is Script {
    address private constant IMMUTABLE_CREATE2_FACTORY = 0x0000000000FFe8B47B3e2130213B802212439497;

    function run() external {
        uint256 _deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address _owner = vm.addr(_deployerPrivateKey);
        address _delegate = address(0);

        bytes32 _salt = bytes32((uint256(uint160(_owner)) << 96) | uint256(0x4761737379));

        vm.startBroadcast(_deployerPrivateKey);

        // Delegate starts unset (0); owner is the broadcast account. Set delegate later via onlyOwner.
        bytes memory _creationCode = type(TKGasStation).creationCode;
        bytes memory _constructorArgs = abi.encode(_delegate, _owner);
        bytes memory _initCode = abi.encodePacked(_creationCode, _constructorArgs);

        IImmutableCreate2Factory _factory = IImmutableCreate2Factory(IMMUTABLE_CREATE2_FACTORY);
        address _station = _factory.safeCreate2(_salt, _initCode);
        console2.log("TKGasStation owner:", _owner);
        console2.log("TKGasStation tkGasDelegate (initial):", _delegate);
        console2.log("TKGasStation deployed at:", _station);

        vm.stopBroadcast();
    }
}


