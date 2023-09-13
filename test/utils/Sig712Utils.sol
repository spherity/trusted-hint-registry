// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/*
* @dev Utility contract to help with EIP712 signatures
*/
contract Sig712Utils {
    bytes32 internal DOMAIN_SEPARATOR;

    struct HintEntry {
        address namespace;
        bytes32 list;
        bytes32 key;
        bytes32 value;
    }

    struct HintsEntry {
        address namespace;
        bytes32 list;
        bytes32[] keys;
        bytes32[] values;
    }

    struct ListOwnerEntry {
        address namespace;
        bytes32 list;
        bool revoked;
    }

    enum MetaAction {
        SET_HINT,
        SET_HINTS,
        SET_HINT_DELEGATED,
        SET_HINTS_DELEGATED,
        SET_LIST_STATUS
    }

    constructor(string memory _contractVersion, address _contractAddress) {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
            // = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
            keccak256("TrustedHintRegistry"),
            keccak256(bytes(_contractVersion)),
            block.chainid,
            address(_contractAddress)
        ));
    }

    /*
    * @dev Get the hash of a MetaAction
    * @param _action MetaAction
    * @return Hash of the MetaAction
    */
    function getTypeHash(MetaAction _action) internal pure returns (bytes32) {
        if (_action == MetaAction.SET_HINT) {
            return keccak256("SetHintSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_HINTS) {
            return keccak256("SetHintsSigned(address namespace,bytes32 list,bytes32[] keys,bytes32[] values,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_HINT_DELEGATED) {
            return keccak256("SetHintDelegatedSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_HINTS_DELEGATED) {
            return keccak256("SetHintsDelegatedSigned(address namespace,bytes32 list,bytes32[] keys,bytes32[] values,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_LIST_STATUS) {
            return keccak256("SetListStatusSigned(address namespace,bytes32 list,bool revoked,address signer,uint256 nonce)");
        }
        revert("Invalid action");
    }


    ///////////////  SET HINT  ///////////////

    /*
    * @dev Get the struct hash for SetHint action
    * @param _hint HintEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHint action
    */
    function getSetHintStructHash(HintEntry calldata _hint, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_HINT),
            _hint.namespace,
            _hint.list,
            _hint.key,
            _hint.value,
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a SetHint action
    * @param _hint HintEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHint action
    */
    function getSetHintTypedDataHash(HintEntry calldata _hint, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetHintStructHash(_hint, _signer, _nonce)
            )
        );
    }

    ///////////////  SET HINTS  ///////////////

    /*
    * @dev Get the struct hash for SetHints action
    * @param _hints HintsEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHints action
    */
    function getSetHintsStructHash(HintsEntry calldata _hints, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_HINTS),
            _hints.namespace,
            _hints.list,
            keccak256(abi.encodePacked(_hints.keys)),
            keccak256(abi.encodePacked(_hints.values)),
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a SetHint action
    * @param _hints HintsEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHints action
    */
    function getSetHintsTypedDataHash(HintsEntry calldata _hints, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetHintsStructHash(_hints, _signer, _nonce)
            )
        );
    }

    ///////////////  SET HINT DELEGATED  ///////////////

    /*
    * @dev Get the struct hash for SetHintDelegated action
    * @param _hint HintEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintDelegated action
    */
    function getSetHintDelegatedStructHash(HintEntry calldata _hint, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_HINT_DELEGATED),
            _hint.namespace,
            _hint.list,
            _hint.key,
            _hint.value,
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a SetHintDelegated action
    * @param _hint HintEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintDelegated action
    */
    function getSetHintDelegatedTypedDataHash(HintEntry calldata _hint, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetHintDelegatedStructHash(_hint, _signer, _nonce)
            )
        );
    }

    ///////////////  SET HINTS DELEGATED  ///////////////

    /*
    * @dev Get the struct hash for SetHintsDelegated action
    * @param _hints HintsEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintsDelegated action
    */
    function getSetHintsDelegatedStructHash(HintsEntry calldata _hints, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_HINTS_DELEGATED),
            _hints.namespace,
            _hints.list,
            keccak256(abi.encodePacked(_hints.keys)),
            keccak256(abi.encodePacked(_hints.values)),
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a SetHint action
    * @param _hints HintsEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHints action
    */
    function getSetHintsDelegatedTypedDataHash(HintsEntry calldata _hints, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetHintsDelegatedStructHash(_hints, _signer, _nonce)
            )
        );
    }

    ///////////////  SET LIST STATUS  ///////////////

    /*
    * @dev Get the struct hash for SetListStatus action
    * @param _listOwnerEntry ListOwnerEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetListStatus action
    */
    function getSetListStatusStructHash(ListOwnerEntry calldata _listOwnerEntry, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_LIST_STATUS),
            _listOwnerEntry.namespace,
            _listOwnerEntry.list,
            _listOwnerEntry.revoked,
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a SetListStatus action
    * @param _listOwnerEntry ListOwnerEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetListStatus action
    */
    function getSetListStatusTypedDataHash(ListOwnerEntry calldata _listOwnerEntry, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetListStatusStructHash(_listOwnerEntry, _signer, _nonce)
            )
        );
    }
}
