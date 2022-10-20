// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract BlindAuctionList {
  BlindAuction[] public auctions;

  function createAuction(string memory _title, string memory _description, uint _minimumBid) public {
    BlindAuction newAuction = new BlindAuction(payable(msg.sender), _title, _description, _minimumBid);
    auctions.push(newAuction);
  }

  function returnAllAuctions() public view returns(BlindAuction[] memory) {
    return auctions;
  }
}

contract BlindAuction {
  
  address payable public seller; // 판매자
  string public title; // 제목
  string public description; // 설명
  uint public minimumBid; // 최소 입찰가
  
  uint public phaseBlockNumber; // 매물 등록 시 블록넘버
  
  address public highestBidder; // 최고가 입찰자
  uint public highestBid; // 최고가 입찰가
  
  mapping(address => bytes32) public blindedBids; // 각 입찰자 별 해시 입찰가
  mapping(address => uint) bids; // 각 입찰자 별 입찰가
  mapping(address => uint) pendingReturns; // 낙찰 실패자들 반환보증금


  // 경매 상태 정보
  // Init - 0; Prebid - 1; Bidding - 2; Reveal - 3; Done - 4;
  // costructor에서 Prebid로 넘어감, 이후 block.number에서 따라 넘어감.
  enum Phase { Init, Prebid, Bidding, Reveal, Done }
  Phase public currentPhase;

  // events
  event AuctionInit();
  event PrebidStarted();
  event BiddingStarted();
  event RevealStarted();
  event AuctionEnded(address _winner, uint _highestBid);

  event BidSuccess();
  event BidFail();

  // 경매단계 확인
  modifier validPhase(Phase reqPhase) {
    require(currentPhase == reqPhase, "phaseError");
    _;
  }

  // 판매자 확인
  modifier onlySeller() {
    require(msg.sender == seller, "onlySeller");
    _;
  }

  // 최소입찰가 확인
  modifier isMinimum(uint value) {
    require(value >= minimumBid, "Less than minimumBid");
    _;
  }

  // BlindAuctionList에서 createAuction으로 생성했을 때 필요한 정보를 입력
  constructor(address payable _seller, string memory _title, string memory _description, uint _minimumBid) {
    seller = _seller;
    title = _title;
    description = _description;
    minimumBid = _minimumBid;
    phaseBlockNumber = block.number;
    currentPhase = Phase.Prebid;
  }

  function getCurrentBlockNumber() public view returns(uint) {
    return block.number;
  }

  // Testing
  uint a;
  function generateBlockTest() public {
    a++;
  }

  function changePhase() public {
    if (currentPhase == Phase.Done) {
      currentPhase = Phase.Init;
    } else {
      if (block.number > phaseBlockNumber + 10) {
        uint nextPhase = uint(currentPhase) + 1;
        currentPhase = Phase(nextPhase);
        phaseBlockNumber = block.number;
      }
    }

    if (currentPhase == Phase.Init) emit AuctionInit();
    if (currentPhase == Phase.Prebid) emit PrebidStarted();
    if (currentPhase == Phase.Bidding) emit BiddingStarted();
    if (currentPhase == Phase.Reveal) emit RevealStarted();
  }

  // 예비입찰
  function prebid(uint value) public validPhase(Phase.Prebid) isMinimum(value) {
    require(msg.sender != seller, "seller prebid");

    bids[msg.sender] = value;
  }

  // 본인이 예비입찰한 가격을 확인
  function getMyBid() external view returns (uint) {
    return bids[msg.sender];
  }

  // (본)입찰
  function bid() public payable validPhase(Phase.Bidding) isMinimum(msg.value) {
    require(msg.sender != seller, "seller bid");
    require(msg.value == bids[msg.sender], "Not same value as the prebid");

    bytes32 blindedBid = keccak256(abi.encodePacked(msg.sender, msg.value));
    blindedBids[msg.sender] = blindedBid;
  }

  // 공표
  function reveal(uint value) public validPhase(Phase.Reveal) isMinimum(value) returns (bool) {
    require(msg.sender != seller, "seller reveal");
    require(value == bids[msg.sender], "Not same value as the bid");

    if (placeBid(msg.sender, value)) {
      emit BidSuccess();
      return true;
    } else {
      emit BidFail();
      return false;
    }
  }

  // 낙찰자 선별
  function placeBid(address bidder, uint value) internal returns (bool success) {
    if (value <= highestBid) {
      return false;
    }
    if (highestBidder != address(0)) {
      pendingReturns[highestBidder] += highestBid;
    }
    highestBid = value;
    highestBidder = bidder;
    return true;
  }

  // 입찰금 반환
  function withdraw() public payable {
    uint amount = pendingReturns[msg.sender];
    require(amount > 0, "No return amount");
    pendingReturns[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
  }

  // 경매종료 후 셀러가 돈을 가져감
  function auctionEnd() public payable validPhase(Phase.Done) {
    if(address(this).balance >= highestBid) {
      uint winningBid = highestBid;
      highestBid = 0;
      seller.transfer(winningBid);
    }
    emit AuctionEnded(highestBidder, highestBid);
    changePhase(); // Init로 전환.
  }

  function returnContents() public view returns (string memory, string memory, uint, Phase) {
    return (title, description, minimumBid, currentPhase);
  }
}
