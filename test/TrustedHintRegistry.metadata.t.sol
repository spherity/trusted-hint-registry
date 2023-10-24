// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { console, Test } from "forge-std/Test.sol";
import { TrustedHintRegistry } from "../src/TrustedHintRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Sig712Utils } from "./utils/Sig712Utils.sol";
import { Events } from "./utils/Events.sol";

contract MetadataTest is Test, Events {
    TrustedHintRegistry internal registry;
    Sig712Utils internal sig712;
    address internal peterAddress;
    uint256 internal peterPrivateKey;
    address internal marieAddress;
    uint256 internal mariePrivateKey;
    address internal namespace = address(1);
    bytes32 internal list = keccak256("list");
    bytes32 internal key = keccak256("key");
    bytes32 internal value = keccak256("value");
    bytes internal metadata = abi.encodePacked("test,test");
    bytes32 internal hintLocationHash = keccak256(abi.encodePacked(namespace, list, key, value));


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

    function test_SetHintWithMetadata() public {
        vm.prank(address(1));

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintValueChanged(namespace, list, key, value);

        registry.setHint(namespace, list, key, value, metadata);

        assertEq(registry.getHint(namespace, list, key), value);
        assertEq(registry.metadata(hintLocationHash), metadata);
    }

    function test_RevertSetHintWithMetadataIfWrongOwner() public {
        vm.prank(address(999999));

        vm.expectRevert("Caller is not an owner");

        registry.setHint(namespace, list, key, value, metadata);
        assertEq(registry.metadata(hintLocationHash), bytes(""));
    }

    function test_RevertSetHintWithMetadataIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(1));

        vm.expectRevert("Pausable: paused");
        registry.setHint(namespace, list, key, value, metadata);

        assertEq(registry.getHint(namespace, list, key), bytes32(0));
        assertEq(registry.metadata(hintLocationHash), bytes(""));
    }

    function test_SetHintWithMetadataSigned() public {
        vm.prank(address(999999));

        bytes32 digest = sig712.getSetHintMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        registry.setHintMetadataSigned(peterAddress, list, key, value, metadata, peterAddress, signature);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), metadata);
    }

    function test_RevertSetHintMetadataSignedIfWrongOwner() public {
        vm.prank(address(999999));

        bytes32 digest = sig712.getSetHintMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setHintMetadataSigned(peterAddress, list, key, value, metadata, marieAddress, signature);

        assertEq(registry.metadata(hintLocationHash), bytes(""));
    }
}
