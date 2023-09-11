pragma solidity ^0.8.20;
import { console, Test } from "forge-std/Test.sol";
import { TrustedHintRegistry } from "../src/TrustedHintRegistry.sol";
import { Sig712Utils } from "./utils/Sig712Utils.sol";
import { Events } from "./utils/Events.sol";

contract DelegateTest is Test, Events {
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

    function test_SetHintDelegated() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");
        uint256 untilTimestamp = block.timestamp + 100;

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintListDelegateAdded(namespace, list, peterAddress);

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), untilTimestamp);

        vm.prank(peterAddress);

        vm.expectEmit(true, true, true, true, address(registry));
        emit HintValueChanged(namespace, list, key, value);

        registry.setHintDelegated(namespace, list, key, value);
    }

    function test_RevertSetHintDelegatedIfCallerNotDelegate() public {
        vm.prank(address(999999));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");

        vm.expectRevert("Caller is not a delegate");

        registry.setHintDelegated(namespace, list, key, value);
    }

    function test_RevertSetHintDelegatedIfContractPaused() public {
        vm.prank(address(1));
        address namespace = address(1);
        bytes32 list = keccak256("list");
        bytes32 key = keccak256("key");
        bytes32 value = keccak256("value");
        uint256 untilTimestamp = block.timestamp + 100;

        registry.addListDelegate(namespace, list, peterAddress, untilTimestamp);
        assertEq(registry.delegates(keccak256(abi.encodePacked(namespace, list)), peterAddress), untilTimestamp);

        vm.prank(address(0));
        registry.pause();

        vm.prank(peterAddress);
        vm.expectRevert("Pausable: paused");
        registry.setHintDelegated(namespace, list, key, value);
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
}