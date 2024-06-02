// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { Script, console } from "forge-std/Script.sol";
import { ERC1967Proxy } from  "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { TrustedHintRegistry } from "../src/TrustedHintRegistry.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { BatchScript } from "forge-safe/BatchScript.sol";

contract UpgradeLogic is Script, BatchScript {
    function run() public {
        // Get instance of already deployed proxy contract
        address proxy = 0x90E6A36D8091E4A94Ec67E95f5D94f715A27C8F3;//vm.envAddress("ETH_PROXY_ADDRESS");
        TrustedHintRegistry wrappedProxy = TrustedHintRegistry(address(proxy));

        // Deploy new implementation in _memory_ to compare versions later on
        TrustedHintRegistry newImplementationTest = new TrustedHintRegistry();
        //newImplementationTest.updateVersion();

        if (keccak256(abi.encodePacked(wrappedProxy.version()))
            == keccak256(abi.encodePacked(newImplementationTest.version()))) {
            console.log("!!!!!!!!!! Deployment skipped, version has not changed !!!!!!!!!!");
            return;
        }

        // Deploy new implementation and update proxy _on-chain_
        vm.startBroadcast();
        address safeAddress = 0x967fced2cb1aFb5f973816d2d643fE910B05df84;
        TrustedHintRegistry implementationNew = new TrustedHintRegistry();
        //wrappedProxy.upgradeTo(address(implementationNew));
        /*
            bytes memory upgradeTxn = abi.encodeWithSelector(
            UUPSUpgradeable.upgradeTo.selector,
            address(implementationNew)
        );
        bytes memory updateVersionTxn = abi.encodeWithSelector(
            TrustedHintRegistry.updateVersion.selector,
            address(implementationNew)
        );*/
        bytes memory upgradeTxn = abi.encodeWithSelector(
            TrustedHintRegistry.version.selector
        );
        addToBatch(proxy, upgradeTxn);
        executeBatch(safeAddress, false);

        // Wrap in ABI to support easier calls
        TrustedHintRegistry wrappedProxyNew = TrustedHintRegistry(address(proxy));
        //wrappedProxyNew.updateVersion();
        vm.stopBroadcast();

        console.log("Chain ID: ", block.chainid);
        console.log("TX Sender: ", msg.sender);
        console.log("New Logic Address: ", address(implementationNew));
        console.log("Proxy Address: ", proxy);
        console.log("Contract Version: ", wrappedProxyNew.version());
    }
}
