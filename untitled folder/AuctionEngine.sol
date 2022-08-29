// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract AuctionEngine is Ownable {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    event AuctionCreated(uint256 _index, address _creator, address _asset,uint256 _assetid,uint256 _starttime,uint256 _duration);
    event AuctionBid(uint256 _index, address _bidder, uint256 amount);
    event Claim(uint256 auctionIndex, address claimer);

    enum Status { pending, active, finished }
    Counters.Counter private contractid;

    struct Auction {
        address assetAddress;
        uint256 assetId;

        address creator;

        uint256 startTime;
        uint256 duration;
        uint256 currentBidAmount;
        address currentBidOwner;
        uint256 bidCount;
    }
    mapping (uint256 => Auction) Auctioncontract;
    mapping(address => bool)whitelistedroleaddress; 

    bool ispublic;   

    function createAuction(address _assetAddress,
                           uint256 _assetId,
                           uint256 _startPrice,
                           uint256 _startTime,
                           uint256 _duration) public returns (uint256) {

        require(_assetAddress.isContract());
        require(_startPrice != 0);
        require(whitelistedroleaddress[msg.sender] == true);
        ERC721 asset = ERC721(_assetAddress);
        require(asset.ownerOf(_assetId) == msg.sender);
        require(asset.getApproved(_assetId) == address(this));


        if (_startTime == 0) { _startTime = block.timestamp; }

       Auctioncontract[contractid.current()]  = Auction({
            creator: msg.sender,
            assetAddress: _assetAddress,
            assetId: _assetId,
            startTime: _startTime,
            duration: _duration,
            currentBidAmount: _startPrice,
            currentBidOwner: address(0),
            bidCount: 0
        });

        // we transfer the asset to this contract
       uint256 index = contractid.current();

       ERC721(_assetAddress).transferFrom(msg.sender,address(this),_assetId);
       

        emit AuctionCreated(index, msg.sender, _assetAddress,_assetId,_startTime,_duration);

        return index;
    }

    function bid(uint256 auctionIndex) public payable returns (bool) {
        Auction storage auction = Auctioncontract[auctionIndex];
        require(auction.creator != address(0));
        require(isActive(auctionIndex));

        if (auction.currentBidAmount != 0) {

            require(msg.value > auction.currentBidAmount);
            // we got a better bid. Return tokens to the previous best bidder
            // and register the sender as `currentBidOwner`
            if(getBidCount(auctionIndex)!= 0){
            
             // return funds to the previuos bidder
            payable(auction.currentBidOwner).transfer(auction.currentBidAmount);
            
            }
               // register new bidder
            auction.currentBidAmount = msg.value;
            auction.currentBidOwner = msg.sender;
            auction.bidCount = auction.bidCount.add(1);
            
            
            emit AuctionBid(auctionIndex, msg.sender,msg.value);
            return true;
            
        }
        return false;
    }

    function getTotalAuctions() public view returns (uint256) { return contractid.current() ;}

    function isActive(uint256 index) public view returns (bool) { return getStatus(index) == Status.active; }

    function isFinished(uint256 index) public view returns (bool) { return getStatus(index) == Status.finished; }

    function getStatus(uint256 index) public view returns (Status) {
        Auction storage auction = Auctioncontract[index];
        if (block.timestamp < auction.startTime) {
            return Status.pending;
        } else if (block.timestamp < auction.startTime.add(auction.duration)) {
            return Status.active;
        } else {
            return Status.finished;
        }
    }

    function getCurrentBidOwner(uint256 auctionIndex) public view returns (address) { return Auctioncontract[auctionIndex].currentBidOwner; }

    function getCurrentBidAmount(uint256 auctionIndex) public view returns (uint256) { return Auctioncontract[auctionIndex].currentBidAmount; }

    function getBidCount(uint256 auctionIndex) public view returns (uint256) { return Auctioncontract[auctionIndex].bidCount; }

    function getWinner(uint256 auctionIndex) public view returns (address) {
        require(isFinished(auctionIndex));
        return Auctioncontract[auctionIndex].currentBidOwner;
    }

    function claimETH(uint256 auctionIndex) public {
        require(isFinished(auctionIndex));
        Auction storage auction = Auctioncontract[auctionIndex];

        require(auction.creator == msg.sender);
        
        payable(auction.creator).transfer(auction.currentBidAmount);

        emit Claim(auctionIndex, auction.creator);
    }

    function sendAsset(uint256 auctionIndex) public onlyOwner{
        require(isFinished(auctionIndex));
        Auction storage auction = Auctioncontract[auctionIndex];

        address winner = getWinner(auctionIndex);

        ERC721 asset = ERC721(auction.assetAddress);
        asset.transferFrom(address(this), winner, auction.assetId);

        emit Claim(auctionIndex, winner);
    }

    function whitelistaddress(address _address) public onlyOwner{
        whitelistedroleaddress[_address] = true;
    }
}