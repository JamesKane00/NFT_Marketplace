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
    uint256 public immutable feePercent;

    mapping(uint256 => Item) public items;

    struct Item {
        IERC721 nft;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event NFTCreated(
        uint256 itemId,
        address indexed nft,
        uint256 tokenId,
        uint256 price,
        address indexed seller
    );

    event Bought(
        uint256 itemId,
        address indexed nft,
        uint256 tokenId,
        uint256 price,
        address indexed seller,
        address indexed buyer
    );

    constructor(uint256 _feePercent) {
        feeAccount = payable(msg.sender);
        feePercent = _feePercent;
    }

    function createNFT(
        IERC721 _nft,
        uint256 _tokenId,
        uint256 _price
    ) external nonReentrant {
        require(_price > 0, "Price must be greater than zero");
        // increment item count
        _itemCount.increment();
        uint256 itemId = _itemCount.current();
        // transfer NFT using ERC721 functionality
        _nft.transferFrom(msg.sender, address(this), _tokenId);
        // add new nft to items mapping
        items[_tokenId] = Item(
            _nft,
            _tokenId,
            payable(msg.sender),
            payable(address(0)),
            _price,
            false
        );

        emit NFTCreated(itemId, address(_nft), _tokenId, _price, msg.sender);
    }

    function getTotalPrice(uint256 _itemId) public view returns (uint256) {
        return ((items[_itemId].price * (100 + feePercent)) / 100);
    }

    function purchaseNFT(uint256 _itemId) public payable nonReentrant {
        uint256 _totalPrice = getTotalPrice(_itemId);
        Item storage item = items[_itemId];
        require(
            msg.value >= _totalPrice,
            "not enough ether to cover item price and market fee"
        );
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

    function fetchUnsoldNFTs() public view returns (Item[] memory) {
        // variables:

        // All NFTs (items)
        uint256 nftCount = _itemCount.current();
        // Unsold NFTS (items), All - Sold
        uint256 unsoldNFTs = _itemCount.current() - _itemsSold.current();
        // index of unsold NFTs
        uint256 unsoldIndex = 0;

        Item[] memory items = new Item[](unsoldNFTs);
        // Loop over Item Array
        for (uint256 i; i < nftCount; i++) {
            // Check for owners that are equal to the empty address
            if (items[i + 1].owner == address(0)) {
                // new variable: itemId of item of the unsold item
                uint256 currentId = items[i + 1].tokenId;
                // assign fetched id to storage (Item struct mapping)
                Item storage currentItem = items[currentId];
                // Assign this item to unsold items index
                items[unsoldIndex] = currentItem;
                // Increment index
                unsoldIndex += 1;
            }
        }
        return items;
    }

    function fetchMyNFTs() public view returns (Item[] memory) {
        // Variables;

        // all item ids
        uint256 totalItemCount = _itemCount.current();
        // count of my items
        uint256 myItemCount = 0;
        // index of my items
        uint256 myItemIndex = 0;
        // for loop, loop through all ids and check for ones that match the users
        for (uint256 i = 0; i < totalItemCount; i++) {
            // if there's a match, increment count by 1
            if (items[i + 1].owner == msg.sender) {
                myItemCount += 1;
            }
            // Initialize new array for my NFTs
            Item[] memory items = new Item[](myItemCount);
            // for loop: if ids within items array are equal to user's address
            for (uint256 i = 0; i < totalItemCount; i++) {
                if (items[i + 1].owner == msg.sender) {
                    // assigns id of nft to new local variable
                    uint256 myItemId = items[i + 1].tokenId;
                    // use that id to reference the item struct in storage
                    Item[] storage myCurrentItem = items[myItemId];
                    // add nft(s) to array of my items
                    items[myItemIndex] = myCurrentItem;

                    myItemIndex += 1;
                }
            }
        }
    }
}
