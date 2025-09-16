// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ZeroFeeDeNFTexchange {
    // Define the order structure, which includes the owner's address and the listed price of the NFT.
    struct Order {
        address owner;
        uint256 price;
    }

    // nft Contract address => tokenId => Order
    mapping(address => mapping(uint256 => Order)) public orders;

    // NFT listing
    event Listed(address indexed nft, uint256 indexed tokenId, address indexed owner, uint256 price);
    // NFT revoked
    event Revoked(address indexed nft, uint256 indexed tokenId, address indexed owner);
    // Modify the NFT price
    event Updated(address indexed nft, uint256 indexed tokenId, address indexed owner, uint256 newPrice);
    // NFT is purchased
    event Purchased(address indexed nft, uint256 indexed tokenId, address indexed buyer, uint256 price);

    // The seller lists the order and puts the NFT on the shelf.
    function list(address nft, uint256 tokenId, uint256 price) external {
        // Ensure that the commodity price is greater than 0
        require(price > 0, "Price must be > 0");
        // Get an NFT contract instance
        IERC721 token = IERC721(nft);// token is a variable of type IERC721, which is an object pointing to the NFT contract (equivalent to an interface)
        // Ensure that the function caller is the NFT owner
        require(token.ownerOf(tokenId) == msg.sender, "Not token owner");// Operate on NFT contracts through tokens
        // Ensure that the NFT is not listed for sale.
        require(orders[nft][tokenId].owner == address(0), "Order already exists");
        // Ensure that the market contract has the permission to operate NFTs.
        require(token.isApprovedForAll(msg.sender, address(this)) || token.getApproved(tokenId) == address(this), "NFT not approved");
        // Create an order and store it
        orders[nft][tokenId] = Order({
            owner: msg.sender,
            price: price
        });
        //Trigger the pending order event
        emit Listed(nft, tokenId, msg.sender, price);
    }

    // The seller cancels the order
    function revoke(address nft, uint256 tokenId) external {
        // Get order information
        Order memory order = orders[nft][tokenId];
        // Ensure that the person canceling the order is the owner of the order.
        require(order.owner == msg.sender, "Not order owner");
        // Ensure that the order exists (if the order does not exist, a clear error can be given to prevent users from mistakenly thinking they are not the order owner)
        require(order.owner != address(0), "Order does not exist");
        // Clear the order(delete can consume less gas fees)
        delete orders[nft][tokenId];
        // Trigger a revoke event
        emit Revoked(nft, tokenId, msg.sender);
    }

    // The seller modifies the price
    function update(address nft, uint256 tokenId, uint256 newPrice) external {
        // Get order information
        Order memory order = orders[nft][tokenId];
        // Ensure that the caller is the order owner
        require(order.owner == msg.sender, "Not order owner");
        // Ensure the order exists
        require(order.owner != address(0), "Order does not exist");
        // Ensure that the new price is greater than 0
        require(newPrice > 0, "Price must be > 0");
        // Modify the order price
        orders[nft][tokenId].price = newPrice;
        // Modify the order price
        emit Updated(nft, tokenId, msg.sender, newPrice);
    }

    // Buyer's purchase
    function purchase(address nft, uint256 tokenId) external payable {
        // Get order information
        Order memory order = orders[nft][tokenId];
        // Ensure the order exists
        require(order.owner != address(0), "Order does not exist");
        // Ensure that the ETH paid is equal to the price of the order
        require(msg.value == order.price, "Incorrect payment amount");
        // Get an NFT contract instance
        IERC721 token = IERC721(nft);// token is a variable of type IERC721, which is an object pointing to the NFT contract (equivalent to an interface)
        require(token.ownerOf(tokenId) == order.owner, "Seller no longer owns this NFT" );
        //Use "seller" to record the seller's address, which facilitates understanding and reduces gas costs.
        address seller = order.owner;
        // Clear the order
        delete orders[nft][tokenId];
        // Transfer the NFT from the contract to the buyer
        IERC721(nft).transferFrom(seller, msg.sender, tokenId);
        // Transfer to the seller (no handling fee)
        payable(seller).transfer(msg.value);
        // Trigger a purchase event
        emit Purchased(nft, tokenId, msg.sender, msg.value);
    }

    // Prevent the contract from receiving ether (except when purchasing)
    receive() external payable {
        revert("Do not send ETH directly");
    }
}
