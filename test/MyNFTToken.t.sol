// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MyNFTToken.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MyNFTTokenTest is Test {
    MyNFTToken private nft;
    address public owner = address(0x0000000000000000000000000000000000000002);
    address public recipient = address(0x0000000000000000000000000000000000000001);
    bytes32 private merkleRoot;

    function setUp() public {
        vm.deal(recipient, 10 ether);
        // Set the Merkle root from the generated output
        merkleRoot = 0x21abd2f655ded75d91fbd5e0b1ad35171a675fd315a077efa7f2d555a26e7094;

        nft = new MyNFTToken(owner, merkleRoot);
    }

    function testMint() public {
        nft.mint{value: 0.1 ether}(owner);
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(1), owner);
    }

    function testMintMaxSupply() public {
        for (uint256 i = 0; i < 1000; i++) {
            nft.mint{value: 0.1 ether}(owner);
        }
        vm.expectRevert("Max supply reached");
        nft.mint{value: 0.1 ether}(owner);
    }

    function testRoyaltyInfo() public {
        nft.mint{value: 0.1 ether}(owner);
        (address royaltyRecipient, uint256 royaltyAmount) = nft.royaltyInfo(1, 1 ether);
        assertEq(royaltyRecipient, owner);
        assertEq(royaltyAmount, 0.025 ether);
    }

    function testDiscountedMint() public {
        // Using the correct proof for the address 0x0000000000000000000000000000000000000001
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x2584db4a68aa8b172f70bc04e2e74541617c003374de6eb4b295e823e5beab01;
        proof[1] = 0xc949c2dc5da2bd9a4f5ae27532dfbb3551487bed50825cd099ff5d0a8d613ab5;

        // Prank recipient to perform the discounted mint
        vm.prank(recipient);
        nft.discountedMint{value: 0.05 ether}(proof);
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(1), recipient);

        // Try discounted mint again, expect revert
        vm.prank(recipient);
        vm.expectRevert("Discount already used");
        nft.discountedMint{value: 0.05 ether}(proof);
    }

    function testWithdrawFunds() public {
        // Mint an NFT to the recipient
        vm.prank(recipient);
        nft.mint{value: 0.1 ether}(recipient);

        // Withdraw funds as the owner
        uint256 initialBalance = owner.balance;
        vm.prank(owner);
        nft.withdrawFunds();
        uint256 finalBalance = owner.balance;
        // Check the balance after withdrawal
        assertEq(finalBalance - initialBalance, 0.1 ether);
    }
}
