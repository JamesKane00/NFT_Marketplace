// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenCount;
    address contractAddress;

    constructor(address marketplaceAddress) ERC721("Chain NFTs", "CHAINFT"){
        contractAddress = marketplaceAddress;
    }
    function mint(string memory _tokenURI) external returns(uint) {
        _tokenCount.increment();
        uint256 newItemId = _tokenCount.current();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        setApprovalForAll(contractAddress, true);
        return(newItemId);
    }
}