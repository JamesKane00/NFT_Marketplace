// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemCount;
    Counters.Counter private _itemsSold;

    // Variables
    address payable public immutable feeAccount;
    uint public immutable feePercent;

    mapping (uint256 => Item) public items;

    struct Item {
        IERC721 nft;
        uint tokenId;
        address payable seller;
        address payable owner;
        uint price;
        bool sold;
    }


    event NFTCreated (
        uint itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller
    );

    event Bought (
        uint itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed buyer

    );

    constructor (uint _feePercent) {
        feeAccount = payable(msg.sender); 
        feePercent = _feePercent;
    }

    function createNFT (IERC721 _nft, uint _tokenId, uint price) external nonReentrant {
        require (price > 0, "Price must be greater than zero");
        // increment item count
        _itemCount.increment();
        uint256 itemId = _itemCount.current();
        // transfer NFT using ERC721 functionality
        _nft.transferFrom(msg.sender, address(this), _tokenId);
        // add new nft to items mapping
        items[_tokenId] = Item ( 
            _nft,
            _tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        emit NFTCreated (
            itemId,
            address(_nft),
            _tokenId,
            price,
            msg.sender
        ); 

    }

    function getTotalPrice(uint _itemId) public view returns(uint){
        return((items[_itemId].price*(100 + feePercent))/100);
    }

    function purchaseNFT(uint _itemId) public payable nonReentrant {
        uint _totalPrice = getTotalPrice(_itemId);
        Item storage item = items[_itemId];
        require(msg.value >= _totalPrice, "not enough ether to cover item price and market fee");
        require(!item.sold, "item already sold");
        // pay seller and feeAccount
        item.seller.transfer(msg.value);
        feeAccount.transfer(_totalPrice - item.price);
        // update item to sold
        item.sold = true;
        // transfer nft to buyer
        item.nft.transferFrom(address(this), msg.sender, item.tokenId);
        // emit Bought event
        emit Bought(
            _itemId,
            address(item.nft),
            item.tokenId,
            item.price,
            item.seller,
            msg.sender
        );
    }
    }


