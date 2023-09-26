// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { console, Test } from "forge-std/Test.sol";
import { TrustedHintRegistry } from "../src/TrustedHintRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Sig712Utils } from "./utils/Sig712Utils.sol";
import { Events } from "./utils/Events.sol";

/*
* @notice Test delegated calls of TrustedHintRegistry
*/
contract DelegateTest is Test, Events {
    TrustedHintRegistry internal registry;
    Sig712Utils internal sig712;
    address internal peterAddress;
    uint256 internal peterPrivateKey;
    address internal marieAddress;
    uint256 internal mariePrivateKey;

    function setUp() public {
        // Owner of this contract is address(0)!
        vm.startPrank(address(0));
        TrustedHintRegistry implementation = new TrustedHintRegistry();
        bytes memory data = abi.encodeCall(TrustedHintRegistry.initialize, ());
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);

        // wrap in ABI to support easier calls
        registry = TrustedHintRegistry(address(proxy));
        sig712 = new Sig712Utils(registry.version(), address(registry));
        vm.stopPrank();

        // Setup key pair for meta transactions
        peterPrivateKey = 1000000000000000000;
        peterAddress = vm.rememberKey(peterPrivateKey);
        mariePrivateKey = 1000000000000000001;
        marieAddress = vm.addr(mariePrivateKey);
    }

    function test_SetHintDelegated() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");
        uint256 untilTimestamp = block.timestamp + 100;

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListDelegateAdded(namespace, list, peterAddress);

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), untilTimestamp);

        vm.prank(peterAddress);

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintValueChanged(namespace, list, key, value);

        registry.setHintDelegated(namespace, list, key, value);
    }

    function test_RevertSetHintDelegatedIfCallerNotDelegate() public {
        vm.prank(address(999999));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");

        vm.expectRevert("Caller is not a delegate");

        registry.setHintDelegated(namespace, list, key, value);
    }

    function test_RevertSetHintDelegatedIfContractPaused() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");
        uint256 untilTimestamp = block.timestamp + 100;

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), untilTimestamp);

        vm.prank(address(0));
        registry.pause();

        vm.prank(peterAddress);
        vm.expectRevert("Pausable: paused");
        registry.setHintDelegated(namespace, list, key, value);
    }

    function test_SetHintDelegatedSigned() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");
        uint256 untilTimestamp = block.timestamp + 100;

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListDelegateAdded(namespace, list, peterAddress);

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), untilTimestamp);

        bytes32 digest = sig712.getSetHintDelegatedTypedDataHash(
            Sig712Utils.HintEntry(namespace, list, key, value),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(marieAddress);

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintValueChanged(namespace, list, key, value);

        registry.setHintDelegatedSigned(namespace, list, key, value, peterAddress, signature);

        assertEq(registry.getHint(namespace, list, key), value);
        assertEq(registry.nonces(peterAddress), 1);
    }

    function test_RevertSetHintDelegatedSignedIfSignerNotDelegate() public {
        vm.prank(marieAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");

        bytes32 digest = sig712.getSetHintDelegatedTypedDataHash(
            Sig712Utils.HintEntry(namespace, list, key, value),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not a delegate");
        registry.setHintDelegatedSigned(namespace, list, key, value, marieAddress, signature);

        assertEq(registry.getHint(namespace, list, key), bytes32(0));
        assertEq(registry.nonces(marieAddress), 0);
    }

    function test_RevertSetHintDelegatedSignedIfContractPaused() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");
        uint256 untilTimestamp = block.timestamp + 100;

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListDelegateAdded(namespace, list, peterAddress);

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), untilTimestamp);

        bytes32 digest = sig712.getSetHintDelegatedTypedDataHash(
            Sig712Utils.HintEntry(namespace, list, key, value),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(address(0));
        registry.pause();

        vm.prank(marieAddress);
        vm.expectRevert("Pausable: paused");
        registry.setHintDelegatedSigned(namespace, list, key, value, peterAddress, signature);

        assertEq(registry.getHint(namespace, list, key), bytes32(0));
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_SetHintsDelegated() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32[] memory keys = new bytes32[](2);
        bytes32[] memory values = new bytes32[](2);
        uint256 untilTimestamp = block.timestamp + 100;

        for (uint256 i = 0; i < 2; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
        }

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListDelegateAdded(namespace, list, peterAddress);

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), untilTimestamp);

        vm.prank(peterAddress);

        vm.expectEmit(true, true, true, true, address(registry));
        for (uint256 i = 0; i < 2; i++) {
            emit HintValueChanged(namespace, list, keys[i], values[i]);
        }

        registry.setHintsDelegated(namespace, list, keys, values);
    }

    function test_RevertSetHintsDelegatedIfCallerNotDelegate() public {
        vm.prank(address(999999));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32[] memory keys = new bytes32[](2);
        bytes32[] memory values = new bytes32[](2);

        for (uint256 i = 0; i < 2; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
        }

        vm.expectRevert("Caller is not a delegate");

        registry.setHintsDelegated(namespace, list, keys, values);
    }

    function test_RevertSetHintsDelegatedIfContractPaused() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32[] memory keys = new bytes32[](2);
        bytes32[] memory values = new bytes32[](2);
        uint256 untilTimestamp = block.timestamp + 100;

        for (uint256 i = 0; i < 2; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
        }

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), untilTimestamp);

        vm.prank(address(0));
        registry.pause();

        vm.prank(peterAddress);
        vm.expectRevert("Pausable: paused");
        registry.setHintsDelegated(namespace, list, keys, values);
    }

    function test_SetHintsDelegatedSigned() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32[] memory keys = new bytes32[](2);
        bytes32[] memory values = new bytes32[](2);
        uint256 untilTimestamp = block.timestamp + 100;

        for (uint256 i = 0; i < 2; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
        }

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListDelegateAdded(namespace, list, peterAddress);

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), untilTimestamp);

        bytes32 digest = sig712.getSetHintsDelegatedTypedDataHash(
            Sig712Utils.HintsEntry(namespace, list, keys, values),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(marieAddress);

        vm.expectEmit(true, true, true, true, address(registry));
        for (uint256 i = 0; i < 2; i++) {
            emit HintValueChanged(namespace, list, keys[i], values[i]);
        }

        registry.setHintsDelegatedSigned(namespace, list, keys, values, peterAddress, signature);

        assertEq(registry.getHint(namespace, list, keys[0]), values[0]);
        assertEq(registry.getHint(namespace, list, keys[1]), values[1]);
        assertEq(registry.nonces(peterAddress), 1);
    }

    function test_RevertSetHintsDelegatedSignedIfSignerNotDelegate() public {
        vm.prank(marieAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bytes32[] memory keys = new bytes32[](2);
        bytes32[] memory values = new bytes32[](2);

        for (uint256 i = 0; i < 2; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
        }

        bytes32 digest = sig712.getSetHintsDelegatedTypedDataHash(
            Sig712Utils.HintsEntry(namespace, list, keys, values),
            marieAddress,
            registry.nonces(marieAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not a delegate");
        registry.setHintsDelegatedSigned(namespace, list, keys, values, marieAddress, signature);

        for (uint256 i = 0; i < 2; i++) {
            assertEq(registry.getHint(namespace, list, keys[i]), bytes32(0));
        }
        assertEq(registry.nonces(marieAddress), 0);
    }

    function test_RevertSetHintsDelegatedSignedIfContractPaused() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32[] memory keys = new bytes32[](2);
        bytes32[] memory values = new bytes32[](2);
        uint256 untilTimestamp = block.timestamp + 100;

        for (uint256 i = 0; i < 2; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
        }

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListDelegateAdded(namespace, list, peterAddress);

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), untilTimestamp);

        bytes32 digest = sig712.getSetHintsDelegatedTypedDataHash(
            Sig712Utils.HintsEntry(namespace, list, keys, values),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(address(0));
        registry.pause();

        vm.prank(marieAddress);
        vm.expectRevert("Pausable: paused");
        registry.setHintsDelegatedSigned(namespace, list, keys, values, peterAddress, signature);

        for (uint256 i = 0; i < 2; i++) {
            assertEq(registry.getHint(namespace, list, keys[i]), bytes32(0));
        }
        assertEq(registry.nonces(peterAddress), 0);
    }
}