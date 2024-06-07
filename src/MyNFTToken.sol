// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title MyNFTToken
/// @notice ERC721 token with discount minting and royalties, managed using Ownable2Step.
/// @dev Inherits from OpenZeppelin's ERC721, ERC721Royalty, and Ownable2Step contracts.
contract MyNFTToken is ERC721, Ownable2Step, ERC721Royalty {
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant PRICE_PER_TOKEN = 0.1 ether; // Normal mint price
    uint256 public constant DISCOUNT_PRICE = 0.05 ether; // Discounted mint price
    uint96 public constant ROYALTY_FEE_NUMERATOR = 250; // 2.5%
    uint256 public totalSupply;
    bytes32 public merkleRoot;

    BitMaps.BitMap private usedDiscounts;

    /// @notice Emitted when a token is minted.
    /// @param user The address of the user who minted the token.
    /// @param tokenId The ID of the minted token.
    event Mint(address indexed user, uint256 indexed tokenId);

    /// @notice Emitted when a token is minted using a discount.
    /// @param user The address of the user who minted the token.
    /// @param tokenId The ID of the minted token.
    event DiscountMint(address indexed user, uint256 indexed tokenId);

    /// @notice Constructor for the MyNFTToken contract.
    /// @param initialOwner The initial owner of the contract.
    /// @param _merkleRoot The merkle root for verifying discount eligibility.
    constructor(address initialOwner, bytes32 _merkleRoot) ERC721("MyNFTToken", "MYNFT") Ownable(initialOwner) {
        totalSupply = 0;
        _setDefaultRoyalty(initialOwner, ROYALTY_FEE_NUMERATOR);
        merkleRoot = _merkleRoot;
    }

    /// @notice Mints a new token.
    /// @param to The address to which the token will be minted.
    function mint(address to) external payable {
        require(totalSupply < MAX_SUPPLY, "Max supply reached");
        require(msg.value >= PRICE_PER_TOKEN, "Invalid Amount of ETH Sent");
        totalSupply++;
        _mint(to, totalSupply);
        emit Mint(msg.sender, totalSupply);
    }

    /// @notice Mints a new token at a discount price.
    /// @param proof The merkle proof for verifying discount eligibility.
    function discountedMint(bytes32[] calldata proof) external payable {
        require(totalSupply < MAX_SUPPLY, "Max supply reached");
        require(msg.value >= DISCOUNT_PRICE, "Incorrect ETH amount");
        _verifyProof(proof, msg.sender);
        require(!BitMaps.get(usedDiscounts, uint256(uint160(msg.sender))), "Discount already used");

        BitMaps.set(usedDiscounts, uint256(uint160(msg.sender)));
        totalSupply++;
        _mint(msg.sender, totalSupply);
        emit DiscountMint(msg.sender, totalSupply);
    }

    /// @notice Verifies the merkle proof for discount eligibility.
    /// @param proof The merkle proof.
    /// @param account The address being verified.
    function _verifyProof(bytes32[] calldata proof, address account) internal view {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account))));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
    }

    /// @notice Withdraws all funds to the owner's address.
    function withdrawFunds() external onlyOwner {
        uint256 funds = address(this).balance;
        payable(msg.sender).transfer(funds);
    }

    /// @notice Checks if the contract supports a specific interface.
    /// @param interfaceId The interface ID to check.
    /// @return True if the contract supports the interface, false otherwise.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
