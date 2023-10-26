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

    struct HintMetadataEntry {
        address namespace;
        bytes32 list;
        bytes32 key;
        bytes32 value;
        bytes metadata;
    }

    struct HintsEntry {
        address namespace;
        bytes32 list;
        bytes32[] keys;
        bytes32[] values;
    }

    struct ListStatusEntry {
        address namespace;
        bytes32 list;
        bool revoked;
    }

    struct ListOwnerEntry {
        address namespace;
        bytes32 list;
        address newOwner;
    }

    struct AddListDelegateEntry {
        address namespace;
        bytes32 list;
        address delegate;
        uint untilTimestamp;
    }

    struct RemoveListDelegateEntry {
        address namespace;
        bytes32 list;
        address delegate;
    }

    enum MetaAction {
        SET_HINT,
        SET_HINT_METADATA,
        SET_HINT_METADATA_DELEGATED,
        SET_HINTS,
        SET_HINT_DELEGATED,
        SET_HINTS_DELEGATED,
        SET_LIST_STATUS,
        SET_LIST_OWNER,
        ADD_LIST_DELEGATE,
        REMOVE_LIST_DELEGATE
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
        } else if (_action == MetaAction.SET_HINT_METADATA) {
            return keccak256("SetHintMetadataSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,bytes metadata,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_HINT_METADATA_DELEGATED) {
            return keccak256("SetHintMetadataDelegatedSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,bytes metadata,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_HINT_DELEGATED) {
            return keccak256("SetHintDelegatedSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_HINTS_DELEGATED) {
            return keccak256("SetHintsDelegatedSigned(address namespace,bytes32 list,bytes32[] keys,bytes32[] values,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_LIST_STATUS) {
            return keccak256("SetListStatusSigned(address namespace,bytes32 list,bool revoked,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_LIST_OWNER) {
            return keccak256("SetListOwnerSigned(address namespace,bytes32 list,address newOwner,address signer,uint256 nonce)");
        } else if (_action == MetaAction.ADD_LIST_DELEGATE) {
            return keccak256("AddListDelegateSigned(address namespace,bytes32 list,address delegate,uint256 untilTimestamp,address signer,uint256 nonce)");
        } else if (_action == MetaAction.REMOVE_LIST_DELEGATE) {
            return keccak256("RemoveListDelegateSigned(address namespace,bytes32 list,address delegate,address signer,uint256 nonce)");
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
    * @param _listStatusEntry ListStatusEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetListStatus action
    */
    function getSetListStatusStructHash(ListStatusEntry calldata _listStatusEntry, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_LIST_STATUS),
            _listStatusEntry.namespace,
            _listStatusEntry.list,
            _listStatusEntry.revoked,
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a SetListStatus action
    * @param _listStatusEntry ListStatusEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetListStatus action
    */
    function getSetListStatusTypedDataHash(ListStatusEntry calldata _listStatusEntry, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetListStatusStructHash(_listStatusEntry, _signer, _nonce)
            )
        );
    }

    ///////////////  SET LIST OWNER  ///////////////

    /*
    * @dev Get the struct hash for SetListOwner action
    * @param _listOwnerEntry ListOwnerEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetListOwner action
    */
    function getSetListOwnerStructHash(ListOwnerEntry calldata _listOwnerEntry, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_LIST_OWNER),
            _listOwnerEntry.namespace,
            _listOwnerEntry.list,
            _listOwnerEntry.newOwner,
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a SetListOwner action
    * @param _listOwnerEntry ListOwnerEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetListOwner action
    */
    function getSetListOwnerTypedDataHash(ListOwnerEntry calldata _listOwnerEntry, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetListOwnerStructHash(_listOwnerEntry, _signer, _nonce)
            )
        );
    }

    ///////////////  ADD LIST DELEGATE  ///////////////

    /*
    * @dev Get the struct hash for AddListDelegate action
    * @param _addDelegateEntry AddListDelegateEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the AddListDelegate action
    */
    function getAddListDelegateStructHash(AddListDelegateEntry calldata _addDelegateEntry, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.ADD_LIST_DELEGATE),
            _addDelegateEntry.namespace,
            _addDelegateEntry.list,
            _addDelegateEntry.delegate,
            _addDelegateEntry.untilTimestamp,
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a AddListDelegate action
    * @param _addDelegateEntry AddListDelegateEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the AddListDelegate action
    */
    function getAddListDelegateTypedDataHash(AddListDelegateEntry calldata _addDelegateEntry, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getAddListDelegateStructHash(_addDelegateEntry, _signer, _nonce)
            )
        );
    }

    ///////////////  REMOVE LIST DELEGATE  ///////////////

    /*
    * @dev Get the struct hash for RemoveListDelegate action
    * @param _removeDelegateEntry RemoveListDelegateEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the RemoveListDelegate action
    */
    function getRemoveListDelegateStructHash(RemoveListDelegateEntry calldata _removeDelegateEntry, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.REMOVE_LIST_DELEGATE),
            _removeDelegateEntry.namespace,
            _removeDelegateEntry.list,
            _removeDelegateEntry.delegate,
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a RemoveListDelegate action
    * @param _removeDelegateEntry RemoveListDelegateEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the RemoveListDelegate action
    */
    function getRemoveListDelegateTypedDataHash(RemoveListDelegateEntry calldata _removeDelegateEntry, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getRemoveListDelegateStructHash(_removeDelegateEntry, _signer, _nonce)
            )
        );
    }

    ///////////////  SET HINT METADATA  ///////////////

    /*
    * @dev Get the struct hash for SetHintMetadata action
    * @param _hint HintEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintMetadata action
    */
    function getSetHintMetadataStructHash(HintMetadataEntry calldata _hint, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_HINT_METADATA),
            _hint.namespace,
            _hint.list,
            _hint.key,
            _hint.value,
            _hint.metadata,
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a SetHintMetadata action
    * @param _hint HintEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintMetadata action
    */
    function getSetHintMetadataTypedDataHash(HintMetadataEntry calldata _hint, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetHintMetadataStructHash(_hint, _signer, _nonce)
            )
        );
    }

    ///////////////  SET HINT METADATA DELEGATED  ///////////////

    /*
    * @dev Get the struct hash for SetHintMetadata action
    * @param _hint HintEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintMetadata action
    */
    function getSetHintMetadataDelegatedStructHash(HintMetadataEntry calldata _hint, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_HINT_METADATA_DELEGATED),
            _hint.namespace,
            _hint.list,
            _hint.key,
            _hint.value,
            _hint.metadata,
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a SetHintMetadata action
    * @param _hint HintEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintMetadata action
    */
    function getSetHintMetadataDelegatedTypedDataHash(HintMetadataEntry calldata _hint, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetHintMetadataDelegatedStructHash(_hint, _signer, _nonce)
            )
        );
    }
}
