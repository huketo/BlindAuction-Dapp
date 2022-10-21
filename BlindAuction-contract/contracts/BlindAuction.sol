// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlindAuction {

  struct Bidder {
    address payable addr;                           // 입찰자
    bytes32 blindedBid;                             // 해시된 입찰가
  }

  mapping(address => mapping(uint => uint)) bid;    // 입찰가

  // 경매 상태 정보
  // Prebid - 0; Bidding - 1; Reveal - 2; Done - 3;
  enum Phase { Prebid, Bidding, Reveal, Done }

  struct Auction {
    uint auctionId;               // 경매 번호
    address payable seller;       // 판매자
    string title;                 // 제목
    string description;           // 설명
    uint minimumPrice;            // 최소 입찰가

    Bidder[] bidders;             // 입찰자들
    address highestBidder;        // 최고가 입찰자
    uint highestBid;              // 최고가 입찰가

    Phase currentPhase;           // 경매 단계(enum)
    uint phaseBlockNumber;        // 경매단계 블록넘버
  }

  uint numAuctions;
  Auction[] auctions;

  // // 경매단계 확인
  // modifier validPhase(Phase reqPhase) {
  //   require(currentPhase == reqPhase, "phaseError");
  //   _;
  // }

  // // 판매자 확인
  // modifier onlySeller() {
  //   require(msg.sender == seller, "onlySeller");
  //   _;
  // }

  // // 최소입찰가 확인
  // modifier isMinimum(uint value) {
  //   require(value >= minimumBid, "Less than minimumBid");
  //   _;
  // }

  // function changePhase() public {
  //   if (block.number >= phaseBlockNumber + 9) {
  //     uint nextPhase = uint(currentPhase) + 1;
  //     currentPhase = Phase(nextPhase);
  //     phaseBlockNumber = block.number;
  //   }
    
  //   if (currentPhase == Phase.Prebid) emit Prebidding();
  //   if (currentPhase == Phase.Bidding) emit Bidding();
  //   if (currentPhase == Phase.Reveal) emit Revealing();
  // }

  event AuctionCreated(
    address _seller,
    string _title,
    string _description,
    uint _minimumPrice
  );

  // 경매 생성
  function createAuction(
    address payable _seller,
    string memory _title,
    string memory _description,
    uint _minimumPrice
  ) public returns (uint) {
    // create auction
    auctions.push();
    Auction storage auction = auctions[numAuctions];
    // put auction data
    auction.auctionId = numAuctions;
    auction.seller = _seller;
    auction.title = _title;
    auction.description = _description;
    auction.minimumPrice = _minimumPrice;
    auction.phaseBlockNumber = block.number;
    // increase auction count
    numAuctions++;
    // event
    emit AuctionCreated(
      _seller,
      _title,
      _description,
      _minimumPrice
    );
    // return auction id
    return auction.auctionId;
  }

  event AuctionPrebid(
    uint _auctionId,
    address indexed _bidder,
    uint _value
  );

  // 예비입찰
  function prebid(uint _auctionId, uint _value) public {
    // require
    require(_auctionId <= numAuctions, "wrong auction id");

    Auction storage auction = auctions[_auctionId];
    require(auction.currentPhase == Phase.Prebid, "phase error");
    require(_value > auction.minimumPrice, "less than minimum price");
    // hashing(address, value)
    bytes32 _blindedBid = keccak256(abi.encodePacked(msg.sender, _value));
    // push prebid
    auction.bidders.push(
      Bidder(payable(msg.sender), _blindedBid)
    );
    // event
    emit AuctionPrebid(_auctionId, msg.sender, _value);
  }

  // 본인이 예비입찰한 가격을 확인
  // function getMyBid() external view returns (uint) {
  //   return bids[msg.sender];
  // }

  // (본)입찰
  // function bid() public payable validPhase(Phase.Bidding) isMinimum(msg.value) {
  //   require(msg.sender != seller, "seller bid");
  //   require(msg.value == bids[msg.sender], "Not same value as the prebid");

  //   bytes32 blindedBid = keccak256(abi.encodePacked(msg.sender, msg.value));
  //   blindedBids[msg.sender] = blindedBid;

  //   payedBidderCount += 1;
  //   changePhase();
  //   if (preBidderCount == payedBidderCount) {
  //     currentPhase = Phase.Reveal;
  //   }
  // }

  // 공표
  // function reveal(uint value) public validPhase(Phase.Reveal) isMinimum(value) {
  //   require(msg.sender != seller, "seller reveal");
  //   require(value == bids[msg.sender], "Not same value as the bid");

  //   if (placeBid(msg.sender, value)) {
  //     emit BidSuccess();
  //   } else {
  //     emit BidFail();
  //     withdraw();
  //   }

  //   if (payedBidderCount <= 1) {
  //     currentPhase = Phase.Done;
  //   }
  //   changePhase();
  // }

  // 낙찰자 선별
  // function placeBid(address bidder, uint value) internal returns (bool success) {
  //   if (highestBidder != address(0)) {
  //     if (value <= highestBid) {
  //       pendingReturns[bidder] = value;
  //       return false;
  //     }
  //   }
    
  //   highestBid = value;
  //   highestBidder = bidder;
    
  //   return true;
  // }

  // 입찰금 반환
  // function withdraw() public {
  //   if (currentPhase == Phase.Reveal) {
  //     uint amount = pendingReturns[msg.sender];
  //     require(amount > 0, "No return amount");

  //     payedBidderCount -= 1;
  //     pendingReturns[msg.sender] = 0;
  //     payable(msg.sender).transfer(amount);
  //   } else if (currentPhase == Phase.Done) {
  //     uint _amount = bids[msg.sender];
  //     require(_amount > 0, "No return amount");

  //     bids[msg.sender] = 0;
  //     payable(msg.sender).transfer(_amount);
  //   }
  // }

  // 경매종료 후 셀러가 돈을 가져감
  // function auctionEnd() public validPhase(Phase.Done) onlySeller() {
  //   if(address(this).balance >= highestBid) {
  //     uint winningBid = highestBid;
  //     highestBid = 0;
  //     seller.transfer(winningBid);
  //   }
  //   emit AuctionEnded(highestBidder, highestBid);
  // }

  // function returnContents() public view returns (string memory, string memory, uint, Phase) {
  //   return (title, description, minimumBid, currentPhase);
  // }

  // // Testing
  // function getCurrentBlockNumber() public view returns(uint) {
  //   return block.number;
  // }
}
