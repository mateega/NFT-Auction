pragma solidity ^0.8.9;

import "hardhat/console.sol";

interface NFT {
    function mintNFT() external;
    function enterAddressIntoBook(string memory) external;

    function transferFrom(address, address, uint) external;
}

contract Auction {
    uint public startTime;
    uint public endTime;
    address payable public owner;

    address payable public highestBidder;
    uint public highestBid;

    NFT nft;
    uint nftId;

    mapping(address => uint256) public fundsPerBidder;

    event Withdrawal(uint amount, uint when);

    constructor(address _nft, uint _id) {
        nft = NFT(_nft);
        nftId = _id;
         
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "sender is not owner");
        _;
    }

    modifier isActive() {
        require(block.timestamp > startTime && startTime > 0 && endTime == 0, "Auction not yet active");
        _;
    }

    modifier isClosed() {
        require(block.timestamp > endTime && endTime > 0, "Can't close the auction until its open");
        _;
    }

    function startAuction() public /* MODIFIER(S) */ {
          require(msg.sender == owner, "sender is not owner");
          require(startTime == 0 && endTime == 0, "auction not closed");
          startTime = block.timestamp;
          endTime = startTime + 2 days;
    }

    function endAuction() public /* MODIFIER(S) */ {
      require(msg.sender == owner, "sender is not owner");
      require(startTime > 0, "auction not started");
      startTime = 0;
      endTime = 0;
    }

    function makeBid() public payable /* MODIFIER(S) */ {
      require(block.timestamp <= endTime, "Auction not yet active");
      require(fundsPerBidder[msg.sender] == 0, "sender has already bid");
      require(msg.value > highestBid, "value less than highest bid");
      fundsPerBidder[msg.sender] = msg.value;
      highestBidder = payable(msg.sender);
      highestBid = msg.value;
    }

    function upBid() public payable /* MODIFIERS(S) */ {
      uint bid = uint(fundsPerBidder[msg.sender]) + msg.value;
      require(block.timestamp <= endTime, "Auction not yet active");
      require(bid > highestBid, "value less than highest bid");
      require(fundsPerBidder[msg.sender] > 0, "sender has not previously bid");
      fundsPerBidder[msg.sender] = bid;
      highestBid = bid;
      highestBidder = payable(msg.sender);
    }

    function refund() public /* MODIFIER(S) */ {
      require(startTime == 0 && endTime == 0, "auction not closed");
      require(msg.sender != highestBidder, "highest bidder can't refund");
      uint bid = fundsPerBidder[msg.sender];
      fundsPerBidder[msg.sender] = 0;
      (bool sent, bytes memory data) = payable(msg.sender).call{value: bid}("");
      require(sent, "refund failed");
    }

    function payoutWinner() public /* MODIFIER(S) */ {
        require(msg.sender == owner, "sender is not owner");
        fundsPerBidder[highestBidder] = 0;
        nft.enterAddressIntoBook("auction");
        nft.mintNFT();
        nft.transferFrom(address(this), highestBidder, 2);
    }
}