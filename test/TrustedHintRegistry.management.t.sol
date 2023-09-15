pragma solidity ^0.8.20;
import { console, Test } from "forge-std/Test.sol";
import { TrustedHintRegistry } from "../src/TrustedHintRegistry.sol";
import { Sig712Utils } from "./utils/Sig712Utils.sol";
import { Events } from "./utils/Events.sol";

contract ManagementTest is Test, Events {
    TrustedHintRegistry internal registry;
    Sig712Utils internal sig712;
    address internal peterAddress;
    uint256 internal peterPrivateKey;
    address internal marieAddress;
    uint256 internal mariePrivateKey;

    function setUp() public {
        // Owner of this contract is address(0)!
        vm.startPrank(address(0));
        registry = new TrustedHintRegistry();
        registry.initialize();
        sig712 = new Sig712Utils(registry.version(), address(registry));
        vm.stopPrank();

        // Setup key pair for meta transactions
        peterPrivateKey = 1000000000000000000;
        peterAddress = vm.rememberKey(peterPrivateKey);
        mariePrivateKey = 1000000000000000001;
        marieAddress = vm.addr(mariePrivateKey);
    }

    function test_SetListStatus() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bool revoked = true;

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListStatusChanged(namespace, list, revoked);

        registry.setListStatus(namespace, list, revoked);
        assertEq(registry.revokedLists(keccak256(abi.encodePacked(namespace, list))), revoked);
    }

    function test_RevertSetListStatusIfCallerNotOwner() public {
        vm.prank(address(999999));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bool revoked = true;

        vm.expectRevert("Caller is not an owner");
        registry.setListStatus(namespace, list, revoked);
    }

    function test_RevertSetListStatusIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bool revoked = true;

        vm.expectRevert("Pausable: paused");
        registry.setListStatus(namespace, list, revoked);
    }

    function test_SetListStatusSigned() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bool revoked = true;

        bytes32 digest = sig712.getSetListStatusTypedDataHash(
            Sig712Utils.ListStatusEntry(namespace, list, revoked),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListStatusChanged(namespace, list, revoked);

        vm.prank(marieAddress);
        registry.setListStatusSigned(
            namespace,
            list,
            revoked,
            peterAddress,
            signature
        );
        assertEq(registry.revokedLists(keccak256(abi.encodePacked(namespace, list))), revoked);
    }

    function test_RevertSetListStatusSignedIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bool revoked = true;

        bytes32 digest = sig712.getSetListStatusTypedDataHash(
            Sig712Utils.ListStatusEntry(namespace, list, revoked),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.setListStatusSigned(
            namespace,
            list,
            revoked,
            peterAddress,
            signature
        );
    }

    function test_RevertSetListStatusSignedIfNonceInvalid() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bool revoked = true;

        bytes32 digest = sig712.getSetListStatusTypedDataHash(
            Sig712Utils.ListStatusEntry(namespace, list, revoked),
            peterAddress,
            registry.nonces(peterAddress) + 1
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setListStatusSigned(
            namespace,
            list,
            revoked,
            peterAddress,
            signature
        );
    }

    function test_RevertSetListStatusSignedIfSignerNotOwner() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        bool revoked = true;

        bytes32 digest = sig712.getSetListStatusTypedDataHash(
            Sig712Utils.ListStatusEntry(namespace, list, revoked),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(mariePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setListStatusSigned(
            namespace,
            list,
            revoked,
            peterAddress,
            signature
        );
    }

    function test_SetListOwner() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        address newOwner = address(2);

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListOwnerChanged(namespace, list, newOwner);

        registry.setListOwner(namespace, list, newOwner);
        assertEq(registry.identityIsOwner(namespace, list, namespace), false);
        assertEq(registry.identityIsOwner(namespace, list, newOwner), true);


        vm.prank(address(2));
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");
        registry.setHint(namespace, list, key, value);
        assertEq(registry.getHint(namespace, list, key), value);
    }

    function test_RevertSetHintIfOldOwner() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        address newOwner = address(2);

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListOwnerChanged(namespace, list, newOwner);

        registry.setListOwner(namespace, list, newOwner);
        assertEq(registry.identityIsOwner(namespace, list, namespace), false);
        assertEq(registry.identityIsOwner(namespace, list, newOwner), true);

        vm.expectRevert("Caller is not an owner");
        registry.setHint(namespace, list, keccak256("key"), keccak256("value"));
    }

    function test_RevertSetListOwnerIfCallerNotOwner() public {
        vm.prank(address(999999));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        address newOwner = address(2);

        vm.expectRevert("Caller is not an owner");
        registry.setListOwner(namespace, list, newOwner);
    }

    function test_RevertSetListOwnerIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        address newOwner = address(2);

        vm.expectRevert("Pausable: paused");
        registry.setListOwner(namespace, list, newOwner);
    }

    function test_SetListOwnerSigned() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        address newOwner = address(2);

        bytes32 digest = sig712.getSetListOwnerTypedDataHash(
            Sig712Utils.ListOwnerEntry(namespace, list, newOwner),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListOwnerChanged(namespace, list, newOwner);

        vm.prank(marieAddress);
        registry.setListOwnerSigned(
            namespace,
            list,
            newOwner,
            peterAddress,
            signature
        );
        assertEq(registry.identityIsOwner(namespace, list, peterAddress), false);
        assertEq(registry.identityIsOwner(namespace, list, newOwner), true);
        assertEq(registry.nonces(peterAddress), 1);
    }

    function test_RevertSetListOwnerSignedIfSignerOldOwner() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        address newOwner = address(2);

        bytes32 digest = sig712.getSetListOwnerTypedDataHash(
            Sig712Utils.ListOwnerEntry(namespace, list, newOwner),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListOwnerChanged(namespace, list, newOwner);

        vm.prank(marieAddress);
        registry.setListOwnerSigned(
            namespace,
            list,
            newOwner,
            peterAddress,
            signature
        );
        assertEq(registry.identityIsOwner(namespace, list, peterAddress), false);
        assertEq(registry.identityIsOwner(namespace, list, newOwner), true);
        assertEq(registry.nonces(peterAddress), 1);

        bytes32 digestNew = sig712.getSetListOwnerTypedDataHash(
            Sig712Utils.ListOwnerEntry(namespace, list, namespace),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 vNew, bytes32 rNew, bytes32 sNew) = vm.sign(peterPrivateKey, digestNew);
        bytes memory signatureNew = abi.encodePacked(rNew, sNew, vNew);

        vm.expectRevert("Signer is not an owner");
        registry.setListOwnerSigned(
            namespace,
            list,
            peterAddress,
            peterAddress,
            signatureNew
        );
    }

    function test_RevertSetListOwnerSignedIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        address newOwner = address(2);

        bytes32 digest = sig712.getSetListOwnerTypedDataHash(
            Sig712Utils.ListOwnerEntry(namespace, list, newOwner),
            peterAddress,
            registry.nonces(peterAddress)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Pausable: paused");
        registry.setListOwnerSigned(
            namespace,
            list,
            newOwner,
            peterAddress,
            signature
        );

        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_RevertSetListOwnerSignedIfNonceInvalid() public {
        vm.prank(peterAddress);
        address namespace = peterAddress;
        bytes32 list = keccak256("list");
        address newOwner = address(2);

        bytes32 digest = sig712.getSetListOwnerTypedDataHash(
            Sig712Utils.ListOwnerEntry(namespace, list, newOwner),
            peterAddress,
            registry.nonces(peterAddress) + 1
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(peterPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Signer is not an owner");
        registry.setListOwnerSigned(
            namespace,
            list,
            newOwner,
            peterAddress,
            signature
        );

        assertEq(registry.nonces(peterAddress), 0);
    }

    function test_AddListDelegate() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListDelegateAdded(namespace, list, peterAddress);

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), untilTimestamp);
    }

    function test_RevertAddListDelegateIfCallerNotOwner() public {
        vm.prank(address(999999));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        vm.expectRevert("Caller is not an owner");
        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
    }

    function test_RevertAddListDelegateIfTimestampNotInFuture() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = 0;

        vm.expectRevert("Timestamp must be in the future");
        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
    }

    function test_RevertAddListDelegateIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        vm.expectRevert("Pausable: paused");
        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
    }

    function test_RemoveListDelegate() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        uint256 untilTimestamp = block.timestamp + 100;

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.identityIsDelegate(namespace, list, peterAddress), true);

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListDelegateRemoved(namespace, list, peterAddress);

        vm.prank(address(1));
        registry.removeListDelegate(namespace, list, peterAddress);
        assertEq(registry.identityIsDelegate(namespace, list, peterAddress), false);
    }

    function test_RevertRemoveListDelegateIfCallerNotOwner() public {
        vm.prank(address(999999));
        address namespace = address(1);
        bytes32 list = keccak256("list");

        vm.expectRevert("Caller is not an owner");
        registry.removeListDelegate(namespace, list, peterAddress);
    }

    function test_RevertRemoveListDelegateIfContractPaused() public {
        vm.prank(address(0));
        registry.pause();

        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");

        vm.expectRevert("Pausable: paused");
        registry.removeListDelegate(namespace, list, peterAddress);
    }
}