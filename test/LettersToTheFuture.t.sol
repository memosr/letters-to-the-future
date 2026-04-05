// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LettersToTheFuture} from "../src/LettersToTheFuture.sol";

contract LettersToTheFutureTest is Test {
    LettersToTheFuture public letters;

    address internal alice = makeAddr("alice");
    address internal bob   = makeAddr("bob");
    address internal carol = makeAddr("carol");

    function setUp() public {
        letters = new LettersToTheFuture();
    }

    // -------------------------------------------------------------------------
    // postMessage — happy path
    // -------------------------------------------------------------------------

    function test_postMessage_storedCorrectly() public {
        uint256 ts = 1_000_000;
        vm.warp(ts);
        vm.prank(alice);
        letters.postMessage("Hello, future.");

        LettersToTheFuture.Message[] memory msgs = letters.getMessages();
        assertEq(msgs.length, 1);
        assertEq(msgs[0].sender, alice);
        assertEq(msgs[0].timestamp, uint96(ts));
        assertEq(msgs[0].text, "Hello, future.");
    }

    function test_postMessage_emitsEvent() public {
        uint256 ts = 2_000_000;
        vm.warp(ts);
        vm.prank(alice);

        vm.expectEmit(true, true, false, true);
        emit LettersToTheFuture.MessagePosted(alice, 0, uint96(ts), "Hello, future.");
        letters.postMessage("Hello, future.");
    }

    // -------------------------------------------------------------------------
    // postMessage — reverts
    // -------------------------------------------------------------------------

    function test_postMessage_revert_emptyMessage() public {
        vm.prank(alice);
        vm.expectRevert(LettersToTheFuture.EmptyMessage.selector);
        letters.postMessage("");
    }

    function test_postMessage_revert_tooLong() public {
        // 281-byte string: exactly one byte over the limit
        string memory msg281 = new string(281);
        assembly {
            let ptr := add(msg281, 32)
            for { let i := 0 } lt(i, 281) { i := add(i, 1) } {
                mstore8(add(ptr, i), 0x41) // 'A'
            }
        }

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(LettersToTheFuture.MessageTooLong.selector, 281, 280)
        );
        letters.postMessage(msg281);
    }

    function test_postMessage_accepts_exactly280Bytes() public {
        string memory msg280 = new string(280);
        assembly {
            let ptr := add(msg280, 32)
            for { let i := 0 } lt(i, 280) { i := add(i, 1) } {
                mstore8(add(ptr, i), 0x42) // 'B'
            }
        }

        vm.prank(alice);
        letters.postMessage(msg280);
        assertEq(letters.getMessageCount(), 1);
    }

    // -------------------------------------------------------------------------
    // Multiple users
    // -------------------------------------------------------------------------

    function test_multipleUsers_getAllMessages() public {
        vm.warp(1_000);
        vm.prank(alice);
        letters.postMessage("Message from Alice");

        vm.warp(2_000);
        vm.prank(bob);
        letters.postMessage("Message from Bob");

        vm.warp(3_000);
        vm.prank(carol);
        letters.postMessage("Message from Carol");

        LettersToTheFuture.Message[] memory msgs = letters.getMessages();
        assertEq(msgs.length, 3);

        assertEq(msgs[0].sender, alice);
        assertEq(msgs[0].text,   "Message from Alice");
        assertEq(msgs[0].timestamp, 1_000);

        assertEq(msgs[1].sender, bob);
        assertEq(msgs[1].text,   "Message from Bob");
        assertEq(msgs[1].timestamp, 2_000);

        assertEq(msgs[2].sender, carol);
        assertEq(msgs[2].text,   "Message from Carol");
        assertEq(msgs[2].timestamp, 3_000);
    }

    // -------------------------------------------------------------------------
    // getMessageCount
    // -------------------------------------------------------------------------

    function test_getMessageCount_startsAtZero() public view {
        assertEq(letters.getMessageCount(), 0);
    }

    function test_getMessageCount_incrementsPerPost() public {
        vm.prank(alice);
        letters.postMessage("one");
        assertEq(letters.getMessageCount(), 1);

        vm.prank(bob);
        letters.postMessage("two");
        assertEq(letters.getMessageCount(), 2);

        vm.prank(carol);
        letters.postMessage("three");
        assertEq(letters.getMessageCount(), 3);
    }

    // -------------------------------------------------------------------------
    // Fuzz
    // -------------------------------------------------------------------------

    function testFuzz_postMessage_validLength(string calldata message) public {
        vm.assume(bytes(message).length > 0 && bytes(message).length <= 280);
        vm.prank(alice);
        letters.postMessage(message);
        assertEq(letters.getMessageCount(), 1);
        assertEq(letters.getMessages()[0].text, message);
    }
}
