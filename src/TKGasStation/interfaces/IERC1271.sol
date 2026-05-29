// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title IERC1271
/// @notice EIP-1271 signature validation for smart contract wallets
/// @custom:security-contact security@turnkey.com
interface IERC1271 {
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue);
}
