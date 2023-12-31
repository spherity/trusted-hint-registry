// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { console, Test } from "forge-std/Test.sol";
import { TrustedHintRegistry } from "../src/TrustedHintRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Sig712Utils } from "./utils/Sig712Utils.sol";
import { Events } from "./utils/Events.sol";

/*
* @notice Test base functionality of TrustedHintRegistry
*/
contract BaseTest is Test, Events {
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

    function test_SetHint() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintValueChanged(namespace, list, key, value);

        registry.setHint(namespace, list, key, value);

        assertEq(registry.getHint(namespace, list, key), value);
    }

    function test_RevertSetHintIfWrongOwner() public {
        vm.prank(address(999999));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");

        vm.expectRevert("Caller is not an owner");

        registry.setHint(namespace, list, key, value);
    }

    function test_RevertSetHintIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");

        vm.expectRevert("Pausable: paused");
        registry.setHint(namespace, list, key, value);

        assertEq(registry.getHint(namespace, list, key), bytes32(0));
    }

    function test_SetHintSigned() public {
        vm.prank(address(999999));
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");

        bytes32 digest = sig712.getSetHintTypedDataHash(
            Sig712Utils.HintEntry(namespace, list, key, value),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintValueChanged(namespace, list, key, value);

        registry.setHintSigned(namespace, list, key, value, peterAddress, signature);

        assertEq(registry.getHint(namespace, list, key), value);
        assertEq(registry.nonces(peterAddress), 1);
    }

    function test_RevertSetHintSignedIfSignatureInvalid() public {
        vm.prank(marieAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");

        bytes32 digest = sig712.getSetHintTypedDataHash(
            Sig712Utils.HintEntry(namespace, list, key, value),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setHintSigned(namespace, list, key, value, marieAddress, signature);

        assertEq(registry.getHint(namespace, list, key), 0);
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertSetHintSignedIfNonceInvalid() public {
        vm.prank(address(999999));
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");
        uint invalidNonce = 100;

        bytes32 digest = sig712.getSetHintTypedDataHash(
            Sig712Utils.HintEntry(namespace, list, key, value),
            peterAddress,
            invalidNonce
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setHintSigned(namespace, list, key, value, marieAddress, signature);

        assertEq(registry.getHint(namespace, list, key), 0);
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertSetHintSignedIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(999999));
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");

        bytes32 digest = sig712.getSetHintTypedDataHash(
            Sig712Utils.HintEntry(namespace, list, key, value),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.setHintSigned(namespace, list, key, value, peterAddress, signature);

        assertEq(registry.getHint(namespace, list, key), bytes32(0));
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_SetHints() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
        }

        for (uint i = 0; i < 10; i++) {
            vm.expectEmit(true, true, true, true, address(registry));
            emit HintValueChanged(namespace, list, keys[i], values[i]);
        }

        registry.setHints(namespace, list, keys, values);

        for (uint i = 0; i < 10; i++) {
            assertEq(registry.getHint(namespace, list, keys[i]), values[i]);
        }
    }

    function test_RevertSetHintsIfWrongOwner() public {
        vm.prank(address(999999));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
        }

        vm.expectRevert("Caller is not an owner");

        registry.setHints(namespace, list, keys, values);

        for (uint i = 0; i < 10; i++) {
            assertEq(registry.getHint(namespace, list, keys[i]), 0);
        }
    }

    function test_RevertSetHintsIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
        }

        vm.expectRevert("Pausable: paused");
        registry.setHints(namespace, list, keys, values);

        for (uint i = 0; i < 10; i++) {
            assertEq(registry.getHint(namespace, list, keys[i]), bytes32(0));
        }
    }

    function test_SetHintsSigned() public {
        vm.prank(address(999999));
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
        }

        bytes32 digest = sig712.getSetHintsTypedDataHash(
            Sig712Utils.HintsEntry(namespace, list, keys, values),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        for (uint i = 0; i < 10; i++) {
            vm.expectEmit(true, true, true, true, address(registry));
            emit HintValueChanged(namespace, list, keys[i], values[i]);
        }

        registry.setHintsSigned(namespace, list, keys, values, peterAddress, signature);

        for (uint i = 0; i < 10; i++) {
            assertEq(registry.getHint(namespace, list, keys[i]), values[i]);
        }
        assertEq(registry.nonces(peterAddress), 1);
    }

    function test_RevertSetHintsSignedIfSignatureInvalid() public {
        vm.prank(marieAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
        }

        bytes32 digest = sig712.getSetHintsTypedDataHash(
            Sig712Utils.HintsEntry(namespace, list, keys, values),
            marieAddress,
            registry.nonces(marieAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setHintsSigned(namespace, list, keys, values, marieAddress, signature);

        for (uint i = 0; i < 10; i++) {
            assertEq(registry.getHint(namespace, list, keys[i]), 0);
        }
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertSetHintsSignedIfNonceInvalid() public {
        vm.prank(address(999999));
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);
        uint invalidNonce = 100;

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
        }

        bytes32 digest = sig712.getSetHintsTypedDataHash(
            Sig712Utils.HintsEntry(namespace, list, keys, values),
            peterAddress,
            invalidNonce
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setHintsSigned(namespace, list, keys, values, marieAddress, signature);

        for (uint i = 0; i < 10; i++) {
            assertEq(registry.getHint(namespace, list, keys[i]), 0);
        }
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertSetHintsSignedIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(999999));
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
        }

        bytes32 digest = sig712.getSetHintsTypedDataHash(
            Sig712Utils.HintsEntry(namespace, list, keys, values),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.setHintsSigned(namespace, list, keys, values, peterAddress, signature);

        for (uint i = 0; i < 10; i++) {
            assertEq(registry.getHint(namespace, list, keys[i]), bytes32(0));
        }
        assertEq(registry.nonces(peterAddress), 0);
    }
}