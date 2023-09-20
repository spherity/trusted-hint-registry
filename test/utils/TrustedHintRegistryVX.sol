// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract TrustedHintRegistryVX is Initializable, EIP712Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    mapping(address => mapping(bytes32 => mapping(bytes32 => bytes32))) hints;
    mapping(bytes32 => mapping(address => uint256)) public delegates;
    mapping(bytes32 => address) public newOwners;
    mapping(address => uint256) public nonces;
    mapping(bytes32 => bool) public revokedLists;

    string public VERSION_MAJOR;
    string public VERSION_MINOR;
    string public VERSION_PATCH;
    string public VERSION_DELIMITER;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        VERSION_MAJOR = "X";
        VERSION_MINOR = "X";
        VERSION_PATCH = "X";
        VERSION_DELIMITER = ".";
        __EIP712_init("TrustedHintRegistry", version());
    }

    function updateVersion() reinitializer(2) public {
        VERSION_MAJOR = "1";
        VERSION_MINOR = "1";
        VERSION_PATCH = "0";
        __EIP712_init("TrustedHintRegistry", version());
    }

    function test() public pure returns (bool) {
        return true;
    }

    function version() public view returns (string memory) {
        return string.concat(VERSION_MAJOR, VERSION_DELIMITER, VERSION_MINOR, VERSION_DELIMITER, VERSION_PATCH);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

}