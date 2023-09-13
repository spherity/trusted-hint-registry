pragma solidity ^0.8.20;
contract Events {
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