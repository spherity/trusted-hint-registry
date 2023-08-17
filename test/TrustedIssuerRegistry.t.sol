// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { TrustedIssuerRegistry } from "../src/TrustedIssuerRegistry.sol";

contract TrustedIssuerRegistryTest is Test {
    TrustedIssuerRegistry public registry;
    string private did = "did:example:123";
    string private context = "https://www.w3.org/2018/credentials/v1";

    event TrustedIssuerUpdate(string indexed _context, string indexed _did, bool _trusted);

    function setUp() public {
        // Owner of this contract is address(0)!
        registry = new TrustedIssuerRegistry();
    }

    function test_Did1IsUnTrusted() public {
        assertEq(registry.isTrusted(context, did), false);
    }

    function test_SetTrustedToTrue() public {
        vm.prank(address(0));
        vm.expectEmit(true, true, false, true, address(registry));
        emit TrustedIssuerUpdate(context, did, true);

        registry.setTrusted(context, did, true);
        assertEq(registry.isTrusted(context, did), true);
        assertEq(registry.isTrusted("randomcontext", did), false);
    }
}
