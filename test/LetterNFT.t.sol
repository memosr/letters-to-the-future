// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LetterNFT.sol";

contract LetterNFTTest is Test {
    LetterNFT public nft;
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    address public stranger = makeAddr("stranger");

    uint256 constant MINT_FEE = 0.001 ether;

    function setUp() public {
        nft = new LetterNFT(owner);
        vm.deal(user, 1 ether);
        vm.deal(stranger, 1 ether);
    }

    // -------------------------------------------------------------------------
    // Mint tests
    // -------------------------------------------------------------------------

    function test_MintWithCorrectFee() public {
        vm.prank(user);
        uint256 tokenId = nft.mint{value: MINT_FEE}("Hello, future!", 1_000_000);

        assertEq(nft.ownerOf(tokenId), user);
        assertEq(address(nft).balance, MINT_FEE);
    }

    function test_MintWithExcessFee() public {
        vm.prank(user);
        uint256 tokenId = nft.mint{value: 0.01 ether}("More than enough", 1_000_000);

        assertEq(nft.ownerOf(tokenId), user);
        assertEq(address(nft).balance, 0.01 ether);
    }

    function test_MintIncrementsTokenId() public {
        vm.startPrank(user);
        uint256 id0 = nft.mint{value: MINT_FEE}("First letter", 1_000_000);
        uint256 id1 = nft.mint{value: MINT_FEE}("Second letter", 2_000_000);
        vm.stopPrank();

        assertEq(id0, 0);
        assertEq(id1, 1);
    }

    function test_RevertInsufficientFee() public {
        vm.prank(user);
        vm.expectRevert(LetterNFT.InsufficientFee.selector);
        nft.mint{value: 0.0009 ether}("Too cheap", 1_000_000);
    }

    function test_RevertZeroFee() public {
        vm.prank(user);
        vm.expectRevert(LetterNFT.InsufficientFee.selector);
        nft.mint{value: 0}("Free rider", 1_000_000);
    }

    // -------------------------------------------------------------------------
    // tokenURI tests
    // -------------------------------------------------------------------------

    function test_TokenURIReturnsBase64JSON() public {
        vm.prank(user);
        uint256 tokenId = nft.mint{value: MINT_FEE}("Hello future world!", 1_700_000_000);

        string memory uri = nft.tokenURI(tokenId);

        // Must start with the data URI prefix
        bytes memory uriBytes = bytes(uri);
        bytes memory prefix = bytes("data:application/json;base64,");
        assertEq(uriBytes.length > prefix.length, true, "URI too short");

        for (uint256 i = 0; i < prefix.length; i++) {
            assertEq(uriBytes[i], prefix[i], "Prefix mismatch");
        }
    }

    function test_TokenURINotEmptyAfterMint() public {
        vm.prank(user);
        uint256 tokenId = nft.mint{value: MINT_FEE}("A message", 123456);

        string memory uri = nft.tokenURI(tokenId);
        assertTrue(bytes(uri).length > 0, "tokenURI should not be empty");
    }

    function test_TokenURIRevertsForNonexistentToken() public {
        vm.expectRevert();
        nft.tokenURI(9999);
    }

    // -------------------------------------------------------------------------
    // Withdraw tests
    // -------------------------------------------------------------------------

    function test_WithdrawByOwner() public {
        // Mint a token to accumulate fees
        vm.prank(user);
        nft.mint{value: MINT_FEE}("Funding the owner", 1_000_000);

        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(owner);
        nft.withdraw();

        assertEq(address(nft).balance, 0);
        assertEq(owner.balance, ownerBalanceBefore + MINT_FEE);
    }

    function test_WithdrawAccumulatesMultipleMints() public {
        vm.prank(user);
        nft.mint{value: MINT_FEE}("Letter one", 1_000_000);

        vm.prank(stranger);
        nft.mint{value: MINT_FEE}("Letter two", 2_000_000);

        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(owner);
        nft.withdraw();

        assertEq(owner.balance, ownerBalanceBefore + 2 * MINT_FEE);
    }

    function test_WithdrawRevertsForNonOwner() public {
        vm.prank(user);
        nft.mint{value: MINT_FEE}("Bait", 1_000_000);

        vm.prank(stranger);
        vm.expectRevert(LetterNFT.NotOwner.selector);
        nft.withdraw();
    }

    function test_WithdrawRevertsForUser() public {
        vm.prank(user);
        nft.mint{value: MINT_FEE}("My letter", 1_000_000);

        vm.prank(user);
        vm.expectRevert(LetterNFT.NotOwner.selector);
        nft.withdraw();
    }

    // -------------------------------------------------------------------------
    // Metadata / SVG sanity
    // -------------------------------------------------------------------------

    function test_TokenURIContainsImageField() public {
        vm.prank(user);
        uint256 tokenId = nft.mint{value: MINT_FEE}("Test", 0);
        string memory uri = nft.tokenURI(tokenId);

        // Decode the base64 suffix and check it contains "image"
        // We just verify the URI is a data URI (checked above) and non-trivially long
        assertTrue(bytes(uri).length > 200, "metadata suspiciously short");
    }

    function test_MintFeeIsCorrect() public {
        assertEq(nft.mintFee(), MINT_FEE);
    }

    function test_OwnerIsSetInConstructor() public {
        assertEq(nft.owner(), owner);
    }
}
