// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlindAuction {
    struct Bidder {
        address payable addr; // 입찰자
        bytes32 blindedBid; // 해시된 입찰가
    }

    struct CheckedBidder {
        address payable addr; // 확인된 입찰자
        uint256 bid; // 확인된 입찰가
    }

    mapping(address => mapping(uint256 => uint256)) bids; // 입찰자->경매번호->입찰가
    mapping(address => mapping(uint256 => uint256)) biddersNumber; // 입찰자->경매번호->입찰자번호

    // 경매 상태 정보
    // Prebid - 0; Bidding - 1; Reveal - 2; Done - 3;
    enum Phase {
        Prebid,
        Bidding,
        Reveal,
        Done
    }

    struct Auction {
        uint256 auctionId; // 경매 번호
        address payable seller; // 판매자
        string title; // 제목
        string description; // 설명
        uint256 minimumPrice; // 최소 입찰가
        Bidder[] bidders; // 입찰자들
        CheckedBidder[] checkedBidders; // 확인된 입찰자들
        uint256 prebidderCount; // 예비입찰자 수
        address highestBidder; // 최고가 입찰자
        uint256 highestBid; // 최고가 입찰가
        Phase currentPhase; // 경매 단계(enum)
        uint256 phaseBlockNumber; // 경매단계 블록넘버
        bool isAuctionEnd; // 경매 종료여부
    }

    uint256 public numAuctions;
    Auction[] public auctions;

    // get auction bidders
    function getAuctionBidders(uint256 _auctionId)
        external
        view
        returns (Bidder[] memory)
    {
        Auction memory auction = auctions[_auctionId];
        return auction.bidders;
    }

    // get auction checked bidders
    function getAuctionCheckedBidders(uint256 _auctionId)
        external
        view
        returns (CheckedBidder[] memory)
    {
        Auction memory auction = auctions[_auctionId];
        return auction.checkedBidders;
    }

    event AuctionCreated();

    // 경매 생성
    function createAuction(
        address payable _seller,
        string memory _title,
        string memory _description,
        uint256 _minimumPrice
    ) public returns (uint256) {
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
        emit AuctionCreated();
        // return auction id
        return auction.auctionId;
    }

    event AuctionPrebid(uint256 _auctionId, address _bidder, uint256 _value);

    // 예비입찰
    function prebid(uint256 _auctionId, uint256 _value) public {
        // check valid
        Auction storage auction = auctions[_auctionId];
        require(msg.sender != auction.seller, "seller bid"); // check no seller
        require(_auctionId <= numAuctions, "wrong auction id"); // check auction id
        require(auction.currentPhase == Phase.Prebid, "phase error"); // check phase
        require(_value > auction.minimumPrice, "less than minimum price"); // check minimun price

        // push prebid
        bids[msg.sender][_auctionId] = _value;
        // increase count
        auction.prebidderCount++;
        // change phase
        if (block.number >= auction.phaseBlockNumber + 3) {
            auction.phaseBlockNumber = block.number;
            auction.currentPhase = Phase.Bidding;
        }
        // event
        emit AuctionPrebid(_auctionId, msg.sender, _value);
    }

    // 본인이 예비입찰한 가격을 확인
    function getMyBid(uint256 _auctionId) external view returns (uint256) {
        Auction memory auction = auctions[_auctionId];
        require(msg.sender != auction.seller, "seller bid"); // check no seller
        require(_auctionId <= numAuctions, "wrong auction id"); // check auction id
        return bids[msg.sender][_auctionId];
    }

    event AuctionBid(uint256 _auctionId, address _bidder, uint256 _value);

    // (본)입찰
    function bid(uint256 _auctionId) public payable {
        // check valid
        Auction storage auction = auctions[_auctionId];
        require(msg.sender != auction.seller, "seller bid"); // check no seller
        require(_auctionId <= numAuctions, "wrong auction id"); // check auction id
        require(auction.currentPhase == Phase.Bidding, "phase error"); // check phase
        require(
            msg.value == bids[msg.sender][_auctionId],
            "Not same value as the prebid"
        ); // check prebid bid value

        // hashing(address, value)
        bytes32 _blindedBid = keccak256(
            abi.encodePacked(msg.sender, msg.value)
        );
        // push bid
        auction.bidders.push(Bidder(payable(msg.sender), _blindedBid));
        // change phase
        if (auction.prebidderCount == auction.bidders.length) {
            auction.phaseBlockNumber = block.number;
            auction.currentPhase = Phase.Reveal;
        }
        if (block.number >= auction.phaseBlockNumber + 3) {
            auction.phaseBlockNumber = block.number;
            auction.currentPhase = Phase.Reveal;
        }
        // event
        emit AuctionBid(_auctionId, msg.sender, msg.value);
    }

    event NowHighestBidder(uint256 _auctionId, address _bidder, uint256 _value);
    event BidFail(uint256 _auctionId, address _bidder, uint256 _value);

    event AuctionReveal(uint256 _auctionId, address _bidder, uint256 _value);

    // 공표
    function reveal(uint256 _auctionId, uint256 _value) public {
        // check valid
        Auction storage auction = auctions[_auctionId];
        require(msg.sender != auction.seller, "seller reveal"); // check no seller
        require(_auctionId <= numAuctions, "wrong auction id"); // check auction id
        require(auction.currentPhase == Phase.Reveal, "phase error"); // check phase
        require(
            _value == bids[msg.sender][_auctionId],
            "Not same value as the prebid"
        ); // check bid value

        // check bid result
        if (placeBid(_auctionId, msg.sender, _value)) {
            emit NowHighestBidder(_auctionId, msg.sender, _value);
        } else {
            emit BidFail(_auctionId, msg.sender, _value);
        }
        // set checked bidder
        auction.checkedBidders.push(CheckedBidder(payable(msg.sender), _value));
        // change phase
        if (auction.bidders.length == auction.checkedBidders.length) {
            auction.phaseBlockNumber = block.number;
            auction.currentPhase = Phase.Done;
        }
        if (block.number >= auction.phaseBlockNumber + 3) {
            auction.phaseBlockNumber = block.number;
            auction.currentPhase = Phase.Done;
        }

        // event
        emit AuctionReveal(_auctionId, msg.sender, _value);
    }

    // 낙찰자 선별
    function placeBid(
        uint256 _auctionId,
        address _bidder,
        uint256 _value
    ) internal returns (bool success) {
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

    event Withdraw(uint256 _auctionId, address _bidder, uint256 _value);

    // 입찰금 반환
    function withdraw(uint256 _auctionId) public {
        // check valid
        Auction storage auction = auctions[_auctionId];
        require(auction.seller != msg.sender, "seller withdraw"); // check seller
        require(auction.highestBidder != msg.sender, "winner withdraw"); // check winner
        require(auction.currentPhase == Phase.Done, "phase error"); // check phase
        uint256 amount = bids[msg.sender][_auctionId];
        require(amount > 0, "No return amount"); // check withdraw amount
        // withdraw bid
        bids[msg.sender][_auctionId] = 0;
        payable(msg.sender).transfer(amount);
        // event
        emit Withdraw(_auctionId, msg.sender, amount);
    }

    event AuctionEnded(
        uint256 _auctionId,
        address _highestBidder,
        uint256 _highestBid
    );

    // 경매종료 후 셀러가 돈을 가져감
    function auctionEnd(uint256 _auctionId) public {
        // check valid
        Auction storage auction = auctions[_auctionId];
        require(msg.sender == auction.seller, "only seller"); // check only seller
        require(_auctionId <= numAuctions, "wrong auction id"); // check auction id
        require(auction.currentPhase == Phase.Done); // check phase

        // seller get highest bid
        if (address(this).balance >= auction.highestBid) {
            uint256 winningBid = auction.highestBid;
            auction.seller.transfer(winningBid);
        }
        // auction end
        auction.isAuctionEnd = true;
        // event
        emit AuctionEnded(
            _auctionId,
            auction.highestBidder,
            auction.highestBid
        );
    }

    // Testing
    function getCurrentBlockNumber() public view returns (uint256) {
        return block.number;
    }

    uint256 testingNumber;

    function generateBlock() public {
        testingNumber++;
    }
}
