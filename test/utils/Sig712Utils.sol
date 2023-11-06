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

    struct HintMetadataEntries {
        address namespace;
        bytes32 list;
        bytes32[] keys;
        bytes32[] values;
        bytes[] metadata;
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

    struct ListMetadataEntry {
        address namespace;
        bytes32 list;
        bytes metadata;
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
        SET_HINT_WITH_METADATA,
        SET_HINT_METADATA,
        SET_HINT_METADATA_DELEGATED,
        SET_HINT_DELEGATED,
        SET_HINT_DELEGATED_WITH_METADATA,
        SET_HINTS,
        SET_HINTS_WITH_METADATA,
        SET_HINTS_DELEGATED,
        SET_HINTS_DELEGATED_WITH_METADATA,
        SET_LIST_STATUS,
        SET_LIST_OWNER,
        SET_LIST_METADATA,
        SET_LIST_METADATA_DELEGATED,
        ADD_LIST_DELEGATE,
        REMOVE_LIST_DELEGATE,
        SET_METADATA,
        SET_METADATA_DELEGATED
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
        } else if (_action == MetaAction.SET_HINT_WITH_METADATA) {
            return keccak256("SetHintSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,bytes metadata,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_HINTS) {
            return keccak256("SetHintsSigned(address namespace,bytes32 list,bytes32[] keys,bytes32[] values,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_HINTS_WITH_METADATA) {
            return keccak256("SetHintsSigned(address namespace,bytes32 list,bytes32[] keys,bytes32[] values,bytes[] _metadata,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_HINT_METADATA) {
            return keccak256("SetHintMetadataSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,bytes metadata,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_HINT_METADATA_DELEGATED) {
            return keccak256("SetHintMetadataDelegatedSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,bytes metadata,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_HINT_DELEGATED) {
            return keccak256("SetHintDelegatedSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_HINT_DELEGATED_WITH_METADATA) {
            return keccak256("SetHintDelegatedSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,bytes metadata,address signer,uint256 nonce)");
        }  else if (_action == MetaAction.SET_HINTS_DELEGATED) {
            return keccak256("SetHintsDelegatedSigned(address namespace,bytes32 list,bytes32[] keys,bytes32[] values,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_HINTS_DELEGATED_WITH_METADATA) {
            return keccak256("SetHintsDelegatedSigned(address namespace,bytes32 list,bytes32[] keys,bytes32[] values, bytes[] _metadata,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_LIST_STATUS) {
            return keccak256("SetListStatusSigned(address namespace,bytes32 list,bool revoked,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_LIST_OWNER) {
            return keccak256("SetListOwnerSigned(address namespace,bytes32 list,address newOwner,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_LIST_METADATA) {
            return keccak256("SetListMetadataSigned(address namespace,bytes32 list,bytes metadata,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_LIST_METADATA_DELEGATED) {
            return keccak256("SetListMetadataDelegatedSigned(address namespace,bytes32 list,bytes metadata,address signer,uint256 nonce)");
        } else if (_action == MetaAction.ADD_LIST_DELEGATE) {
            return keccak256("AddListDelegateSigned(address namespace,bytes32 list,address delegate,uint256 untilTimestamp,address signer,uint256 nonce)");
        } else if (_action == MetaAction.REMOVE_LIST_DELEGATE) {
            return keccak256("RemoveListDelegateSigned(address namespace,bytes32 list,address delegate,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_METADATA) {
            return keccak256("SetMetadataSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,bytes metadata,address signer,uint256 nonce)");
        } else if (_action == MetaAction.SET_METADATA_DELEGATED) {
            return keccak256("SetMetadataDelegatedSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,bytes metadata,address signer,uint256 nonce)");
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

    ///////////////  SET HINT WITH METADATA ///////////////

    /*
    * @dev Get the struct hash for SetHintWithMetadata action
    * @param _hint HintMetadataEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintWithMetadata action
    */
    function getSetHintWithMetadataStructHash(HintMetadataEntry calldata _hint, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_HINT_WITH_METADATA),
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
    * @dev Get the typed data hash of a SetHintWithMetadata action
    * @param _hint HintMetadataEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintWithMetadata action
    */
    function getSetHintWithMetadataTypedDataHash(HintMetadataEntry calldata _hint, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetHintWithMetadataStructHash(_hint, _signer, _nonce)
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

    ///////////////  SET HINT DELEGATED WITH METADATA  ///////////////

    /*
    * @dev Get the struct hash for SetHintDelegatedWithMetadata action
    * @param _hint HintMetadataEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintDelegatedWithMetadata action
    */
    function getSetHintDelegatedWithMetadataStructHash(HintMetadataEntry calldata _hint, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_HINT_DELEGATED_WITH_METADATA),
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
    * @dev Get the typed data hash of a SetHintDelegated action
    * @param _hint HintMetadataEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintDelegated action
    */
    function getSetHintDelegatedWithMetadataTypedDataHash(HintMetadataEntry calldata _hint, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetHintDelegatedWithMetadataStructHash(_hint, _signer, _nonce)
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

    ///////////////  SET HINTS DELEGATED WITH METADATA  ///////////////

    /*
    * @dev Get the struct hash for SetHintsDelegatedWithMetadata action
    * @param _hints HintMetadataEntries
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintDelegatedWithMetadata action
    */
    function getSetHintsDelegatedWithMetadataStructHash(HintMetadataEntries calldata _hints, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_HINTS_DELEGATED_WITH_METADATA),
            _hints.namespace,
            _hints.list,
            keccak256(abi.encodePacked(_hints.keys)),
            keccak256(abi.encodePacked(_hints.values)),
            keccak256(abi.encode(_hints.metadata)),
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a SetHintsDelegatedWithMetadata action
    * @param _hint HintMetadataEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintsDelegated action
    */
    function getSetHintsDelegatedWithMetadataTypedDataHash(HintMetadataEntries calldata _hints, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetHintsDelegatedWithMetadataStructHash(_hints, _signer, _nonce)
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

    ///////////////  SET LIST METADATA  ///////////////

    /*
    * @dev Get the struct hash for SetListMetadata action
    * @param _listEntry ListMetadataEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the ListMetadataEntry action
    */
    function getSetListMetadataStructHash(ListMetadataEntry calldata _listEntry, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_LIST_METADATA),
            _listEntry.namespace,
            _listEntry.list,
            _listEntry.metadata,
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a SetListMetadata action
    * @param _listEntry ListMetadataEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetListMetadata action
    */
    function getSetListMetadataTypedDataHash(ListMetadataEntry calldata _listEntry, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetListMetadataStructHash(_listEntry, _signer, _nonce)
            )
        );
    }

    ///////////////  SET LIST METADATA DELEGATED  ///////////////

    /*
    * @dev Get the struct hash for SetListMetadata action
    * @param _listEntry ListMetadataEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the ListMetadataEntry action
    */
    function getSetListMetadataDelegatedStructHash(ListMetadataEntry calldata _listEntry, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_LIST_METADATA_DELEGATED),
            _listEntry.namespace,
            _listEntry.list,
            _listEntry.metadata,
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a SetListMetadata action
    * @param _listEntry ListMetadataEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetListMetadata action
    */
    function getSetListMetadataDelegatedTypedDataHash(ListMetadataEntry calldata _listEntry, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetListMetadataDelegatedStructHash(_listEntry, _signer, _nonce)
            )
        );
    }

    ///////////////  SET HINTS METADATA  ///////////////

    /*
    * @dev Get the struct hash for SetHintsMetadata action
    * @param _hints HintMetadataEntries
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintsMetadata action
    */
    function getSetHintsMetadataStructHash(HintMetadataEntries calldata _hints, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_HINTS_WITH_METADATA),
            _hints.namespace,
            _hints.list,
            keccak256(abi.encodePacked(_hints.keys)),
            keccak256(abi.encodePacked(_hints.values)),
            keccak256(abi.encode(_hints.metadata)),
            _signer,
            _nonce
        ));
    }

    /*
    * @dev Get the typed data hash of a SetHintsMetadata action
    * @param _hints HintMetadataEntries
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetHintsMetadata action
    */
    function getSetHintsMetadataTypedDataHash(HintMetadataEntries calldata _hints, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetHintsMetadataStructHash(_hints, _signer, _nonce)
            )
        );
    }

    ///////////////  SET METADATA  ///////////////

    /*
    * @dev Get the struct hash for SetMetadata action
    * @param _hint HintMetadataEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetMetadata action
    */
    function getSetMetadataStructHash(HintMetadataEntry calldata _hint, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_METADATA),
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
    * @dev Get the typed data hash of a SetMetadata action
    * @param _hint HintMetadataEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetMetadata action
    */
    function getSetMetadataTypedDataHash(HintMetadataEntry calldata _hint, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetMetadataStructHash(_hint, _signer, _nonce)
            ));
    }

    ///////////////  SET METADATA DELEGATED  ///////////////

    /*
    * @dev Get the struct hash for SetMetadataDelegated action
    * @param _hint HintMetadataEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetMetadataDelegated action
    */
    function getSetMetadataDelegatedStructHash(HintMetadataEntry calldata _hint, address _signer, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            getTypeHash(MetaAction.SET_METADATA_DELEGATED),
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
    * @dev Get the typed data hash of a SetMetadataDelegated action
    * @param _hint HintMetadataEntry
    * @param _signer Address of signature creator
    * @param _nonce Nonce of signature creator
    * @return Hash of the SetMetadataDelegated action
    */
    function getSetMetadataDelegatedTypedDataHash(HintMetadataEntry calldata _hint, address _signer, uint _nonce) public view returns (bytes32) {
        return
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                getSetMetadataDelegatedStructHash(_hint, _signer, _nonce)
            ));
    }
}