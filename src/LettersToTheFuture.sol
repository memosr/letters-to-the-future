// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LettersToTheFuture {
    // Packs sender (20 bytes) + timestamp (12 bytes) into one storage slot
    struct Message {
        address sender;
        uint96 timestamp;
        string text;
    }

    uint256 public constant MAX_LENGTH = 280;

    Message[] private _messages;

    event MessagePosted(address indexed sender, uint256 indexed index, uint96 timestamp, string text);

    error MessageTooLong(uint256 length, uint256 max);
    error EmptyMessage();

    function postMessage(string calldata message) external {
        uint256 len = bytes(message).length;
        if (len == 0) revert EmptyMessage();
        if (len > MAX_LENGTH) revert MessageTooLong(len, MAX_LENGTH);

        uint96 ts = uint96(block.timestamp);
        _messages.push(Message({sender: msg.sender, timestamp: ts, text: message}));

        emit MessagePosted(msg.sender, _messages.length - 1, ts, message);
    }

    function getMessages() external view returns (Message[] memory) {
        return _messages;
    }

    function getMessageCount() external view returns (uint256) {
        return _messages.length;
    }
}
