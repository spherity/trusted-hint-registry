// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract TrustedHintRegistry is Initializable, EIP712Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    mapping(address => mapping(bytes32 => mapping(bytes32 => bytes32))) hints;
    mapping(bytes32 => mapping(address => uint256)) public delegates;
    mapping(bytes32 => address) public newOwners;
    mapping(address => uint256) public nonces;
    mapping(bytes32 => bool) public revokedLists;

    string public VERSION_MAJOR;
    string public VERSION_MINOR;
    string public VERSION_PATCH;
    string public VERSION_DELIMITER;

    function initialize() initializer public {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        VERSION_MAJOR = "1";
        VERSION_MINOR = "0";
        VERSION_PATCH = "0";
        VERSION_DELIMITER = ".";
        __EIP712_init("TrustedHintRegistry", version());
    }

    ///////////////  HINT MANAGEMENT  ///////////////

    /**
      * @notice Returns a hint value
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _key Bytes32 key identifier for hint value
      * @return hint value
    */
    function getHint(address _namespace, bytes32 _list, bytes32 _key) external view returns (bytes32) {
        return hints[_namespace][_list][_key];
    }

    /**
      * @dev Internal function to change a hint value
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _key Bytes32 key identifier for hint value
      * @param _value New bytes32 hint value
    */
    function _setHint(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value) internal {
        hints[_namespace][_list][_key] = _value;
        emit HintValueChanged(_namespace, _list, _key, _value);
    }

    /**
      * @notice Change a hint value
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _key Bytes32 key identifier for hint value
      * @param _value New bytes32 hint value
    */
    function setHint(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value) public isOwner(_namespace, _list) whenNotPaused {
        _setHint(_namespace, _list, _key, _value);
    }

    /**
      * @notice Change a hint value with a raw signature
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _key Bytes32 key identifier for hint value
      * @param _value New bytes32 hint value
      * @param _signer Address of signature creator
      * @param _signature Raw signature create according to EIP-712
    */
    function setHintSigned(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value, address _signer, bytes calldata _signature) public whenNotPaused {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("SetHintSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,address signer,uint256 nonce)"),
            _namespace,
            _list,
            _key,
            _value,
            _signer,
            nonces[_signer]
        )));
        address recoveredSigner = ECDSAUpgradeable.recover(hash, _signature);
        require(identityIsOwner(_namespace, _list, recoveredSigner), "Signer is not an owner");
        nonces[recoveredSigner]++;
        _setHint(_namespace, _list, _key, _value);
    }


    /**
      * @dev Internal function to change multiple hint values
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _keys List of bytes32 key identifiers
      * @param _values List of new bytes32 hint values
    */
    function _setHints(address _namespace, bytes32 _list, bytes32[] calldata _keys, bytes32[] calldata _values) internal {
        for (uint i = 0; i < _keys.length; i++) {
            _setHint(_namespace, _list, _keys[i], _values[i]);
        }
    }


    /**
      * @notice Change multiple hint values inside a hint list
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _keys List of bytes32 key identifiers
      * @param _values List of new bytes32 hint values
    */
    function setHints(address _namespace, bytes32 _list, bytes32[] calldata _keys, bytes32[] calldata _values) public isOwner(_namespace, _list) whenNotPaused {
        _setHints(_namespace, _list, _keys, _values);
    }

    /**
      * @notice Change multiple hint values inside a hint list with a raw signature
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _keys List of bytes32 key identifiers
      * @param _values List of new bytes32 hint values
      * @param _signer Address of signature creator
      * @param _signature Raw signature create according to EIP-712
    */
    function setHintsSigned(address _namespace, bytes32 _list, bytes32[] calldata _keys, bytes32[] calldata _values, address _signer, bytes calldata _signature) public whenNotPaused {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("SetHintsSigned(address namespace,bytes32 list,bytes32[] keys,bytes32[] values,address signer,uint256 nonce)"),
            _namespace,
            _list,
            keccak256(abi.encodePacked(_keys)),
            keccak256(abi.encodePacked(_values)),
            _signer,
            nonces[_signer]
        )));
        address recoveredSigner = ECDSAUpgradeable.recover(hash, _signature);
        require(identityIsOwner(_namespace, _list, recoveredSigner), "Signer is not an owner");
        nonces[recoveredSigner]++;
        _setHints(_namespace, _list, _keys, _values);
    }

    ///////////////  DELEGATED MANAGEMENT  ///////////////

    function setHintDelegated(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value) public isDelegate(_namespace, _list) whenNotPaused {
        _setHint(_namespace, _list, _key, _value);
    }

    function addListDelegate(address _namespace, bytes32 _list, address _delegate, uint256 _untilTimestamp) public isOwner(_namespace, _list) whenNotPaused {
        require(_untilTimestamp > block.timestamp, "Timestamp must be in the future");
        delegates[generateListLocationHash(_namespace, _list)][_delegate] = _untilTimestamp;
        emit HintListDelegateAdded(_namespace, _list, _delegate);
    }

    function version() public view returns (string memory) {
        return string.concat(VERSION_MAJOR, VERSION_DELIMITER, VERSION_MINOR, VERSION_DELIMITER, VERSION_PATCH);
    }

    // Misc

    function generateListLocationHash(address _namespace, bytes32 _list) pure internal returns (bytes32) {
        return keccak256(abi.encodePacked(_namespace, _list));
    }

    function identityIsOwner(address _namespace, bytes32 _list, address _identity) view public returns (bool) {
        bytes32 listLocationHash = generateListLocationHash(_namespace, _list);
        if (newOwners[listLocationHash] == address(0) && _identity == _namespace) {
            return true;
        } else if (newOwners[listLocationHash] == _identity) {
            return true;
        }
        return false;
    }

    function identityIsDelegate(address _namespace, bytes32 _list, address _identity) view public returns (bool) {
        bytes32 listLocationHash = generateListLocationHash(_namespace, _list);
        if (delegates[listLocationHash][_identity] > block.timestamp) {
            return true;
        }
        return false;
    }

    modifier isOwner(address _namespace, bytes32 _list) {
        require(identityIsOwner(_namespace, _list, msg.sender), "Caller is not an owner");
        _;
    }

    modifier isDelegate(address _namespace, bytes32 _list) {
        require(identityIsDelegate(_namespace, _list, msg.sender), "Caller is not a delegate");
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    // Events

    event HintValueChanged(
        address indexed namespace,
        bytes32 indexed list,
        bytes32 indexed key,
        bytes32 value
    );

    event HintListDelegateAdded(
        address indexed namespace,
        bytes32 indexed list,
        address indexed newDelegate
    );
}