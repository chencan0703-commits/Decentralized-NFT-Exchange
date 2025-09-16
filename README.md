# Decentralized-NFT-Exchange
This project uses smart contracts to build a zero-fee decentralized NFT exchange, with the main logic as follows:
- Seller: The party selling the NFT, which can list, revoke, and update the price.
- Buyer: The party purchasing the NFT, which can make a purchase.
- Order: An on-chain order for an NFT issued by the seller. There can be at most one order for the same token ID in a collection, which includes information such as the listing price and the owner. When an order is completed or revoked, the information in it is cleared.
