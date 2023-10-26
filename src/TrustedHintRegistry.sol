// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TrustedHintRegistry is Initializable, EIP712Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    mapping(address => mapping(bytes32 => mapping(bytes32 => bytes32))) hints;
    mapping(bytes32 => mapping(address => uint256)) public delegates;
    mapping(bytes32 => address) public newOwners;
    mapping(address => uint256) public nonces;
    mapping(bytes32 => bool) public revokedLists;
    mapping(bytes32 => bytes) public metadata;

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
        VERSION_MAJOR = "1";
        VERSION_MINOR = "0";
        VERSION_PATCH = "0";
        VERSION_DELIMITER = ".";
        __EIP712_init("TrustedHintRegistry", version());
    }

    /**
      * Implement method for subsequent upgrades; has to be called via proxy after upgrade.
      * increase reinitializer counter by 1 for each new implementation.
      *  function updateVersion() reinitializer(1) public {
      *      VERSION_MAJOR = "X";
      *      VERSION_MINOR = "X";
      *      VERSION_PATCH = "X";
      *      VERSION_DELIMITER = ".";
      *      __EIP712_init("TrustedHintRegistry", version());
      *  }
    */

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
      * @notice Change a hint value with metadata
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _key Bytes32 key identifier for hint value
      * @param _value New bytes32 hint value
      * @param _metadata New metdata value
    */
    function setHint(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value, bytes calldata _metadata) public isOwner(_namespace, _list) whenNotPaused {
        _setHint(_namespace, _list, _key, _value);
        metadata[generateValueLocationHash(_namespace, _list, _key, _value)] = _metadata;
    }

    /**
      * @notice Change a hint value with a raw signature
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _key Bytes32 key identifier for hint value
      * @param _value New bytes32 hint value
      * @param _signer Address of signature creator
      * @param _signature Raw signature created according to EIP-712
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
      * @notice Change a hint value with a raw signature and metadata
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _key Bytes32 key identifier for hint value
      * @param _value New bytes32 hint value
      * @param _metadata New bytes metdata value
      * @param _signer Address of signature creator
      * @param _signature Raw signature created according to EIP-712
    */
    function setHintSigned(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value, bytes calldata _metadata, address _signer, bytes calldata _signature) public whenNotPaused {
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
        metadata[generateValueLocationHash(_namespace, _list, _key, _value)] = _metadata;
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
      * @dev Internal function to change multiple hint values with metadata
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _keys List of bytes32 key identifiers
      * @param _values List of new bytes32 hint values
    */
    function _setHints(address _namespace, bytes32 _list, bytes32[] calldata _keys, bytes32[] calldata _values, bytes[] calldata _metadata) internal {
        for (uint i = 0; i < _keys.length; i++) {
            _setHint(_namespace, _list, _keys[i], _values[i]);
            metadata[generateValueLocationHash(_namespace, _list, _keys[i], _values[i])] = _metadata[i];
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
      * @notice Change multiple hint values inside a hint list
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _keys List of bytes32 key identifiers
      * @param _values List of new bytes32 hint values
      * @param _metadata List of new metadata values
    */
    function setHints(address _namespace, bytes32 _list, bytes32[] calldata _keys, bytes32[] calldata _values, bytes[] calldata _metadata) public isOwner(_namespace, _list) whenNotPaused {
        _setHints(_namespace, _list, _keys, _values, _metadata);
    }

    /**
      * @notice Change multiple hint values inside a hint list with a raw signature
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _keys List of bytes32 key identifiers
      * @param _values List of new bytes32 hint values
      * @param _signer Address of signature creator
      * @param _signature Raw signature created according to EIP-712
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

    /**
      * @notice Change multiple hint values inside a hint list with a raw signature
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _keys List of bytes32 key identifiers
      * @param _values List of new bytes32 hint values
      * @param _metadata List of new metadata values
      * @param _signer Address of signature creator
      * @param _signature Raw signature created according to EIP-712
    */
    function setHintsSigned(address _namespace, bytes32 _list, bytes32[] calldata _keys, bytes32[] calldata _values, bytes[] calldata _metadata, address _signer, bytes calldata _signature) public whenNotPaused {
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
        _setHints(_namespace, _list, _keys, _values, _metadata);
    }

    ///////////////  DELEGATED MANAGEMENT  ///////////////

    /**
      * @notice Change a hint value as a delegate
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _key Bytes32 key identifier for hint value
      * @param _value New bytes32 hint value
    */
    function setHintDelegated(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value) public isDelegate(_namespace, _list) whenNotPaused {
        _setHint(_namespace, _list, _key, _value);
    }

    /**
      * @notice Change a hint value as a delegate
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _key Bytes32 key identifier for hint value
      * @param _value New bytes32 hint value
      * @param _metadata New metadata value
    */
    function setHintDelegated(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value, bytes calldata _metadata) public isDelegate(_namespace, _list) whenNotPaused {
        _setHint(_namespace, _list, _key, _value);
        metadata[generateValueLocationHash(_namespace, _list, _key, _value)] = _metadata;
    }

    /**
      * @notice Change a hint value with a raw signature from a delegate
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _key Bytes32 key identifier for hint value
      * @param _value New bytes32 hint value
      * @param _signer Address of signature creator
      * @param _signature Raw signature created according to EIP-712
    */
    function setHintDelegatedSigned(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value, address _signer, bytes calldata _signature) public whenNotPaused {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("SetHintDelegatedSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,address signer,uint256 nonce)"),
            _namespace,
            _list,
            _key,
            _value,
            _signer,
            nonces[_signer]
        )));
        address recoveredSigner = ECDSAUpgradeable.recover(hash, _signature);
        require(identityIsDelegate(_namespace, _list, recoveredSigner), "Signer is not a delegate");
        nonces[recoveredSigner]++;
        _setHint(_namespace, _list, _key, _value);
    }

    /**
      * @notice Change a hint value with a raw signature from a delegate
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _key Bytes32 key identifier for hint value
      * @param _value New bytes32 hint value
      * @param _metadata New metadata value
      * @param _signer Address of signature creator
      * @param _signature Raw signature created according to EIP-712
    */
    function setHintDelegatedSigned(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value, bytes calldata _metadata, address _signer, bytes calldata _signature) public whenNotPaused {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("SetHintDelegatedSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,address signer,uint256 nonce)"),
            _namespace,
            _list,
            _key,
            _value,
            _signer,
            nonces[_signer]
        )));
        address recoveredSigner = ECDSAUpgradeable.recover(hash, _signature);
        require(identityIsDelegate(_namespace, _list, recoveredSigner), "Signer is not a delegate");
        nonces[recoveredSigner]++;
        _setHint(_namespace, _list, _key, _value);
        metadata[generateValueLocationHash(_namespace, _list, _key, _value)] = _metadata;
    }

    /**
      * @dev Change multiple hint values inside a hint list as a delegate
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _keys List of bytes32 key identifiers
      * @param _values List of new bytes32 hint values
    */
    function setHintsDelegated(address _namespace, bytes32 _list, bytes32[] calldata _keys, bytes32[] calldata _values) public isDelegate(_namespace, _list) whenNotPaused {
        _setHints(_namespace, _list, _keys, _values);
    }

    /**
      * @dev Change multiple hint values inside a hint list as a delegate
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _keys List of bytes32 key identifiers
      * @param _values List of new bytes32 hint values
      * @param _metadata List of new metadata values
    */
    function setHintsDelegated(address _namespace, bytes32 _list, bytes32[] calldata _keys, bytes32[] calldata _values, bytes[] calldata _metadata) public isDelegate(_namespace, _list) whenNotPaused {
        _setHints(_namespace, _list, _keys, _values, _metadata);
    }

    /**
      * @notice Change multiple hint values inside a hint list with a raw signature from a delegate
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _keys List of bytes32 key identifiers
      * @param _values List of new bytes32 hint values
      * @param _signer Address of signature creator
      * @param _signature Raw signature created according to EIP-712
    */
    function setHintsDelegatedSigned(address _namespace, bytes32 _list, bytes32[] calldata _keys, bytes32[] calldata _values, address _signer, bytes calldata _signature) public whenNotPaused {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("SetHintsDelegatedSigned(address namespace,bytes32 list,bytes32[] keys,bytes32[] values,address signer,uint256 nonce)"),
            _namespace,
            _list,
            keccak256(abi.encodePacked(_keys)),
            keccak256(abi.encodePacked(_values)),
            _signer,
            nonces[_signer]
        )));
        address recoveredSigner = ECDSAUpgradeable.recover(hash, _signature);
        require(identityIsDelegate(_namespace, _list, recoveredSigner), "Signer is not a delegate");
        nonces[recoveredSigner]++;
        _setHints(_namespace, _list, _keys, _values);
    }

    /**
      * @notice Change multiple hint values inside a hint list with a raw signature from a delegate
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _keys List of bytes32 key identifiers
      * @param _values List of new bytes32 hint values
      * @param _metadata List of new metadata values
      * @param _signer Address of signature creator
      * @param _signature Raw signature created according to EIP-712
    */
    function setHintsDelegatedSigned(address _namespace, bytes32 _list, bytes32[] calldata _keys, bytes32[] calldata _values, bytes[] calldata _metadata, address _signer, bytes calldata _signature) public whenNotPaused {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("SetHintsDelegatedSigned(address namespace,bytes32 list,bytes32[] keys,bytes32[] values,address signer,uint256 nonce)"),
            _namespace,
            _list,
            keccak256(abi.encodePacked(_keys)),
            keccak256(abi.encodePacked(_values)),
            _signer,
            nonces[_signer]
        )));
        address recoveredSigner = ECDSAUpgradeable.recover(hash, _signature);
        require(identityIsDelegate(_namespace, _list, recoveredSigner), "Signer is not a delegate");
        nonces[recoveredSigner]++;
        _setHints(_namespace, _list, _keys, _values, _metadata);
    }

    ///////////////  LIST MANAGEMENT  ///////////////

    /**
      * @notice Change the status of a hint list
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _revoked New status of hint list
    */
    function _setListStatus(address _namespace, bytes32 _list, bool _revoked) internal {
        revokedLists[generateListLocationHash(_namespace, _list)] = _revoked;
        emit HintListStatusChanged(_namespace, _list, true);
    }

    /**
      * @notice Change the status of a hint list
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _revoked New status of hint list
    */
    function setListStatus(address _namespace, bytes32 _list, bool _revoked) public isOwner(_namespace, _list) whenNotPaused {
        _setListStatus(_namespace, _list, _revoked);
    }

    /**
      * @notice Change the status of a hint list with a raw signature
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _revoked New status of hint list
      * @param _signer Address of signature creator
      * @param _signature Raw signature created according to EIP-712
    */
    function setListStatusSigned(address _namespace, bytes32 _list, bool _revoked, address _signer, bytes calldata _signature) public whenNotPaused {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("SetListStatusSigned(address namespace,bytes32 list,bool revoked,address signer,uint256 nonce)"),
            _namespace,
            _list,
            _revoked,
            _signer,
            nonces[_signer]
        )));
        address recoveredSigner = ECDSAUpgradeable.recover(hash, _signature);
        require(identityIsOwner(_namespace, _list, recoveredSigner), "Signer is not an owner");
        nonces[recoveredSigner]++;
        _setListStatus(_namespace, _list, _revoked);
    }

    /**
      * @notice Internal method to change the owner of a hint list
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _newOwner Address of new owner
    */
    function _setListOwner(address _namespace, bytes32 _list, address _newOwner) internal {
        newOwners[generateListLocationHash(_namespace, _list)] = _newOwner;
        emit HintListOwnerChanged(_namespace, _list, _newOwner);
    }

    /**
      * @notice Change the owner of a hint list
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _newOwner Address of new owner
    */
    function setListOwner(address _namespace, bytes32 _list, address _newOwner) public isOwner(_namespace, _list) whenNotPaused {
        _setListOwner(_namespace, _list, _newOwner);
    }

    /**
      * @notice Change the owner of a hint list with a raw signature
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _newOwner Address of new owner
      * @param _signer Address of signature creator
      * @param _signature Raw signature created according to EIP-712
    */
    function setListOwnerSigned(address _namespace, bytes32 _list, address _newOwner, address _signer, bytes calldata _signature) public whenNotPaused {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("SetListOwnerSigned(address namespace,bytes32 list,address newOwner,address signer,uint256 nonce)"),
            _namespace,
            _list,
            _newOwner,
            _signer,
            nonces[_signer]
        )));
        address recoveredSigner = ECDSAUpgradeable.recover(hash, _signature);
        require(identityIsOwner(_namespace, _list, recoveredSigner), "Signer is not an owner");
        nonces[recoveredSigner]++;
        _setListOwner(_namespace, _list, _newOwner);
    }

    /**
      * @notice Internal method to add a delegate to a hint list
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _delegate Address of new delegate
      * @param _untilTimestamp Timestamp until which the delegate is valid
    */
    function _addListDelegate(address _namespace, bytes32 _list, address _delegate, uint256 _untilTimestamp) internal {
        require(_untilTimestamp > block.timestamp, "Timestamp must be in the future");
        delegates[generateListLocationHash(_namespace, _list)][_delegate] = _untilTimestamp;
        emit HintListDelegateAdded(_namespace, _list, _delegate);
    }

    /**
      * @notice Add a delegate to a hint list
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _delegate Address of new delegate
      * @param _untilTimestamp Timestamp until which the delegate is valid
    */
    function addListDelegate(address _namespace, bytes32 _list, address _delegate, uint256 _untilTimestamp) public isOwner(_namespace, _list) whenNotPaused {
        _addListDelegate(_namespace, _list, _delegate, _untilTimestamp);
    }

    /**
      * @notice Add a delegate to a hint list with a raw signature
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _delegate Address of new delegate
      * @param _untilTimestamp Timestamp until which the delegate is valid
      * @param _signer Address of signature creator
      * @param _signature Raw signature created according to EIP-712
    */
    function addListDelegateSigned(address _namespace, bytes32 _list, address _delegate, uint256 _untilTimestamp, address _signer, bytes calldata _signature) public whenNotPaused {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("AddListDelegateSigned(address namespace,bytes32 list,address delegate,uint256 untilTimestamp,address signer,uint256 nonce)"),
            _namespace,
            _list,
            _delegate,
            _untilTimestamp,
            _signer,
            nonces[_signer]
        )));
        address recoveredSigner = ECDSAUpgradeable.recover(hash, _signature);
        require(identityIsOwner(_namespace, _list, recoveredSigner), "Signer is not an owner");
        nonces[recoveredSigner]++;
        _addListDelegate(_namespace, _list, _delegate, _untilTimestamp);
    }

    /**
      * @notice Internal method to remove a delegate from a hint list
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _delegate Address of new delegate
    */
    function _removeListDelegate(address _namespace, bytes32 _list, address _delegate) internal {
        delegates[generateListLocationHash(_namespace, _list)][_delegate] = 0;
        emit HintListDelegateRemoved(_namespace, _list, _delegate);
    }

    /**
      * @notice Remove a delegate from a hint list
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _delegate Address of new delegate
    */
    function removeListDelegate(address _namespace, bytes32 _list, address _delegate) public isOwner(_namespace, _list) whenNotPaused {
        _removeListDelegate(_namespace, _list, _delegate);
    }

    /**
      * @notice Remove a delegate from a hint list with a raw signature
      * @param _namespace Address namespace
      * @param _list Bytes32 list identifier
      * @param _delegate Address of new delegate
      * @param _signer Address of signature creator
      * @param _signature Raw signature created according to EIP-712
    */
    function removeListDelegateSigned(address _namespace, bytes32 _list, address _delegate, address _signer, bytes calldata _signature) public whenNotPaused {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("RemoveListDelegateSigned(address namespace,bytes32 list,address delegate,address signer,uint256 nonce)"),
            _namespace,
            _list,
            _delegate,
            _signer,
            nonces[_signer]
        )));
        address recoveredSigner = ECDSAUpgradeable.recover(hash, _signature);
        require(identityIsOwner(_namespace, _list, recoveredSigner), "Signer is not an owner");
        nonces[recoveredSigner]++;
        _removeListDelegate(_namespace, _list, _delegate);
    }

    ///////////////  METADATA  ///////////////

    function setHintMetadata(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value, bytes calldata _metadata) public isOwner(_namespace, _list) whenNotPaused {
        metadata[generateValueLocationHash(_namespace, _list, _key, _value)] = _metadata;
    }

    function setHintMetadataSigned(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value, bytes calldata _metadata, address _signer, bytes calldata _signature) public whenNotPaused {
        uint nonce = nonces[_signer];
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("SetHintMetadataSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,bytes metadata,address signer,uint256 nonce)"),
            _namespace,
            _list,
            _key,
            _value,
            _metadata,
            _signer,
           nonce
        )));
        address recoveredSigner = ECDSAUpgradeable.recover(hash, _signature);
        require(identityIsOwner(_namespace, _list, recoveredSigner), "Signer is not an owner");
        nonces[recoveredSigner]++;
        bytes32 locationHash = generateValueLocationHash(_namespace, _list, _key, _value);
        metadata[locationHash] = _metadata;
    }

    function setHintMetadataDelegated(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value, bytes calldata _metadata) public isDelegate(_namespace, _list) whenNotPaused {
        metadata[generateValueLocationHash(_namespace, _list, _key, _value)] = _metadata;
    }

    function setHintMetadataDelegatedSigned(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value, bytes calldata _metadata, address _signer, bytes calldata _signature) public whenNotPaused {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("SetHintMetadataDelegatedSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,bytes metadata,address signer,uint256 nonce)"),
            _namespace,
            _list,
            _key,
            _value,
            _metadata,
            _signer,
            nonces[_signer]
        )));
        address recoveredSigner = ECDSAUpgradeable.recover(hash, _signature);
        require(identityIsDelegate(_namespace, _list, recoveredSigner), "Signer is not a delegate");
        nonces[recoveredSigner]++;
        bytes32 locationHash = generateValueLocationHash(_namespace, _list, _key, _value);
        metadata[locationHash] = _metadata;
    }

    function setListMetadata(address _namespace, bytes32 _list, bytes calldata _metadata) public isOwner(_namespace, _list) whenNotPaused {
        metadata[generateListLocationHash(_namespace, _list)] = _metadata;
    }

    function setListMetadataSigned(address _namespace, bytes32 _list, bytes calldata _metadata, address _signer, bytes calldata _signature) public isOwner(_namespace, _list) whenNotPaused {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("SetListDelegatedSigned(address namespace,bytes32 list,bytes metadata,address signer,uint256 nonce)"),
            _namespace,
            _list,
            _metadata,
            _signer,
            nonces[_signer]
        )));
        address recoveredSigner = ECDSAUpgradeable.recover(hash, _signature);
        require(identityIsOwner(_namespace, _list, recoveredSigner), "Signer is not an owner");
        nonces[recoveredSigner]++;
        bytes32 locationHash = generateListLocationHash(_namespace, _list);
        metadata[locationHash] = _metadata;
    }

    function setListMetadataDelegated(address _namespace, bytes32 _list, bytes calldata _metadata) public isDelegate(_namespace, _list) whenNotPaused {
        metadata[generateListLocationHash(_namespace, _list)] = _metadata;
    }

    function setListMetadataDelegatedSigned(address _namespace, bytes32 _list, bytes calldata _metadata, address _signer, bytes calldata _signature) public whenNotPaused {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("SetListDelegatedSigned(address namespace,bytes32 list,bytes metadata,address signer,uint256 nonce)"),
            _namespace,
            _list,
            _metadata,
            _signer,
            nonces[_signer]
        )));
        address recoveredSigner = ECDSAUpgradeable.recover(hash, _signature);
        require(identityIsDelegate(_namespace, _list, recoveredSigner), "Signer is not a delegate");
        nonces[recoveredSigner]++;
        bytes32 locationHash = generateListLocationHash(_namespace, _list);
        metadata[locationHash] = _metadata;
    }

    ///////////////  MISC  ///////////////

    function version() public view returns (string memory) {
        return string.concat(VERSION_MAJOR, VERSION_DELIMITER, VERSION_MINOR, VERSION_DELIMITER, VERSION_PATCH);
    }

    function generateListLocationHash(address _namespace, bytes32 _list) pure internal returns (bytes32) {
        return keccak256(abi.encodePacked(_namespace, _list));
    }

    function generateValueLocationHash(address _namespace, bytes32 _list, bytes32 _key, bytes32 _value) pure internal returns (bytes32) {
        return keccak256(abi.encodePacked(_namespace, _list, _key, _value));
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

    ////////////////////////  EVENTS  ////////////////////////

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

    event HintListDelegateRemoved(
        address indexed namespace,
        bytes32 indexed list,
        address indexed oldDelegate
    );

    event HintListStatusChanged(
        address indexed namespace,
        bytes32 indexed list,
        bool indexed revoked
    );

    event HintListOwnerChanged(
        address indexed namespace,
        bytes32 indexed list,
        address indexed newOwner
    );
}