// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { console, Test } from "forge-std/Test.sol";
import { TrustedHintRegistry } from "../src/TrustedHintRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Events } from "./utils/Events.sol";

/*
* @notice Test OCI specific methods
*/
contract OCITest is Test, Events {
    TrustedHintRegistry internal registry;
    address internal peterAddress;
    uint256 internal peterPrivateKey;
    address internal marieAddress;
    uint256 internal mariePrivateKey;

    string internal constant IDENTITY_SCHEMA = "https://open-credentialing-initiative.github.io/schemas/credentials/IdentityCredential-v1.0.0.jsonld";
    string internal constant ATP_SCHEMA = "https://open-credentialing-initiative.github.io/schemas/credentials/DSCSAAuthorityCredential-v1.0.0.jsonld";
    string internal constant DID = "did:example:123456789abcdefghi";

    bytes32 internal constant BYTES32_TRUE = 0x1000000000000000000000000000000000000000000000000000000000000000;
    bytes32 internal constant BYTES32_FALSE = 0x0000000000000000000000000000000000000000000000000000000000000000;

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

    function test_IsTrustedIssuer() public {
        address namespace = address(1);
        bytes32 list = keccak256(abi.encodePacked(ATP_SCHEMA));
        bytes32 key = keccak256(abi.encodePacked(DID));

        vm.startPrank(namespace);
        registry.setHint(namespace, list, key, BYTES32_TRUE);

        bool result = registry.isTrustedIssuer(namespace, ATP_SCHEMA, DID);
        assertEq(result, true);
    }

    function test_IsTrustedIssuer_False() public {
        address namespace = address(1);

        bool result = registry.isTrustedIssuer(namespace, ATP_SCHEMA, DID);
        assertEq(result, false);
    }

    function test_IsTrustedIssuer_False_InvalidSchema() public {
        address namespace = address(1);
        bytes32 list = keccak256(abi.encodePacked(ATP_SCHEMA));
        bytes32 key = keccak256(abi.encodePacked(DID));

        vm.startPrank(namespace);
        registry.setHint(namespace, list, key, BYTES32_TRUE);

        bool result = registry.isTrustedIssuer(namespace, IDENTITY_SCHEMA, DID);
        assertEq(result, false);
    }

    function test_IsTrustedIssuer_False_InvalidDID() public {
        address namespace = address(1);
        bytes32 list = keccak256(abi.encodePacked(ATP_SCHEMA));
        bytes32 key = keccak256(abi.encodePacked(DID));

        vm.startPrank(namespace);
        registry.setHint(namespace, list, key, BYTES32_TRUE);

        bool result = registry.isTrustedIssuer(namespace, ATP_SCHEMA, "did:wrong:nottrusted");
        assertEq(result, false);
    }

    function test_IsTrustedIssuer_False_InvalidNamespace() public {
        address namespace = address(1);
        bytes32 list = keccak256(abi.encodePacked(ATP_SCHEMA));
        bytes32 key = keccak256(abi.encodePacked(DID));

        vm.startPrank(namespace);
        registry.setHint(namespace, list, key, BYTES32_TRUE);

        bool result = registry.isTrustedIssuer(address(2), ATP_SCHEMA, DID);
        assertEq(result, false);
    }
}