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

    // GET HINT

    function test_GetMetadata() public {
        vm.prank(namespace);

        registry.setMetadata(namespace, list, key, value, metadata);

        assertEq(registry.getMetadata(namespace, list, key, value), metadata);
    }

    function test_GetMetadataIfNotSet() public {
        vm.prank(namespace);

        assertEq(registry.getMetadata(namespace, list, key, value), bytes(""));
    }

    // SET HINT WITH METADATA
    function test_SetHintWithMetadata() public {
        vm.prank(namespace);

        registry.setHint(namespace, list, key, value, metadata);

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

    // SET HINT WITH METADATA SIGNED
    function test_SetHintWithMetadataSigned() public {
        vm.prank(address(999999));

        bytes32 digest = sig712.getSetHintWithMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        registry.setHintSigned(peterAddress, list, key, value, metadata, peterAddress, signature);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), metadata);
        assertEq(registry.nonces(peterAddress), 1);
    }

    function test_RevertSetHintWithMetadataSignedIfWrongOwner() public {
        vm.prank(address(999999));

        bytes32 digest = sig712.getSetHintMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setHintSigned(peterAddress, list, key, value, metadata, marieAddress, signature);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), "");
        assertEq(registry.nonces(marieAddress), 0);
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertSetHintWithMetadataSignedIfPaused() public {
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
        registry.setHintSigned(peterAddress, list, key, value, metadata, peterAddress, signature);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), "");
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertSetHintWithMetadataSignedIfNonceWrong() public {
        vm.prank(address(999999));

        bytes32 digest = sig712.getSetHintMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            peterAddress,
            10000
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setHintSigned(peterAddress, list, key, value, metadata, peterAddress, signature);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), "");
        assertEq(registry.nonces(peterAddress), 0);
    }

    // SET HINT WITH METADATA DELEGATED
    function test_SetHintWithMetadataDelegated() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(marieAddress);
        registry.setHintDelegated(peterAddress, list, key, value, metadata);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), metadata);
    }

    function test_RevertSetHintWithMetadataDelegatedIfNotDelegate() public {
        vm.prank(marieAddress);
        vm.expectRevert("Caller is not a delegate");
        registry.setHintDelegated(peterAddress, list, key, value, metadata);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), "");
    }

    function test_RevertSetHintWithMetadataDelegatedIfPaused() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(address(0));
        registry.pause();

        vm.prank(marieAddress);
        vm.expectRevert("Pausable: paused");
        registry.setHintDelegated(peterAddress, list, key, value, metadata);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), "");
    }

    // SET HINT WITH METADATA DELEGATED SIGNED
    function test_SetHintWithMetadataDelegatedSigned() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(address(0));
        bytes32 digest = sig712.getSetHintDelegatedWithMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        registry.setHintDelegatedSigned(peterAddress, list, key, value, metadata, marieAddress, signature);

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
        registry.setHintDelegatedSigned(peterAddress, list, key, value, metadata, marieAddress, signature);

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
        registry.setHintDelegatedSigned(peterAddress, list, key, value, metadata, marieAddress, signature);

        bytes32 peterHintLocationHash = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(peterHintLocationHash), "");
        assertEq(registry.nonces(marieAddress), 0);
    }

    // SET HINTS WITH METADATA
    function test_SetHintsWithMetadata() public {
        vm.prank(namespace);

        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);
        bytes[] memory metadataValues = new bytes[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
            metadataValues[i] = abi.encodePacked("test", i);
        }

        registry.setHints(namespace, list, keys, values, metadataValues);

        for (uint i = 0; i < 10; i++) {
            bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(namespace, list, keys[i], values[i]));
            assertEq(registry.metadata(hintLocationHashEntry), metadataValues[i]);
        }
    }

    function test_RevertSetHintsWithMetadataIfNotOwner() public {
        vm.prank(address(999999));

        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);
        bytes[] memory metadataValues = new bytes[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
            metadataValues[i] = abi.encodePacked("test", i);
        }

        vm.expectRevert("Caller is not an owner");
        registry.setHints(namespace, list, keys, values, metadataValues);

        for (uint i = 0; i < 10; i++) {
            bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(namespace, list, keys[i], values[i]));
            assertEq(registry.metadata(hintLocationHashEntry), "");
        }
    }

    function test_RevertSetHintsWithMetadataWhenPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(namespace);

        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);
        bytes[] memory metadataValues = new bytes[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
            metadataValues[i] = abi.encodePacked("test", i);
        }

        vm.expectRevert("Pausable: paused");
        registry.setHints(namespace, list, keys, values, metadataValues);

        for (uint i = 0; i < 10; i++) {
            bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(namespace, list, keys[i], values[i]));
            assertEq(registry.metadata(hintLocationHashEntry), "");
        }
    }

    // SET HINTS WITH METADATA SIGNED

    function test_SetHintsWithMetadataSigned() public {
        vm.prank(address(999999));

        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);
        bytes[] memory metadataValues = new bytes[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
            metadataValues[i] = abi.encodePacked("test", i);
        }

        bytes32 digest = sig712.getSetHintsMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntries(peterAddress, list, keys, values, metadataValues),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        registry.setHintsSigned(peterAddress, list, keys, values, metadataValues, peterAddress, signature);

        for (uint i = 0; i < 10; i++) {
            bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, keys[i], values[i]));
            assertEq(registry.metadata(hintLocationHashEntry), metadataValues[i]);
        }
        assertEq(registry.nonces(peterAddress), 1);
    }

    function test_RevertSetHintsWithMetadataSignedIfWrongOwner() public {
        vm.prank(address(999999));

        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);
        bytes[] memory metadataValues = new bytes[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
            metadataValues[i] = abi.encodePacked("test", i);
        }

        bytes32 digest = sig712.getSetHintsMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntries(peterAddress, list, keys, values, metadataValues),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setHintsSigned(peterAddress, list, keys, values, metadataValues, marieAddress, signature);

        for (uint i = 0; i < 10; i++) {
            bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, keys[i], values[i]));
            assertEq(registry.metadata(hintLocationHashEntry), "");
        }
        assertEq(registry.nonces(marieAddress), 0);
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertSetHintsWithMetadataSignedIfPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(999999));

        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);
        bytes[] memory metadataValues = new bytes[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
            metadataValues[i] = abi.encodePacked("test", i);
        }

        bytes32 digest = sig712.getSetHintsMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntries(peterAddress, list, keys, values, metadataValues),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.setHintsSigned(peterAddress, list, keys, values, metadataValues, peterAddress, signature);

        for (uint i = 0; i < 10; i++) {
            bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, keys[i], values[i]));
            assertEq(registry.metadata(hintLocationHashEntry), "");
        }

        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertSetHintsWithMetadataSignedIfNonceWrong() public {
        vm.prank(address(999999));

        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);
        bytes[] memory metadataValues = new bytes[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
            metadataValues[i] = abi.encodePacked("test", i);
        }

        uint256 wrongNonce = 10000;
        bytes32 digest = sig712.getSetHintsMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntries(peterAddress, list, keys, values, metadataValues),
            peterAddress,
            wrongNonce
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setHintsSigned(peterAddress, list, keys, values, metadataValues, peterAddress, signature);

        for (uint i = 0; i < 10; i++) {
            bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, keys[i], values[i]));
            assertEq(registry.metadata(hintLocationHashEntry), "");
        }

        assertEq(registry.nonces(peterAddress), 0);
    }

    // SET HINTS WITH METADATA DELEGATED

    function test_SetHintsWithMetadataDelegated() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(marieAddress);

        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);
        bytes[] memory metadataValues = new bytes[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
            metadataValues[i] = abi.encodePacked("test", i);
        }

        registry.setHintsDelegated(peterAddress, list, keys, values, metadataValues);

        for (uint i = 0; i < 10; i++) {
            bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, keys[i], values[i]));
            assertEq(registry.metadata(hintLocationHashEntry), metadataValues[i]);
        }
    }

    function test_RevertSetHintsWithMetadataDelegatedIfNotDelegate() public {
        vm.prank(marieAddress);

        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);
        bytes[] memory metadataValues = new bytes[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
            metadataValues[i] = abi.encodePacked("test", i);
        }

        vm.expectRevert("Caller is not a delegate");
        registry.setHintsDelegated(peterAddress, list, keys, values, metadataValues);

        for (uint i = 0; i < 10; i++) {
            bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, keys[i], values[i]));
            assertEq(registry.metadata(hintLocationHashEntry), "");
        }
    }

    function test_RevertSetHintsWithMetadataDelegatedIfPaused() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(address(0));
        registry.pause();

        vm.prank(marieAddress);

        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);
        bytes[] memory metadataValues = new bytes[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
            metadataValues[i] = abi.encodePacked("test", i);
        }

        vm.expectRevert("Pausable: paused");
        registry.setHintsDelegated(peterAddress, list, keys, values, metadataValues);

        for (uint i = 0; i < 10; i++) {
            bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, keys[i], values[i]));
            assertEq(registry.metadata(hintLocationHashEntry), "");
        }
    }

    // SET HINTS WITH METADATA DELEGATED SIGNED

    function test_SetHintsWithMetadataDelegatedSigned() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(address(0));

        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);
        bytes[] memory metadataValues = new bytes[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
            metadataValues[i] = abi.encodePacked("test", i);
        }

        bytes32 digest = sig712.getSetHintsDelegatedWithMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntries(peterAddress, list, keys, values, metadataValues),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        registry.setHintsDelegatedSigned(peterAddress, list, keys, values, metadataValues, marieAddress, signature);

        for (uint i = 0; i < 10; i++) {
            bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, keys[i], values[i]));
            assertEq(registry.metadata(hintLocationHashEntry), metadataValues[i]);
        }
        assertEq(registry.nonces(marieAddress), 1);
    }

    function test_RevertSetHintsWithMetadataDelegatedSignedIfWrongSigner() public {
        vm.prank(marieAddress);

        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);
        bytes[] memory metadataValues = new bytes[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
            metadataValues[i] = abi.encodePacked("test", i);
        }

        bytes32 digest = sig712.getSetHintsDelegatedWithMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntries(peterAddress, list, keys, values, metadataValues),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not a delegate");
        registry.setHintsDelegatedSigned(peterAddress, list, keys, values, metadataValues, marieAddress, signature);

        for (uint i = 0; i < 10; i++) {
            bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, keys[i], values[i]));
            assertEq(registry.metadata(hintLocationHashEntry), "");
        }
        assertEq(registry.nonces(marieAddress), 0);
    }

    function test_RevertSetHintsWithMetadataDelegatedSignedIfPaused() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(address(0));
        registry.pause();

        vm.prank(marieAddress);

        bytes32[] memory keys = new bytes32[](10);
        bytes32[] memory values = new bytes32[](10);
        bytes[] memory metadataValues = new bytes[](10);

        for (uint i = 0; i < 10; i++) {
            keys[i] = keccak256(abi.encodePacked("key", i));
            values[i] = keccak256(abi.encodePacked("value", i));
            metadataValues[i] = abi.encodePacked("test", i);
        }

        bytes32 digest = sig712.getSetHintsDelegatedWithMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntries(peterAddress, list, keys, values, metadataValues),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.setHintsDelegatedSigned(peterAddress, list, keys, values, metadataValues, marieAddress, signature);

        for (uint i = 0; i < 10; i++) {
            bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, keys[i], values[i]));
            assertEq(registry.metadata(hintLocationHashEntry), "");
        }
        assertEq(registry.nonces(marieAddress), 0);
    }

    ///////////////////// METADATA-ACTION ONLY TEST /////////////////////

    // SET METADATA

    function test_SetMetadata() public {
        vm.prank(namespace);

        registry.setMetadata(namespace, list, key, value, metadata);

        assertEq(registry.metadata(hintLocationHash), metadata);
    }

    function test_RevertSetMetadataIfNotOwner() public {
        vm.prank(address(999999));

        vm.expectRevert("Caller is not an owner");
        registry.setMetadata(namespace, list, key, value, metadata);

        assertEq(registry.metadata(hintLocationHash), "");
    }

    function test_RevertSetMetadataIfPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(namespace);

        vm.expectRevert("Pausable: paused");
        registry.setMetadata(namespace, list, key, value, metadata);

        assertEq(registry.metadata(hintLocationHash), "");
    }

    // SET METADATA SIGNED

    function test_SetMetadataSigned() public {
        vm.prank(address(999999));

        bytes32 digest = sig712.getSetMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        registry.setMetadataSigned(peterAddress, list, key, value, metadata, peterAddress, signature);

        bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(hintLocationHashEntry), metadata);
        assertEq(registry.nonces(peterAddress), 1);
        assertEq(registry.nonces(address(999999)), 0);
    }

    function test_RevertSetMetadataSignedIfWrongOwner() public {
        vm.prank(address(999999));

        bytes32 digest = sig712.getSetMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setMetadataSigned(peterAddress, list, key, value, metadata, marieAddress, signature);

        bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(hintLocationHashEntry), "");
        assertEq(registry.nonces(marieAddress), 0);
        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertSetMetadataSignedIfPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(999999));

        bytes32 digest = sig712.getSetMetadataTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            peterAddress,
            registry.nonces(peterAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.setMetadataSigned(peterAddress, list, key, value, metadata, peterAddress, signature);

        bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(hintLocationHashEntry), "");
        assertEq(registry.nonces(peterAddress), 0);
    }

    // SET METADATA DELEGATED

    function test_SetMetadataDelegated() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(marieAddress);
        registry.setMetadataDelegated(peterAddress, list, key, value, metadata);

        bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(hintLocationHashEntry), metadata);
    }

    function test_RevertSetMetadataDelegatedIfNotDelegate() public {
        vm.prank(marieAddress);
        vm.expectRevert("Caller is not a delegate");
        registry.setMetadataDelegated(peterAddress, list, key, value, metadata);

        bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(hintLocationHashEntry), "");
    }

    function test_RevertSetMetadataDelegatedIfPaused() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(address(0));
        registry.pause();

        vm.prank(marieAddress);
        vm.expectRevert("Pausable: paused");
        registry.setMetadataDelegated(peterAddress, list, key, value, metadata);

        bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(hintLocationHashEntry), "");
    }

    // SET METADATA DELEGATED SIGNED

    function test_SetMetadataDelegatedSigned() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(address(0));
        bytes32 digest = sig712.getSetMetadataDelegatedTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        registry.setMetadataDelegatedSigned(peterAddress, list, key, value, metadata, marieAddress, signature);

        bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(hintLocationHashEntry), metadata);
        assertEq(registry.nonces(marieAddress), 1);
    }

    function test_RevertSetMetadataDelegatedSignedIfWrongSigner() public {
        vm.prank(marieAddress);
        bytes32 digest = sig712.getSetMetadataDelegatedTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not a delegate");
        registry.setMetadataDelegatedSigned(peterAddress, list, key, value, metadata, marieAddress, signature);

        bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(hintLocationHashEntry), "");
        assertEq(registry.nonces(marieAddress), 0);
    }

    function test_RevertSetMetadataDelegatedSignedIfPaused() public {
        vm.prank(peterAddress);
        registry.addListDelegate(peterAddress, list, marieAddress, 99999999);

        vm.prank(address(0));
        registry.pause();

        vm.prank(marieAddress);
        bytes32 digest = sig712.getSetMetadataDelegatedTypedDataHash(
            Sig712Utils.HintMetadataEntry(peterAddress, list, key, value, metadata),
            marieAddress,
            registry.nonces(marieAddress)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.setMetadataDelegatedSigned(peterAddress, list, key, value, metadata, marieAddress, signature);

        bytes32 hintLocationHashEntry = keccak256(abi.encodePacked(peterAddress, list, key, value));
        assertEq(registry.metadata(hintLocationHashEntry), "");
        assertEq(registry.nonces(marieAddress), 0);
    }
}
