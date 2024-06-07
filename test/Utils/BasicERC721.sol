// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicERC721 is ERC721 {
    uint256 public nextTokenId = 1;

    constructor() ERC721("BasicERC721", "B721") {}

    function mint(address to) external {
        _mint(to, nextTokenId);
        nextTokenId++;
    }
}
