// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { console, Test } from "forge-std/Test.sol";
import { TrustedHintRegistry } from "../src/TrustedHintRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Sig712Utils } from "./utils/Sig712Utils.sol";
import { Events } from "./utils/Events.sol";

/*
* @notice Test list status (revocation) functionality of TrustedHintRegistry
*/
contract ListStatusManagementTest is Test, Events {
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

    function test_SetListStatus() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bool revoked = true;

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListStatusChanged(namespace, list, revoked);

        registry.setListStatus(namespace, list, revoked);
        assertEq(registry.revokedLists(keccak256(abi.encodePacked(namespace, list))), revoked);
    }

    function test_RevertSetListStatusIfCallerNotOwner() public {
        vm.prank(address(999999));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bool revoked = true;

        vm.expectRevert("Caller is not an owner");
        registry.setListStatus(namespace, list, revoked);
    }

    function test_RevertSetListStatusIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bool revoked = true;

        vm.expectRevert("Pausable: paused");
        registry.setListStatus(namespace, list, revoked);
    }

    function test_SetListStatusSigned() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bool revoked = true;

        bytes32 digest = sig712.getSetListStatusTypedDataHash(
            Sig712Utils.ListStatusEntry(namespace, list, revoked),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListStatusChanged(namespace, list, revoked);

        vm.prank(marieAddress);
        registry.setListStatusSigned(
            namespace,
            list,
            revoked,
            peterAddress,
            signature
        );
        assertEq(registry.revokedLists(keccak256(abi.encodePacked(namespace, list))), revoked);
    }

    function test_RevertSetListStatusSignedIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bool revoked = true;

        bytes32 digest = sig712.getSetListStatusTypedDataHash(
            Sig712Utils.ListStatusEntry(namespace, list, revoked),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.setListStatusSigned(
            namespace,
            list,
            revoked,
            peterAddress,
            signature
        );
    }

    function test_RevertSetListStatusSignedIfNonceInvalid() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bool revoked = true;

        bytes32 digest = sig712.getSetListStatusTypedDataHash(
            Sig712Utils.ListStatusEntry(namespace, list, revoked),
            peterAddress,
            registry.nonces(peterAddress) + 1
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setListStatusSigned(
            namespace,
            list,
            revoked,
            peterAddress,
            signature
        );
    }

    function test_RevertSetListStatusSignedIfSignerNotOwner() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bool revoked = true;

        bytes32 digest = sig712.getSetListStatusTypedDataHash(
            Sig712Utils.ListStatusEntry(namespace, list, revoked),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setListStatusSigned(
            namespace,
            list,
            revoked,
            peterAddress,
            signature
        );
    }
}