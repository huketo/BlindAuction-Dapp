// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlindAuction {

  struct Bidder {
    address payable addr;                                   // 입찰자
    bytes32 blindedBid;                                     // 해시된 입찰가
  }

  mapping(address => mapping(uint => uint)) bids;           // 입찰자->경매번호->입찰가
  mapping(address => mapping(uint => uint)) biddersNumber;  // 입찰자->경매번호->입찰자번호

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
    uint prebidderCount;          // 예비입찰자 수
    uint bidderCount;             // 입찰자 수
    uint revealCount;             // 공표확인 수
    address highestBidder;        // 최고가 입찰자
    uint highestBid;              // 최고가 입찰가

    Phase currentPhase;           // 경매 단계(enum)
    uint phaseBlockNumber;        // 경매단계 블록넘버
    bool isAuctionEnd;            // 경매 종료여부
  }

  uint public numAuctions;
  Auction[] public auctions;

  // get auction bidders
  function getAuctionBidders(uint _auctionId) external view returns(Bidder [] memory) {
    Auction memory auction = auctions[_auctionId];
    return auction.bidders;
  }

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
    address _bidder,
    uint _value
  );

  // 예비입찰
  function prebid(uint _auctionId, uint _value) public {
    // check valid
    Auction storage auction = auctions[_auctionId]; 
    require(msg.sender != auction.seller, "seller bid");                // check no seller
    require(_auctionId <= numAuctions, "wrong auction id");             // check auction id
    require(auction.currentPhase == Phase.Prebid, "phase error");       // check phase
    require(_value > auction.minimumPrice, "less than minimum price");  // check minimun price
    
    // push prebid
    bids[msg.sender][_auctionId] = _value;
    // increase count
    auction.prebidderCount++;
    // change phase
    if (block.number >= auction.phaseBlockNumber + 10) {
      auction.phaseBlockNumber = block.number;
      auction.currentPhase = Phase.Bidding;
    }
    // event
    emit AuctionPrebid(_auctionId, msg.sender, _value);
  }

  // 본인이 예비입찰한 가격을 확인
  function getMyBid(uint _auctionId) external view returns (uint) {
    Auction memory auction = auctions[_auctionId];
    require(msg.sender != auction.seller, "seller bid");                // check no seller
    require(_auctionId <= numAuctions, "wrong auction id");             // check auction id
    return bids[msg.sender][_auctionId];
  }

  event AuctionBid(uint _auctionId, address _bidder, uint _value);

  // (본)입찰
  function bid(uint _auctionId) public payable {
    // check valid
    Auction storage auction = auctions[_auctionId];
    require(msg.sender != auction.seller, "seller bid");                                // check no seller
    require(_auctionId <= numAuctions, "wrong auction id");                             // check auction id
    require(auction.currentPhase == Phase.Bidding, "phase error");                      // check phase
    require(msg.value == bids[msg.sender][_auctionId], "Not same value as the prebid"); // check prebid bid value

    // hashing(address, value)
    bytes32 _blindedBid = keccak256(abi.encodePacked(msg.sender, msg.value));
    // push bid
    auction.bidders.push(
      Bidder(payable(msg.sender), _blindedBid)
    );
    // increase count
    auction.bidderCount++;
    // change phase
    if (auction.prebidderCount == auction.bidderCount) {
      auction.phaseBlockNumber = block.number;
      auction.currentPhase = Phase.Reveal;
    } 
    if (block.number >= auction.phaseBlockNumber + 10) {
      auction.phaseBlockNumber = block.number;
      auction.currentPhase = Phase.Reveal;
    }
    // event
    emit AuctionBid(_auctionId, msg.sender, msg.value);
  }

  event NowHighestBidder(uint _auctionId, address _bidder, uint _value);
  event BidFail(uint _auctionId, address _bidder, uint _value);

  event AuctionReveal(uint _auctionId, address _bidder, uint _value);
  // 공표
  function reveal(uint _auctionId , uint _value) public {
    // check valid
    Auction storage auction = auctions[_auctionId];
    require(msg.sender != auction.seller, "seller reveal");                             // check no seller
    require(_auctionId <= numAuctions, "wrong auction id");                             // check auction id
    require(auction.currentPhase == Phase.Reveal, "phase error");                       // check phase
    require(_value == bids[msg.sender][_auctionId], "Not same value as the prebid");    // check bid value

    // check bid result
    if (placeBid(_auctionId, msg.sender, _value)) {
      emit NowHighestBidder(_auctionId, msg.sender, _value);
    } else {
      emit BidFail(_auctionId, msg.sender, _value);
      // withdraw
      withdraw(_auctionId, msg.sender);
    }
    // increase count
    auction.revealCount++;
    // change phase
    if (auction.bidderCount == auction.revealCount) {
      auction.phaseBlockNumber = block.number;
      auction.currentPhase = Phase.Done;
    } 
    if (block.number >= auction.phaseBlockNumber + 10) {
      auction.phaseBlockNumber = block.number;
      auction.currentPhase = Phase.Done;
    }
    // rest bidder withdraw
    if (auction.currentPhase == Phase.Done) {
      if (auction.bidders.length > 0) {
        for (uint i = 0; i < auction.bidders.length; i++) {
          if (auction.highestBidder != auction.bidders[i].addr) {
            withdraw(_auctionId, auction.bidders[i].addr);
          }
        }
      }
    }
    // event
    emit AuctionReveal(_auctionId, msg.sender, _value);
  }

  // 낙찰자 선별
  function placeBid(uint _auctionId, address _bidder, uint _value) internal returns (bool success) {
    Auction storage auction = auctions[_auctionId];
    if (auction.highestBidder != address(0)) {
      if (_value <= auction.highestBid) {
        return false;
      } 
    }
    // set highest bid & bidder
    auction.highestBid = _value;
    auction.highestBidder = _bidder;


    return true;
  }

  event Withdraw(uint _auctionId, address _bidder, uint _value);
  // 입찰금 반환
  function withdraw(uint _auctionId, address _bidder) public {
    // check valid
    Auction storage auction = auctions[_auctionId];
    require(auction.currentPhase == Phase.Reveal || auction.currentPhase == Phase.Done, "phase error");         // check phase
    uint amount = bids[_bidder][_auctionId];
    require(amount > 0, "No return amount");                                                                    // check withdraw amount
    // bidders pop
    uint _index = biddersNumber[_bidder][_auctionId];
    auction.bidders[_index] = auction.bidders[auction.bidders.length - 1];
    auction.bidders.pop();
    // withdraw bid
    bids[_bidder][_auctionId] = 0;
    payable(_bidder).transfer(amount);
    // event
    emit Withdraw(_auctionId, _bidder, amount);
  }

  event AuctionEnded(uint _auctionId, address _highestBidder, uint _highestBid);
  // 경매종료 후 셀러가 돈을 가져감
  function auctionEnd(uint _auctionId) public {
    // check valid
    Auction storage auction = auctions[_auctionId];
    require(msg.sender == auction.seller, "only seller");           // check only seller
    require(_auctionId <= numAuctions, "wrong auction id");         // check auction id
    require(auction.currentPhase == Phase.Done);                    // check phase

    // seller get highest bid
    if(address(this).balance >= auction.highestBid) {
      uint winningBid = auction.highestBid;
      auction.highestBid = 0;
      auction.seller.transfer(winningBid);
    }
    // auction end
    auction.isAuctionEnd = true;
    // event
    emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBid);
  }

  // Testing 
  function getCurrentBlockNumber() public view returns(uint) {
    return block.number;
  }

  uint testingNumber;
  function generateBlock() public {
    testingNumber++;
  }
}