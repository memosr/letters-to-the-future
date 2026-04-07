// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LetterNFT is ERC721 {
    using Strings for uint256;
    using Strings for address;

    struct Letter {
        address sender;
        string message;
        uint256 timestamp;
        uint256 tokenId;
    }

    uint256 public mintFee = 0.001 ether;
    address public owner;
    uint256 private _nextTokenId;

    mapping(uint256 => Letter) private _letters;

    error InsufficientFee();
    error NotOwner();
    error WithdrawFailed();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(address _owner) ERC721("Letters to the Future", "LETTER") {
        owner = _owner;
    }

    function mint(
        string memory message,
        uint256 timestamp
    ) external payable returns (uint256) {
        if (msg.value < mintFee) revert InsufficientFee();

        uint256 tokenId = _nextTokenId++;
        _letters[tokenId] = Letter({
            sender: msg.sender,
            message: message,
            timestamp: timestamp,
            tokenId: tokenId
        });

        _mint(msg.sender, tokenId);
        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        Letter memory letter = _letters[tokenId];
        string memory svg = _buildSVG(letter);
        string memory json = _buildJSON(letter, svg);

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function withdraw() external onlyOwner {
        (bool success,) = owner.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    function _buildSVG(Letter memory letter) internal pure returns (string memory) {
        string memory senderStr = _toHexString(letter.sender);
        string memory messageLines = _wrapText(letter.message, 36);

        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" width="400" height="400">',
                '<defs>',
                '<style>',
                '.title{font-family:Georgia,serif;font-size:16px;fill:#f0c060;font-style:italic;}',
                '.msg{font-family:Georgia,serif;font-size:13px;fill:#ffffff;}',
                '.addr{font-family:monospace;font-size:10px;fill:#a0a0c0;}',
                '.star{fill:#ffffff;}',
                '</style>',
                '</defs>',
                // background
                '<rect width="400" height="400" fill="#0a0a0f"/>',
                // stars
                _stars(),
                // gold border
                '<rect x="12" y="12" width="376" height="376" fill="none" stroke="#f0c060" stroke-width="2" rx="8"/>',
                '<rect x="16" y="16" width="368" height="368" fill="none" stroke="#f0c060" stroke-width="0.5" rx="6" opacity="0.4"/>',
                // title
                '<text x="200" y="50" text-anchor="middle" class="title">Letters to the Future</text>',
                // divider
                '<line x1="40" y1="62" x2="360" y2="62" stroke="#f0c060" stroke-width="0.5" opacity="0.5"/>',
                // message text
                messageLines,
                // sender
                '<line x1="40" y1="348" x2="360" y2="348" stroke="#f0c060" stroke-width="0.5" opacity="0.5"/>',
                '<text x="200" y="368" text-anchor="middle" class="addr">',
                senderStr,
                '</text>',
                '</svg>'
            )
        );
    }

    function _stars() internal pure returns (string memory) {
        // Deterministic star positions
        return string(
            abi.encodePacked(
                '<circle cx="30" cy="30" r="0.8" class="star" opacity="0.9"/>',
                '<circle cx="80" cy="20" r="0.5" class="star" opacity="0.7"/>',
                '<circle cx="150" cy="35" r="0.7" class="star" opacity="0.8"/>',
                '<circle cx="230" cy="25" r="0.6" class="star" opacity="0.9"/>',
                '<circle cx="310" cy="30" r="0.8" class="star" opacity="0.6"/>',
                '<circle cx="370" cy="18" r="0.5" class="star" opacity="0.8"/>',
                '<circle cx="350" cy="380" r="0.7" class="star" opacity="0.7"/>',
                '<circle cx="60" cy="370" r="0.6" class="star" opacity="0.9"/>',
                '<circle cx="190" cy="390" r="0.8" class="star" opacity="0.6"/>',
                '<circle cx="270" cy="375" r="0.5" class="star" opacity="0.8"/>'
            )
        );
    }

    function _buildJSON(Letter memory letter, string memory svg) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{"name":"Letter #',
                letter.tokenId.toString(),
                '","description":"A letter written to the future, preserved forever on-chain.","image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '","attributes":[{"trait_type":"Sender","value":"',
                _toHexString(letter.sender),
                '"},{"trait_type":"Timestamp","value":"',
                letter.timestamp.toString(),
                '"},{"trait_type":"Message Length","value":"',
                bytes(letter.message).length.toString(),
                '"}]}'
            )
        );
    }

    /// @dev Wraps text into SVG tspan lines at ~charsPerLine chars each, starting at y=90.
    function _wrapText(string memory text, uint256 charsPerLine) internal pure returns (string memory) {
        bytes memory b = bytes(text);
        uint256 len = b.length;
        if (len == 0) return "";

        string memory result = "";
        uint256 lineStart = 0;
        uint256 lineY = 90;
        uint256 maxLines = 10;
        uint256 lineCount = 0;

        while (lineStart < len && lineCount < maxLines) {
            uint256 lineEnd = lineStart + charsPerLine;
            if (lineEnd >= len) {
                lineEnd = len;
            } else {
                // back up to last space if possible
                uint256 k = lineEnd;
                while (k > lineStart && b[k] != 0x20) {
                    k--;
                }
                if (k > lineStart) lineEnd = k;
            }

            bytes memory segment = new bytes(lineEnd - lineStart);
            for (uint256 i = 0; i < lineEnd - lineStart; i++) {
                segment[i] = b[lineStart + i];
            }

            result = string(
                abi.encodePacked(
                    result,
                    '<text x="200" y="',
                    lineY.toString(),
                    '" text-anchor="middle" class="msg">',
                    _escapeSVG(string(segment)),
                    "</text>"
                )
            );

            lineStart = lineEnd;
            // skip leading space on next line
            if (lineStart < len && b[lineStart] == 0x20) lineStart++;
            lineY += 20;
            lineCount++;
        }

        return result;
    }

    function _escapeSVG(string memory s) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        bytes memory out = new bytes(b.length * 6); // worst case
        uint256 outLen = 0;
        for (uint256 i = 0; i < b.length; i++) {
            bytes1 c = b[i];
            if (c == "<") {
                out[outLen++] = "&"; out[outLen++] = "l"; out[outLen++] = "t"; out[outLen++] = ";";
            } else if (c == ">") {
                out[outLen++] = "&"; out[outLen++] = "g"; out[outLen++] = "t"; out[outLen++] = ";";
            } else if (c == "&") {
                out[outLen++] = "&"; out[outLen++] = "a"; out[outLen++] = "m"; out[outLen++] = "p"; out[outLen++] = ";";
            } else if (c == '"') {
                out[outLen++] = "&"; out[outLen++] = "q"; out[outLen++] = "u"; out[outLen++] = "o"; out[outLen++] = "t"; out[outLen++] = ";";
            } else {
                out[outLen++] = c;
            }
        }
        bytes memory trimmed = new bytes(outLen);
        for (uint256 i = 0; i < outLen; i++) {
            trimmed[i] = out[i];
        }
        return string(trimmed);
    }

    function _toHexString(address addr) internal pure returns (string memory) {
        bytes memory b = abi.encodePacked(addr);
        bytes memory hexChars = "0123456789abcdef";
        bytes memory out = new bytes(42);
        out[0] = "0";
        out[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            out[2 + i * 2] = hexChars[uint8(b[i]) >> 4];
            out[3 + i * 2] = hexChars[uint8(b[i]) & 0x0f];
        }
        return string(out);
    }
}
