// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LettersToTheFutureV2} from "../src/LettersToTheFutureV2.sol";

contract LettersToTheFutureV2Test is Test {
    LettersToTheFutureV2 public letters;

    address internal alice = makeAddr("alice");
    address internal bob   = makeAddr("bob");
    address internal carol = makeAddr("carol");

    uint256 constant BASE_TIME = 1_000_000;

    function setUp() public {
        vm.warp(BASE_TIME);
        letters = new LettersToTheFutureV2();
    }

    // -------------------------------------------------------------------------
    // postMessage — no lock (unlockTime = 0)
    // -------------------------------------------------------------------------

    function test_postMessage_noLock_storedCorrectly() public {
        vm.prank(alice);
        letters.postMessage("Hello, future.", 0);

        LettersToTheFutureV2.Message[] memory msgs = letters.getMessages();
        assertEq(msgs.length, 1);
        assertEq(msgs[0].sender, alice);
        assertEq(msgs[0].timestamp, uint96(BASE_TIME));
        assertEq(msgs[0].unlockTime, 0);
        assertEq(msgs[0].text, "Hello, future.");
    }

    function test_postMessage_noLock_emitsEvent() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit LettersToTheFutureV2.MessagePosted(alice, 0, uint96(BASE_TIME), 0, "Hello, future.");
        letters.postMessage("Hello, future.", 0);
    }

    // -------------------------------------------------------------------------
    // postMessage — with future lock
    // -------------------------------------------------------------------------

    function test_postMessage_withLock_storedCorrectly() public {
        uint256 unlock = BASE_TIME + 365 days;
        vm.prank(alice);
        letters.postMessage("Open in a year.", unlock);

        LettersToTheFutureV2.Message[] memory msgs = letters.getMessages();
        assertEq(msgs[0].unlockTime, unlock);
        assertEq(msgs[0].text, "Open in a year.");
    }

    function test_postMessage_withLock_emitsEvent() public {
        uint256 unlock = BASE_TIME + 1 days;
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit LettersToTheFutureV2.MessagePosted(alice, 0, uint96(BASE_TIME), unlock, "Tomorrow.");
        letters.postMessage("Tomorrow.", unlock);
    }

    // unlockTime exactly one second in the future is valid
    function test_postMessage_withLock_oneSecondAhead() public {
        vm.prank(alice);
        letters.postMessage("Just barely future.", BASE_TIME + 1);
        assertEq(letters.getMessageCount(), 1);
    }

    // -------------------------------------------------------------------------
    // postMessage — reverts
    // -------------------------------------------------------------------------

    function test_postMessage_revert_emptyMessage() public {
        vm.prank(alice);
        vm.expectRevert(LettersToTheFutureV2.EmptyMessage.selector);
        letters.postMessage("", 0);
    }

    function test_postMessage_revert_tooLong() public {
        string memory msg281 = new string(281);
        assembly {
            let ptr := add(msg281, 32)
            for { let i := 0 } lt(i, 281) { i := add(i, 1) } {
                mstore8(add(ptr, i), 0x41)
            }
        }
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(LettersToTheFutureV2.MessageTooLong.selector, 281, 280)
        );
        letters.postMessage(msg281, 0);
    }

    function test_postMessage_revert_unlockTimeInPast() public {
        uint256 past = BASE_TIME - 1;
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(LettersToTheFutureV2.UnlockTimeInPast.selector, past, BASE_TIME)
        );
        letters.postMessage("Too late.", past);
    }

    // unlockTime == block.timestamp is also rejected (not strictly future)
    function test_postMessage_revert_unlockTimeEqualsNow() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(LettersToTheFutureV2.UnlockTimeInPast.selector, BASE_TIME, BASE_TIME)
        );
        letters.postMessage("Right now.", BASE_TIME);
    }

    function test_postMessage_accepts_exactly280Bytes() public {
        string memory msg280 = new string(280);
        assembly {
            let ptr := add(msg280, 32)
            for { let i := 0 } lt(i, 280) { i := add(i, 1) } {
                mstore8(add(ptr, i), 0x42)
            }
        }
        vm.prank(alice);
        letters.postMessage(msg280, 0);
        assertEq(letters.getMessageCount(), 1);
    }

    // -------------------------------------------------------------------------
    // Mixed locked / unlocked messages from multiple users
    // -------------------------------------------------------------------------

    function test_multipleMessages_mixedLockTimes() public {
        uint256 unlock = BASE_TIME + 30 days;

        vm.warp(BASE_TIME);
        vm.prank(alice);
        letters.postMessage("Always visible", 0);

        vm.warp(BASE_TIME + 100);
        vm.prank(bob);
        letters.postMessage("Opens in a month", unlock);

        vm.warp(BASE_TIME + 200);
        vm.prank(carol);
        letters.postMessage("Also always visible", 0);

        LettersToTheFutureV2.Message[] memory msgs = letters.getMessages();
        assertEq(msgs.length, 3);

        assertEq(msgs[0].sender, alice);
        assertEq(msgs[0].unlockTime, 0);

        assertEq(msgs[1].sender, bob);
        assertEq(msgs[1].unlockTime, unlock);

        assertEq(msgs[2].sender, carol);
        assertEq(msgs[2].unlockTime, 0);
    }

    // -------------------------------------------------------------------------
    // getMessageCount
    // -------------------------------------------------------------------------

    function test_getMessageCount_startsAtZero() public view {
        assertEq(letters.getMessageCount(), 0);
    }

    function test_getMessageCount_incrementsPerPost() public {
        vm.prank(alice);
        letters.postMessage("one", 0);
        assertEq(letters.getMessageCount(), 1);

        vm.prank(bob);
        letters.postMessage("two", BASE_TIME + 1 days);
        assertEq(letters.getMessageCount(), 2);

        vm.prank(carol);
        letters.postMessage("three", 0);
        assertEq(letters.getMessageCount(), 3);
    }

    // -------------------------------------------------------------------------
    // Fuzz
    // -------------------------------------------------------------------------

    function testFuzz_postMessage_noLock(string calldata message) public {
        vm.assume(bytes(message).length > 0 && bytes(message).length <= 280);
        vm.prank(alice);
        letters.postMessage(message, 0);
        assertEq(letters.getMessageCount(), 1);
        assertEq(letters.getMessages()[0].text, message);
        assertEq(letters.getMessages()[0].unlockTime, 0);
    }

    function testFuzz_postMessage_futureLock(string calldata message, uint256 offset) public {
        vm.assume(bytes(message).length > 0 && bytes(message).length <= 280);
        // offset in [1, 10 years] to keep unlockTime strictly in the future
        offset = bound(offset, 1, 10 * 365 days);
        uint256 unlock = BASE_TIME + offset;
        vm.prank(alice);
        letters.postMessage(message, unlock);
        assertEq(letters.getMessages()[0].unlockTime, unlock);
    }

    function testFuzz_postMessage_revert_pastOrPresentLock(uint256 ts) public {
        // any ts <= BASE_TIME (and ts != 0) should revert
        ts = bound(ts, 1, BASE_TIME);
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(LettersToTheFutureV2.UnlockTimeInPast.selector, ts, BASE_TIME)
        );
        letters.postMessage("locked", ts);
    }
}
