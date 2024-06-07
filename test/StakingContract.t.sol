// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/StakingContract.sol";
import "./Utils/BasicERC721.sol";
import "./Utils/BasicERC20.sol";

contract StakingContractTest is Test {
    StakingContract private stakingContract;
    BasicERC721 private nft;
    BasicERC721 private nft2;
    BasicERC20 private token;
    address private owner;
    address private user;

    function setUp() public {
        owner = address(this);
        user = address(1);

        nft = new BasicERC721();
        nft2 = new BasicERC721();
        token = new BasicERC20();

        stakingContract = new StakingContract(owner, token, nft);

        // Mint some tokens to the staking contract for rewards
        token.transfer(address(stakingContract), 1000 * 10 ** token.decimals());
    }

    function testStake() public {
        nft.mint(user);

        vm.prank(user);
        nft.safeTransferFrom(user, address(stakingContract), 1);

        (uint256 tokenId, uint256 timestamp, address tokenOwner) = stakingContract.stakes(1);
        assertEq(tokenId, 1);
        assertEq(tokenOwner, user);
    }

    function testWrongNFTToStake() public {
        nft2.mint(user);

        vm.prank(user);
        vm.expectRevert();
        nft2.safeTransferFrom(user, address(stakingContract), 1);
    }

    function testStakeAndClaimReward() public {
        // Mint an NFT to the user
        nft.mint(user);

        vm.startPrank(user);
        nft.safeTransferFrom(user, address(stakingContract), 1);

        // Fast forward time by 2 days
        vm.warp(block.timestamp + 2 days);
        stakingContract.claimReward(1);

        // Check reward balance
        uint256 expectedReward = 2 * 10 * 10 ** token.decimals(); // 2 days worth of rewards
        assertEq(token.balanceOf(user), expectedReward);
    }

    function testClaimEarly() public {
        // Mint an NFT to the user
        nft.mint(user);

        vm.startPrank(user);
        nft.safeTransferFrom(user, address(stakingContract), 1);

        // Fast forward time by 2 days
        vm.warp(block.timestamp + 6 hours);
        stakingContract.claimReward(1);

        // Check reward balance
        assertEq(token.balanceOf(user), 0);
    }

    function testClaimWithoutDeposit() public {
        // Mint an NFT to the user
        nft.mint(user);

        vm.startPrank(user);
        vm.expectRevert();
        stakingContract.claimReward(0);
    }

    function testWithdraw() public {
        // Mint an NFT to the user
        nft.mint(user);

        vm.startPrank(user);
        nft.safeTransferFrom(user, address(stakingContract), 1);

        // Fast forward time by 1 day
        vm.warp(block.timestamp + 1 days);

        // Withdraw the NFT
        stakingContract.withdraw(1);

        // Check ownership of the NFT
        assertEq(nft.ownerOf(1), user);

        // Check reward balance
        uint256 expectedReward = 10 * 10 ** token.decimals(); // 1 day worth of rewards
        assertEq(token.balanceOf(user), expectedReward);

        // Check that the stake has been deleted
        (uint256 tokenId, uint256 timestamp, address tokenOwner) = stakingContract.stakes(1);
        assertEq(tokenOwner, address(0));
    }

    function testWithdrawEarly() public {
        // Mint an NFT to the user
        nft.mint(user);

        vm.startPrank(user);
        nft.safeTransferFrom(user, address(stakingContract), 1);

        // Fast forward time by 1 day
        vm.warp(block.timestamp + 6 hours);

        // Withdraw the NFT
        stakingContract.withdraw(1);
        assertEq(token.balanceOf(user), 0);
    }
}
