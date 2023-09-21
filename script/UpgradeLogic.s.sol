// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/TrustedHintRegistry.sol";

contract UpgradeLogic is Script {
    address proxy = vm.envAddress("ETH_PROXY_ADDRESS");
    TrustedHintRegistry wrappedProxy = TrustedHintRegistry(address(proxy));

    function run() public {
        vm.startBroadcast();
        TrustedHintRegistry implementationNew = new TrustedHintRegistry();
        wrappedProxy.upgradeTo(address(implementationNew));

        // Wrap in ABI to support easier calls
        TrustedHintRegistry wrappedProxyNew = TrustedHintRegistry(address(proxy));
        wrappedProxyNew.updateVersion();
        vm.stopBroadcast();

        console.log("Chain ID: ", block.chainid);
        console.log("TX Sender: ", msg.sender);
        console.log("New Logic Address: ", address(implementationNew));
        console.log("Proxy Address: ", proxy);
        console.log("Contract Version: ", wrappedProxyNew.version());
    }
}
