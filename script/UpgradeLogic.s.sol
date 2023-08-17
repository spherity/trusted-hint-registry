// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/TrustedIssuerRegistry.sol";
import "../src/TrustedIssuerRegistry2.sol";

contract UpgradeLogic is Script {
    address proxy = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    TrustedIssuerRegistry wrappedProxyV1 = TrustedIssuerRegistry(address(proxy));
    TrustedIssuerRegistry2 wrappedProxyV2;

    function run() public {
        vm.startBroadcast();
        TrustedIssuerRegistry2 implementationV2 = new TrustedIssuerRegistry2();
        wrappedProxyV1.upgradeTo(address(implementationV2));

        wrappedProxyV2 = TrustedIssuerRegistry2(address(proxy));
        wrappedProxyV2.setTrusted("test2", "test2", true);
        vm.stopBroadcast();

        console.log(msg.sender);
        console.log("Contract Version: ", wrappedProxyV2.version());
        console.log("New Logic: ", address(implementationV2));
    }
}