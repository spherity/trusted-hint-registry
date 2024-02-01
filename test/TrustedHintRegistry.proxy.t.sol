// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { console, Test } from "forge-std/Test.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { TrustedHintRegistry } from "../src/TrustedHintRegistry.sol";
import { TrustedHintRegistryVX } from "./utils/TrustedHintRegistryVX.sol";

/*
* @notice Test proxy functionality of TrustedHintRegistry
*/
contract ProxyTest is Test {
    function test_ShouldDeployImplementationAndProxy() public {
        TrustedHintRegistry implementation = new TrustedHintRegistry();
        bytes memory data = abi.encodeCall(TrustedHintRegistry.initialize, ());
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);

        // wrap in ABI to support easier calls
        TrustedHintRegistry wrappedProxy = TrustedHintRegistry(address(proxy));
        (,string memory name, string memory version,, address verifyingContract,,) = wrappedProxy.eip712Domain();

        assertEq(wrappedProxy.version(), "1.0.0");
        assertEq(verifyingContract, address(proxy));
        assertEq(name, "TrustedHintRegistry");
        assertEq(version, "1.0.0");
    }

    function test_ShouldUpgradeProxyImplementation() public {
        TrustedHintRegistry implementation = new TrustedHintRegistry();
        bytes memory data = abi.encodeCall(TrustedHintRegistry.initialize, ());
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);

        // wrap in ABI to support easier calls
        TrustedHintRegistry wrappedProxy = TrustedHintRegistry(address(proxy));
        (,string memory name, string memory version,, address verifyingContract,,) = wrappedProxy.eip712Domain();

        assertEq(wrappedProxy.version(), "1.0.0");
        assertEq(verifyingContract, address(proxy));
        assertEq(name, "TrustedHintRegistry");
        assertEq(version, "1.0.0");

        console.log("version: %s", wrappedProxy.version());

        // Upgrade implementation
        TrustedHintRegistryVX implementationVX = new TrustedHintRegistryVX();
        wrappedProxy.upgradeTo(address(implementationVX));

        // wrap in ABI to support easier calls
        TrustedHintRegistryVX wrappedProxyVX = TrustedHintRegistryVX(address(proxy));
        wrappedProxyVX.updateVersion();

        (,string memory nameVX, string memory versionVX,, address verifyingContractVX,,) = wrappedProxyVX.eip712Domain();

        assertEq(wrappedProxyVX.version(), "1.1.0");
        assertEq(wrappedProxyVX.test(), true);
        assertEq(verifyingContractVX, address(proxy));
        assertEq(nameVX, "TrustedHintRegistry");
        assertEq(versionVX, "1.1.0");
    }
}