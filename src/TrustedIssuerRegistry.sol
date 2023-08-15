pragma solidity >=0.8.0 <0.9.0;

import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/cryptography/EIP712Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

contract TrustedIssuerRegistry is Initializable, EIP712Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    mapping(bytes32 => bool) public trusted;

    string public VERSION_MAJOR;
    string public VERSION_MINOR;
    string public VERSION_PATCH;
    string internal VERSION_DELIMITER;

    function initialize() initializer public {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        VERSION_MAJOR = "1";
        VERSION_MINOR = "0";
        VERSION_PATCH = "0";
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

    event TrustedIssuerUpdate(string indexed _context, string indexed _did, bool _trusted);

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