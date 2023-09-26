// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { console, Test } from "forge-std/Test.sol";
import { TrustedHintRegistry } from "../src/TrustedHintRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

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
        TrustedHintRegistry implementation = new TrustedHintRegistry();
        bytes memory data = abi.encodeCall(TrustedHintRegistry.initialize, ());
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);

        // wrap in ABI to support easier calls
        registry = TrustedHintRegistry(address(proxy));
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

    function testFuzz_FailIdentityIsOwnerIfNotOwner(address _notOwner) public {
        if (_notOwner != peterAddress) {
            assertFalse(registry.identityIsOwner(peterAddress, bytes32(0), _notOwner));
        }
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

    function testFuzz_FailIdentityIsDelegateIfNotDelegate(address _notDelegate) public {
        if (_notDelegate != peterAddress) {
            assertFalse(registry.identityIsDelegate(peterAddress, bytes32(0), _notDelegate));
        }
    }

    function test_Pause() public {
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");


        vm.prank(peterAddress);
        registry.setHint(peterAddress, list, key, value);
        assertEq(registry.getHint(peterAddress, list, key), value);
        assertEq(registry.paused(), false);

        vm.prank(address(0));
        registry.pause();
        assertEq(registry.paused(), true);

        vm.prank(peterAddress);
        bytes32 key2= keccak256("key2");
        bytes32 value2 = keccak256("value2");
        vm.expectRevert("Pausable: paused");
        registry.setHint(peterAddress, list, key2, value2);
        assertEq(registry.getHint(peterAddress, list, key), value);

        vm.prank(address(0));
        registry.unpause();

        vm.prank(peterAddress);
        registry.setHint(peterAddress, list, key2, value2);
        assertEq(registry.getHint(peterAddress, list, key2), value2);
    }
}