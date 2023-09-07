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

    enum MetaAction {
        SET_HINT,
        SET_HINTS
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
            return keccak256("SetHintSigned(address namespace,bytes32 list,bytes32 key,bytes32 value,address signer,uint nonce)");
        } else if (_action == MetaAction.SET_HINTS) {
            return keccak256("SetHintsSigned(address namespace,bytes32 list,bytes32[] keys,bytes32[] values,address signer,uint nonce)");
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
}
