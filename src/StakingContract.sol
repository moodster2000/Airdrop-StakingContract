// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Unauthorized();

/// @title StakingContract
/// @notice Allows users to stake ERC721 tokens and earn ERC20 rewards.
/// @dev Inherits from OpenZeppelin's Ownable and implements IERC721Receiver.
contract StakingContract is IERC721Receiver, Ownable {
    IERC20 public rewardToken;
    IERC721 public stakableNFT;
    uint256 public rewardRate = 10 * 10 ** 18; // 10 tokens per 24 hours, assuming 18 decimals for ERC20

    struct Stake {
        uint256 tokenId;
        uint256 timestamp;
        address tokenOwner;
    }

    mapping(uint256 => Stake) public stakes;

    /// @notice Emitted when a token is staked.
    /// @param user The address of the user who staked the token.
    /// @param tokenId The ID of the staked token.
    event Staked(address indexed user, uint256 indexed tokenId);

    /// @notice Emitted when a token is withdrawn.
    /// @param user The address of the user who withdrew the token.
    /// @param tokenId The ID of the withdrawn token.
    event Withdrew(address indexed user, uint256 indexed tokenId);

    /// @notice Emitted when a reward is claimed.
    /// @param user The address of the user who claimed the reward.
    /// @param rewardAmount The amount of the reward claimed.
    event RewardClaimed(address indexed user, uint256 rewardAmount);

    /// @notice Constructor for the StakingContract.
    /// @param initialOwner The initial owner of the contract.
    /// @param _rewardToken The ERC20 token used for rewards.
    /// @param _stakableNFT The ERC721 token that can be staked.
    constructor(address initialOwner, IERC20 _rewardToken, IERC721 _stakableNFT) Ownable(initialOwner) {
        rewardToken = _rewardToken;
        stakableNFT = _stakableNFT;
    }

    /// @notice Handles the receipt of an ERC721 token.
    /// @param operator The address which called `safeTransferFrom` function.
    /// @param from The address which previously owned the token.
    /// @param tokenId The ID of the token being transferred.
    /// @param data Additional data with no specified format.
    /// @return The selector of this function.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        require(msg.sender == address(stakableNFT), "Wrong NFT sent");

        stakes[tokenId] = Stake({tokenId: tokenId, tokenOwner: from, timestamp: block.timestamp});

        emit Staked(from, tokenId);
        return this.onERC721Received.selector;
    }

    /// @notice Withdraws a staked token.
    /// @param tokenId The ID of the token to withdraw.
    function withdraw(uint256 tokenId) external {
        Stake storage userStake = stakes[tokenId];
        if (userStake.tokenOwner != msg.sender || userStake.tokenOwner == address(0)) {
            revert Unauthorized();
        }

        _claimReward(userStake);

        delete stakes[tokenId];
        stakableNFT.safeTransferFrom(address(this), msg.sender, tokenId);

        emit Withdrew(msg.sender, tokenId);
    }

    /// @notice Claims the reward for a staked token.
    /// @param tokenId The ID of the token for which to claim the reward.
    function claimReward(uint256 tokenId) external {
        Stake storage userStake = stakes[tokenId];
        if (userStake.tokenOwner != msg.sender || userStake.tokenOwner == address(0)) {
            revert Unauthorized();
        }
        _claimReward(userStake);
    }

    /// @notice Internal function to claim rewards for a staked token.
    /// @param userStake The stake information of the user.
    function _claimReward(Stake storage userStake) internal {
        uint256 stakedDuration = block.timestamp - userStake.timestamp;
        uint256 rewardAmount = (stakedDuration / 1 days) * rewardRate;

        if (rewardAmount > 0) {
            require(rewardToken.balanceOf(address(this)) >= rewardAmount, "Not enough rewards in contract");

            // Update the timestamp for the next reward claim
            userStake.timestamp = block.timestamp;
            rewardToken.transfer(userStake.tokenOwner, rewardAmount);

            emit RewardClaimed(userStake.tokenOwner, rewardAmount);
        }
    }

    /// @notice Deposits rewards into the contract.
    /// @param amount The amount of rewards to deposit.
    function depositRewards(uint256 amount) external onlyOwner {
        rewardToken.transferFrom(msg.sender, address(this), amount);
    }
}
