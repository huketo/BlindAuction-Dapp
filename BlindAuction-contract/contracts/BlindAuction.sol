// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract BlindAuction {
  struct Bid {
    bytes32 blindedBid; // 비공개 입찰가
    uint deposit; // 보증금
  }

// 경매 상태 정보
// Init - 0; Bidding - 1; Reveal - 2; Done - 3;
  enum Phase { Init, Bidding, Reveal, Done }
  Phase public state = Phase.Init;

  address payable public seller; // 판매자
  uint public minimumBid; // 최소 입찰가
  mapping(address => Bid) public bids; // 각 입찰자 별 입찰정보
  
  address public highestBidder; // 최고가 입찰자
  uint public highestBid; // 최고가 입찰가

  mapping(address => uint) depositReturns; // 낙찰 실패자들 반환보증금

  uint public firstBlockNumber; // 매물 등록 시 블록넘버
  // uint latestBlockNumber; // 최신 블록넘버

  // 경매단계 확인
  modifier validPhase(Phase reqPhase) {
    require(state == reqPhase);
    _;
  }

  // 판매자 확인
  modifier onlySeller() {
    require(msg.sender == seller);
    _;
  }

  // 최소입찰가 확인
  modifier isMinimun(uint value) {
    require(value >= minimumBid, "Less than minimumBid");
    _;
  }


  constructor(uint _minimumBid) {
    seller = payable(msg.sender);
    state = Phase.Bidding; 
    minimumBid = _minimumBid;
    firstBlockNumber = block.number;
  }

  function changeState(Phase x) public onlySeller {
    require(x > state, "Unable to return the previous state");
    state = x;
  }


  function bid(bytes32 blindBid) public payable validPhase(Phase.Bidding) {
    bids[msg.sender] = Bid({
      blindedBid: blindBid,
      deposit: msg.value
    });
  }

  function reveal(uint value, bytes32 secrect) public validPhase(Phase.Reveal) isMinimun(value) {
    uint refund;
    Bid storage bidToCheck = bids[msg.sender];
    bytes32 checkBid = keccak256(abi.encodePacked(value, secrect));
    if (bidToCheck.blindedBid == checkBid) {
      refund += bidToCheck.deposit;
    }
    if (bidToCheck.deposit >= value) {
      if (placeBid(msg.sender, value)) {
        refund -= value;
      }
    }
  }

  function placeBid(address bidder, uint value) internal isMinimun(value) returns (bool success) {
    if (value <= highestBid) {
      return false;
    }
    if (highestBidder != address(0)) {
      depositReturns[highestBidder] += highestBid;
    }
    highestBid = value;
    highestBidder = bidder;
    return true;
  }

  function withdraw() public payable {
    uint amount = depositReturns[msg.sender];
    require(amount > 0, "No return amount");
    depositReturns[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
  }

  function auctionEnd() public payable validPhase(Phase.Done) {
    seller.transfer(highestBid);
  }
}
