// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { Script, console } from "forge-std/Script.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { TrustedHintRegistry } from "../src/TrustedHintRegistry.sol";

contract DeployProxy is Script {
    ERC1967Proxy proxy;
    TrustedHintRegistry wrappedProxy;

    function run() public {
        vm.startBroadcast();
        // Deploy implementationq
        TrustedHintRegistry implementation = new TrustedHintRegistry();

        // Deploy proxy, reference implementation, and call initialize
        bytes memory data = abi.encodeCall(TrustedHintRegistry.initialize, ());
        proxy = new ERC1967Proxy(address(implementation), data);

        // Wrap proxy in ABI to support easier calls
        wrappedProxy = TrustedHintRegistry(address(proxy));

        address safeAddress = 0x967fced2cb1aFb5f973816d2d643fE910B05df84;
        wrappedProxy.transferOwnership(safeAddress);
        vm.stopBroadcast();

        console.log("Chain ID: ", block.chainid);
        console.log("TX Sender: ", msg.sender);
        console.log("Proxy Address: ", address(proxy));
        console.log("Proxy Owner: ", wrappedProxy.owner());
        console.log("Logic Address: ", address(implementation));
        console.log("Contract Version: ", wrappedProxy.version());
    }
}