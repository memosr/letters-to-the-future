// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LettersToTheFutureV2 {
    // Packs sender (20 bytes) + timestamp (12 bytes) into one storage slot.
    // unlockTime occupies its own slot (uint256); 0 means always visible.
    struct Message {
        address sender;
        uint96 timestamp;
        uint256 unlockTime;
        string text;
    }

    uint256 public constant MAX_LENGTH = 280;

    Message[] private _messages;

    event MessagePosted(
        address indexed sender,
        uint256 indexed index,
        uint96 timestamp,
        uint256 unlockTime,
        string text
    );

    error MessageTooLong(uint256 length, uint256 max);
    error EmptyMessage();
    // unlockTime must be strictly in the future (or 0)
    error UnlockTimeInPast(uint256 provided, uint256 current);

    /// @param message  The letter text (max 280 bytes).
    /// @param unlockTime  Unix timestamp after which the UI reveals the text.
    ///                    Pass 0 for no lock. Note: text is always public on-chain.
    function postMessage(string calldata message, uint256 unlockTime) external {
        uint256 len = bytes(message).length;
        if (len == 0) revert EmptyMessage();
        if (len > MAX_LENGTH) revert MessageTooLong(len, MAX_LENGTH);
        if (unlockTime != 0 && unlockTime <= block.timestamp) {
            revert UnlockTimeInPast(unlockTime, block.timestamp);
        }

        uint96 ts = uint96(block.timestamp);
        _messages.push(Message({sender: msg.sender, timestamp: ts, unlockTime: unlockTime, text: message}));

        emit MessagePosted(msg.sender, _messages.length - 1, ts, unlockTime, message);
    }

    function getMessages() external view returns (Message[] memory) {
        return _messages;
    }

    function getMessageCount() external view returns (uint256) {
        return _messages.length;
    }
}
