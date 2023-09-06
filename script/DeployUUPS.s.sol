// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/TrustedHintRegistry.sol";

contract DeployUUPS is Script {
    ERC1967Proxy proxy;
    TrustedHintRegistry wrappedProxyV1;

    function run() public {
        vm.startBroadcast();
        TrustedHintRegistry implementationV1 = new TrustedHintRegistry();

        // deploy proxy contract and point it to implementation
        proxy = new ERC1967Proxy(address(implementationV1), "");

        wrappedProxyV1 = TrustedHintRegistry(address(proxy));
        wrappedProxyV1.initialize();
        vm.stopBroadcast();

        console.log(msg.sender);
        console.log("Contract Version: ", wrappedProxyV1.version());
        console.log("Proxy: ", address(proxy));
        console.log("Logic: ", address(implementationV1));
    }
}