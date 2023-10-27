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
        vm.prank(namespace);

        registry.setHintMetadata(namespace, list, key, value, metadata);

        assertEq(registry.metadata(hintLocationHash), metadata);
    }

    function test_RevertSetHintWithMetadataIfWrongOwner() public {
        vm.prank(address(999999));

        vm.expectRevert("Caller is not an owner");

        registry.setHintMetadata(namespace, list, key, value, metadata);
        assertEq(registry.metadata(hintLocationHash), bytes(""));
    }

    function test_RevertSetHintWithMetadataIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(1));

        vm.expectRevert("Pausable: paused");
        registry.setHintMetadata(namespace, list, key, value, metadata);

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
        assertEq(registry.nonces(peterAddress), 1);
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

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), "");
        assertEq(registry.nonces(marieAddress), 0);
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertSetHintMetadataSignedIfPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(999999));

        bytes32 digest = sig712.getSetHintMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.setHintMetadataSigned(peterAddress, list, key, value, metadata, peterAddress, signature);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), "");
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertSetHintMetadataSignedIfNonceWrong() public {
        vm.prank(address(999999));

        bytes32 digest = sig712.getSetHintMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            peterAddress,
            10000
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setHintMetadataSigned(peterAddress, list, key, value, metadata, peterAddress, signature);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), "");
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_SetHintMetadataDelegated() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(marieAddress);
        registry.setHintMetadataDelegated(peterAddress, list, key, value, metadata);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), metadata);
    }

    function test_RevertSetHintMetadataDelegatedIfNotDelegate() public {
        vm.prank(marieAddress);
        vm.expectRevert("Caller is not a delegate");
        registry.setHintMetadataDelegated(peterAddress, list, key, value, metadata);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), "");
    }

    function test_RevertSetHintMetadataDelegatedIfPaused() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(address(0));
        registry.pause();

        vm.prank(marieAddress);
        vm.expectRevert("Pausable: paused");
        registry.setHintMetadataDelegated(peterAddress, list, key, value, metadata);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), "");
    }

    function test_SetHintMetadataDelegatedSigned() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(address(0));
        bytes32 digest = sig712.getSetHintMetadataDelegatedTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        registry.setHintMetadataDelegatedSigned(peterAddress, list, key, value, metadata, marieAddress, signature);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), metadata);
        assertEq(registry.nonces(marieAddress), 1);
    }

    function test_RevertSetHintMetadataDelegatedSignedIfWrongSigner() public {
        vm.prank(marieAddress);
        bytes32 digest = sig712.getSetHintMetadataDelegatedTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not a delegate");
        registry.setHintMetadataDelegatedSigned(peterAddress, list, key, value, metadata, marieAddress, signature);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), "");
        assertEq(registry.nonces(marieAddress), 0);
    }

    function test_RevertSetHintMetadataDelegatedSignedIfPaused() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(address(0));
        registry.pause();

        vm.prank(marieAddress);
        bytes32 digest = sig712.getSetHintMetadataDelegatedTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.setHintMetadataDelegatedSigned(peterAddress, list, key, value, metadata, marieAddress, signature);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), "");
        assertEq(registry.nonces(marieAddress), 0);
    }

    function test_SetListMetadata() public {
        vm.prank(namespace);
        registry.setListMetadata(namespace, list, metadata);
        assertEq(registry.metadata(keccak256(abi.encodePacked(namespace, list))), metadata);
    }

    function test_RevertSetListMetadataIfNotOwner() public {
        vm.prank(address(999999));
        vm.expectRevert("Caller is not an owner");
        registry.setListMetadata(namespace, list, metadata);
        assertEq(registry.metadata(keccak256(abi.encodePacked(namespace, list))), "");
    }

    function test_RevertSetListMetadataIfPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(namespace);
        vm.expectRevert("Pausable: paused");
        registry.setListMetadata(namespace, list, metadata);
        assertEq(registry.metadata(keccak256(abi.encodePacked(namespace, list))), "");
    }

    function test_SetListMetadataSigned() public {
        vm.prank(address(999999));

        bytes32 digest = sig712.getSetListMetadataTypedDataHash(
            Sig712Utils.ListMetadataEntry(peterAddress, list, metadata),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        registry.setListMetadataSigned(peterAddress, list, metadata, peterAddress, signature);

        assertEq(registry.metadata(keccak256(abi.encodePacked(peterAddress, list))), metadata);
        assertEq(registry.nonces(peterAddress), 1);
    }

    function test_RevertSetListMetadataSignedIfWrongSigner() public {
        vm.prank(address(999999));

        bytes32 digest = sig712.getSetListMetadataTypedDataHash(
            Sig712Utils.ListMetadataEntry(peterAddress, list, metadata),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setListMetadataSigned(peterAddress, list, metadata, marieAddress, signature);

        assertEq(registry.metadata(keccak256(abi.encodePacked(peterAddress, list))), "");
        assertEq(registry.nonces(marieAddress), 0);
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertSetListMetadataSignedIfPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(marieAddress);

        bytes32 digest = sig712.getSetListMetadataTypedDataHash(
            Sig712Utils.ListMetadataEntry(peterAddress, list, metadata),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.setListMetadataSigned(peterAddress, list, metadata, peterAddress, signature);

        assertEq(registry.metadata(keccak256(abi.encodePacked(peterAddress, list))), "");
        assertEq(registry.nonces(peterAddress), 0);
        assertEq(registry.nonces(marieAddress), 0);
    }

    function test_SetListMetadataDelegated() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(marieAddress);
        registry.setListMetadataDelegated(peterAddress, list, metadata);

        assertEq(registry.metadata(keccak256(abi.encodePacked(peterAddress, list))), metadata);
    }

    function test_RevertSetListMetadataDelegatedIfNotDelegate() public {
        vm.prank(marieAddress);
        vm.expectRevert("Caller is not a delegate");
        registry.setListMetadataDelegated(peterAddress, list, metadata);

        assertEq(registry.metadata(keccak256(abi.encodePacked(peterAddress, list))), "");
    }

    function test_RevertSetListMetadataDelegatedIfPaused() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(address(0));
        registry.pause();

        vm.prank(marieAddress);
        vm.expectRevert("Pausable: paused");
        registry.setListMetadataDelegated(peterAddress, list, metadata);

        assertEq(registry.metadata(keccak256(abi.encodePacked(peterAddress, list))), "");
    }

    function test_SetListMetadataDelegatedSigned() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(address(0));
        bytes32 digest = sig712.getSetListMetadataDelegatedTypedDataHash(
            Sig712Utils.ListMetadataEntry(peterAddress, list, metadata),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        registry.setListMetadataDelegatedSigned(peterAddress, list, metadata, marieAddress, signature);

        assertEq(registry.metadata(keccak256(abi.encodePacked(peterAddress, list))), metadata);
        assertEq(registry.nonces(marieAddress), 1);
    }

    function test_RevertSetListMetadataDelegatedSignedIfWrongSigner() public {
        vm.prank(marieAddress);
        bytes32 digest = sig712.getSetListMetadataDelegatedTypedDataHash(
            Sig712Utils.ListMetadataEntry(peterAddress, list, metadata),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not a delegate");
        registry.setListMetadataDelegatedSigned(peterAddress, list, metadata, marieAddress, signature);

        assertEq(registry.metadata(keccak256(abi.encodePacked(peterAddress, list))), "");
        assertEq(registry.nonces(marieAddress), 0);
    }

    function test_RevertSetListMetadataDelegatedSignedIfPaused() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(address(0));
        registry.pause();

        vm.prank(marieAddress);
        bytes32 digest = sig712.getSetListMetadataDelegatedTypedDataHash(
            Sig712Utils.ListMetadataEntry(peterAddress, list, metadata),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.setListMetadataDelegatedSigned(peterAddress, list, metadata, marieAddress, signature);

        assertEq(registry.metadata(keccak256(abi.encodePacked(peterAddress, list))), "");
        assertEq(registry.nonces(marieAddress), 0);
    }
}
