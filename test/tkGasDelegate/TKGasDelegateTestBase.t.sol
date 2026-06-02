// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {TKGasDelegate} from "../../src/TKGasStation/TKGasDelegate.sol";
import {MockDelegate} from "../mocks/MockDelegate.t.sol";
import {IBatchExecution} from "../../src/TKGasStation/interfaces/IBatchExecution.sol";
import "../../test/mocks/MockERC20.t.sol";

contract TKGasDelegateTestBase is Test {
    MockDelegate public tkGasDelegate;
    MockERC20 public mockToken;

    address public paymaster = makeAddr("paymaster");
    address public targetContract = makeAddr("targetContract");
    uint256 public constant USER_PRIVATE_KEY = 0xAAAAAA;
    uint256 public constant USER_PRIVATE_KEY_2 = 0xBBBBBB;
    address payable public user;
    address payable public user2;

    /// @dev Gas station passed to `MockDelegate` (`address(0)` = any caller may invoke the delegate).
    address public mockDelegateGasStation;

    /// @dev Override to bind the delegate to a gas station (e.g. `address(tkGasStation)`).
    function _mockDelegateGasStation() internal view virtual returns (address) {
        return address(0);
    }

    function setUp() public virtual {
        mockDelegateGasStation = _mockDelegateGasStation();
        tkGasDelegate = new MockDelegate(mockDelegateGasStation);
        user = payable(vm.addr(USER_PRIVATE_KEY)); // 0x3545A2F3928d5b21E71a790FB458F4AE03306C55
        user2 = payable(vm.addr(USER_PRIVATE_KEY_2));

        // Deploy Mock ERC20
        mockToken = new MockERC20("Test Token", "TEST");

        vm.deal(paymaster, 10 ether);

        // Delegate MockDelegate for the user
        _delegate(USER_PRIVATE_KEY);
        _delegate(USER_PRIVATE_KEY_2);
    }

    function _delegate(uint256 _userPrivateKey) internal {
        Vm.SignedDelegation memory signedDelegation =
            vm.signDelegation(payable(address(tkGasDelegate)), _userPrivateKey);

        vm.prank(paymaster);
        vm.attachDelegation(signedDelegation);
        vm.stopPrank();
    }

    function _signExecute(
        uint256 _privateKey,
        address payable _publicKey,
        uint128 _nonce,
        uint32 _deadline,
        address _outputContract,
        uint256 _ethAmount,
        bytes memory _arguments
    ) internal returns (bytes memory) {
        address signer = vm.addr(_privateKey);
        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _privateKey,
            MockDelegate(_publicKey).hashExecution(_nonce, _deadline, _outputContract, _ethAmount, _arguments)
        );
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
        return signature;
    }

    function _signBurnNonce(uint256 _privateKey, address payable _publicKey, uint128 _nonce)
        internal
        returns (bytes memory)
    {
        address signer = vm.addr(_privateKey);
        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, MockDelegate(_publicKey).hashBurnNonce(_nonce));
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
        return signature;
    }

    function _signBurnSessionCounter(uint256 _privateKey, address payable _publicKey, uint128 _counter)
        internal
        returns (bytes memory)
    {
        address signer = vm.addr(_privateKey);
        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(_privateKey, MockDelegate(_publicKey).hashBurnSessionCounter(_counter));
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
        return signature;
    }

    function _constructExecuteBytesNoValue(bytes memory _signature, uint128 _nonce, address _to, bytes memory _args)
        internal
        pure
        returns (bytes memory)
    {
        require(_signature.length == 65, "sig len");
        bytes16 nonce16 = bytes16(uint128(_nonce));
        bytes20 to20 = bytes20(_to);
        return abi.encodePacked(_signature, nonce16, to20, _args);
    }

    function _constructExecuteBytes(
        bytes memory _signature,
        uint128 _nonce,
        uint32 _deadline,
        address _to,
        uint256 _value,
        bytes memory _args
    ) internal pure returns (bytes memory) {
        require(_signature.length == 65, "sig len");
        bytes16 nonce16 = bytes16(uint128(_nonce));
        bytes20 to20 = bytes20(_to);
        bytes32 value32 = bytes32(_value);
        return abi.encodePacked(_signature, nonce16, bytes4(_deadline), to20, value32, _args);
    }

    function _signSessionExecuteWithSender(
        uint256 _privateKey,
        address payable _publicKey,
        uint128 _counter,
        uint32 _deadline,
        address _sender,
        address _outputContract
    ) internal returns (bytes memory) {
        address signer = vm.addr(_privateKey);
        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _privateKey,
            MockDelegate(_publicKey).hashSessionExecution(_counter, uint32(_deadline), _sender, _outputContract)
        );
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
        return signature;
    }

    function _constructSessionExecuteBytes(
        bytes memory _signature,
        uint128 _counter,
        uint32 _deadline,
        address _outputContract,
        uint256 _value,
        bytes memory _arguments
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(_signature, _counter, _deadline, _outputContract, _value, _arguments);
    }

    function _signBatch(
        uint256 _privateKey,
        address payable _publicKey,
        uint128 _nonce,
        uint32 _deadline,
        IBatchExecution.Call[] memory _calls
    ) internal returns (bytes memory) {
        address signer = vm.addr(_privateKey);
        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(_privateKey, MockDelegate(_publicKey).hashBatchExecution(_nonce, _deadline, _calls));
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
        return signature;
    }
}
