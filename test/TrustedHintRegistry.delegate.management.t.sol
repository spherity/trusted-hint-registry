// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { console, Test } from "forge-std/Test.sol";
import { TrustedHintRegistry } from "../src/TrustedHintRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Sig712Utils } from "./utils/Sig712Utils.sol";
import { Events } from "./utils/Events.sol";

/*
* @notice Test util functionality of TrustedHintRegistry
*/
contract DelegateManagementTest is Test, Events {
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

    function test_AddListDelegate() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListDelegateAdded(namespace, list, peterAddress);

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), untilTimestamp);
    }

    function test_RevertAddListDelegateIfCallerNotOwner() public {
        vm.prank(address(999999));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        vm.expectRevert("Caller is not an owner");
        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
    }

    function test_RevertAddListDelegateIfTimestampNotInFuture() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = 0;

        vm.expectRevert("Timestamp must be in the future");
        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
    }

    function test_RevertAddListDelegateIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        vm.expectRevert("Pausable: paused");
        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
    }

    function test_AddListDelegateSigned() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        bytes32 digest = sig712.getAddListDelegateTypedDataHash(
            Sig712Utils.AddListDelegateEntry(namespace, list, peterAddress, untilTimestamp),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListDelegateAdded(namespace, list, peterAddress);

        vm.prank(marieAddress);
        registry.addListDelegateSigned(
            namespace,
            list,
            peterAddress,
            untilTimestamp,
            peterAddress,
            signature
        );
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), untilTimestamp);
        assertEq(registry.nonces(peterAddress), 1);
    }

    function test_RevertAddListDelegateSignedIfSignerNotOwner() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        bytes32 digest = sig712.getAddListDelegateTypedDataHash(
            Sig712Utils.AddListDelegateEntry(namespace, list, peterAddress, untilTimestamp),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.addListDelegateSigned(
            namespace,
            list,
            peterAddress,
            untilTimestamp,
            peterAddress,
            signature
        );
        assertEq(registry.nonces(peterAddress), 0);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), 0);
    }

    function test_RevertAddListDelegateSignedIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        bytes32 digest = sig712.getAddListDelegateTypedDataHash(
            Sig712Utils.AddListDelegateEntry(namespace, list, peterAddress, untilTimestamp),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.addListDelegateSigned(
            namespace,
            list,
            peterAddress,
            untilTimestamp,
            peterAddress,
            signature
        );
        assertEq(registry.nonces(peterAddress), 0);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), 0);
    }

    function test_RevertAddListDelegateSignedIfNonceInvalid() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        bytes32 digest = sig712.getAddListDelegateTypedDataHash(
            Sig712Utils.AddListDelegateEntry(namespace, list, peterAddress, untilTimestamp),
            peterAddress,
            registry.nonces(peterAddress) + 1
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.addListDelegateSigned(
            namespace,
            list,
            peterAddress,
            untilTimestamp,
            peterAddress,
            signature
        );
        assertEq(registry.nonces(peterAddress), 0);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), 0);
    }

    function test_RevertAddListDelegateSignedIfTimestampNotInFuture() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = 0;

        bytes32 digest = sig712.getAddListDelegateTypedDataHash(
            Sig712Utils.AddListDelegateEntry(namespace, list, peterAddress, untilTimestamp),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Timestamp must be in the future");
        registry.addListDelegateSigned(
            namespace,
            list,
            peterAddress,
            untilTimestamp,
            peterAddress,
            signature
        );
        assertEq(registry.nonces(peterAddress), 0);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), 0);
    }

    function test_RemoveListDelegate() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.identityIsDelegate(namespace, list, peterAddress), true);

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListDelegateRemoved(namespace, list, peterAddress);

        vm.prank(address(1));
        registry.removeListDelegate(namespace, list, peterAddress);
        assertEq(registry.identityIsDelegate(namespace, list, peterAddress), false);
    }

    function test_RevertRemoveListDelegateIfCallerNotOwner() public {
        vm.prank(address(999999));
        address namespace = address(1);
        bytes32 list = keccak256("list");

        vm.expectRevert("Caller is not an owner");
        registry.removeListDelegate(namespace, list, peterAddress);
        assertEq(registry.identityIsDelegate(namespace, list, peterAddress), false);
    }

    function test_RevertRemoveListDelegateIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");

        vm.expectRevert("Pausable: paused");
        registry.removeListDelegate(namespace, list, peterAddress);
        assertEq(registry.identityIsDelegate(namespace, list, peterAddress), false);
    }

    function test_RemoveListDelegateSigned() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.identityIsDelegate(namespace, list, peterAddress), true);

        bytes32 digest = sig712.getRemoveListDelegateTypedDataHash(
            Sig712Utils.RemoveListDelegateEntry(namespace, list, peterAddress),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListDelegateRemoved(namespace, list, peterAddress);

        vm.prank(marieAddress);
        registry.removeListDelegateSigned(
            namespace,
            list,
            peterAddress,
            peterAddress,
            signature
        );
        assertEq(registry.identityIsDelegate(namespace, list, peterAddress), false);
        assertEq(registry.nonces(peterAddress), 1);
    }

    function test_RevertRemoveListDelegateSignedIfSignerNotOwner() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.identityIsDelegate(namespace, list, peterAddress), true);

        bytes32 digest = sig712.getRemoveListDelegateTypedDataHash(
            Sig712Utils.RemoveListDelegateEntry(namespace, list, peterAddress),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.removeListDelegateSigned(
            namespace,
            list,
            peterAddress,
            peterAddress,
            signature
        );
        assertEq(registry.identityIsDelegate(namespace, list, peterAddress), true);
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertRemoveListDelegateSignedIfContractPaused() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.identityIsDelegate(namespace, list, peterAddress), true);

        vm.prank(address(0));
        registry.pause();

        vm.prank(peterAddress);
        bytes32 digest = sig712.getRemoveListDelegateTypedDataHash(
            Sig712Utils.RemoveListDelegateEntry(namespace, list, peterAddress),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.removeListDelegateSigned(
            namespace,
            list,
            peterAddress,
            peterAddress,
            signature
        );
        assertEq(registry.identityIsDelegate(namespace, list, peterAddress), true);
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertRemoveListDelegateSignedIfNonceInvalid() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.identityIsDelegate(namespace, list, peterAddress), true);

        bytes32 digest = sig712.getRemoveListDelegateTypedDataHash(
            Sig712Utils.RemoveListDelegateEntry(namespace, list, peterAddress),
            peterAddress,
            registry.nonces(peterAddress) + 1
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.removeListDelegateSigned(
            namespace,
            list,
            peterAddress,
            peterAddress,
            signature
        );
        assertEq(registry.identityIsDelegate(namespace, list, peterAddress), true);
        assertEq(registry.nonces(peterAddress), 0);
    }
}