// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";

contract DeployUUPS is Script {
    ERC1967UpgradeUpgradeable proxy;
    MyContract wrappedProxyV1;
    MyContractV2 wrappedProxyV2;

    function run() public {
        MyContract implementationV1 = new MyContract();

        // deploy proxy contract and point it to implementation
        proxy = new UUPSProxy(address(implementationV1), "");

        // wrap in ABI to support easier calls
        wrappedProxyV1 = MyContract(address(proxy));
        wrappedProxyV1.initialize(100);


        // expect 100
        console.log(wrappedProxyV1.x());

        // new implementation
        MyContractV2 implementationV2 = new MyContractV2();
        wrappedProxyV1.upgradeTo(address(implementationV2));

        wrappedProxyV2 = MyContractV2(address(proxy));
        wrappedProxyV2.setY(200);

        console.log(wrappedProxyV2.x(), wrappedProxyV2.y());
    }

}