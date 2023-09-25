// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { console, Test } from "forge-std/Test.sol";
import { TrustedHintRegistry } from "../src/TrustedHintRegistry.sol";

/*
* @notice Test util functionality of TrustedHintRegistry
*/
contract UtilTest is Test {
    TrustedHintRegistry internal registry;
    address internal peterAddress;
    uint256 internal peterPrivateKey;
    address internal marieAddress;
    uint256 internal mariePrivateKey;

    function setUp() public {
        // Owner of this contract is address(0)!
        vm.startPrank(address(0));
        registry = new TrustedHintRegistry();
        registry.initialize();
        vm.stopPrank();

        // Setup key pair for meta transactions
        peterPrivateKey = 1000000000000000000;
        peterAddress = vm.rememberKey(peterPrivateKey);
        mariePrivateKey = 1000000000000000001;
        marieAddress = vm.addr(mariePrivateKey);
    }

    function test_IdentityIsOwner() public {
        assertTrue(registry.identityIsOwner(peterAddress, bytes32(0), peterAddress));
    }

    function test_IdentityIsOwnerIfNewOwner() public {
        address namespace = peterAddress;
        bytes32 list = bytes32(0);
        address newOwner = marieAddress;

        assertTrue(registry.identityIsOwner(peterAddress, bytes32(0), peterAddress));
        assertFalse(registry.identityIsOwner(peterAddress, bytes32(0), marieAddress));

        vm.prank(peterAddress);
        registry.setListOwner(namespace, list, newOwner);
        assertTrue(registry.identityIsOwner(peterAddress, bytes32(0), marieAddress));
        assertFalse(registry.identityIsOwner(peterAddress, bytes32(0), peterAddress));
    }

    function test_FailIdentityIsOwnerIfNotOwner() public {
        assertFalse(registry.identityIsOwner(peterAddress, bytes32(0), marieAddress));
    }

    function test_IdentityIsDelegate() public {
        address namespace = peterAddress;
        bytes32 list = bytes32(0);
        address delegate = marieAddress;

        assertFalse(registry.identityIsDelegate(peterAddress, bytes32(0), marieAddress));
        vm.prank(peterAddress);
        registry.addListDelegate(namespace, list, delegate, 100);
        assertTrue(registry.identityIsDelegate(peterAddress, bytes32(0), marieAddress));
    }

    function test_FailIdentityIsDelegateIfNotDelegate() public {
        assertFalse(registry.identityIsDelegate(peterAddress, bytes32(0), marieAddress));
    }
}