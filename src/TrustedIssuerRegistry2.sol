pragma solidity >=0.8.0 <0.9.0;

import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract TrustedIssuerRegistry2 is Initializable, EIP712Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    string public VERSION_MAJOR;
    string public VERSION_MINOR;
    string public VERSION_PATCH;
    string internal VERSION_DELIMITER;

    mapping(bytes32 => bool) public trusted;

    function initialize() initializer public {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        VERSION_MAJOR = "1";
        VERSION_MINOR = "0";
        VERSION_PATCH = "1";
        VERSION_DELIMITER = ".";
        __EIP712_init("TIR", version());
    }

    function isTrusted(string calldata _context, string calldata _did) external view returns (bool) {
        return trusted[keccak256(abi.encodePacked(_context, _did))];
    }

    function setTrusted(string calldata _context, string calldata _did, bool _trusted) public onlyOwner {
        trusted[keccak256(abi.encodePacked(_context, _did))] = _trusted;
        emit TrustedIssuerUpdate(_context, _did, _trusted);
    }

    function version() public view returns (string memory) {
        return string.concat(VERSION_MAJOR, VERSION_DELIMITER, VERSION_MINOR, VERSION_DELIMITER, VERSION_PATCH);
    }

    function wow() public view returns (bool) {
        return true;
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    event TrustedIssuerUpdate(string indexed _context, string indexed _did, bool _trusted);
}