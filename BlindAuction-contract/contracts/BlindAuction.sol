// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title  Blind Auction
/// @author huke(장진수)
contract BlindAuction {
    struct Bidder {
        address payable addr;   // 입찰자
        bytes32 blindedBid;     // 해시된 입찰가
        bool revealed;          // 공표확인 여부
    }

    struct Auction {
        uint256 auctionId;          // 경매 번호
        address payable seller;     // 판매자
        string title;               // 제목
        string description;         // 설명
        uint256 minimumPrice;       // 최소 입찰가
        Bidder[] bidders;           // 입찰자들
        uint256 prebidderCount;     // 예비입찰자 수
        uint256 revealedCount;      // 공표확인 횟수
        address highestBidder;      // 최고가 입찰자
        uint256 highestBid;         // 최고가 입찰가
        Phase currentPhase;         // 경매 단계(enum)
        uint256 phaseBlockNumber;   // 경매단계 블록넘버
        bool isAuctionEnd;          // 경매 종료여부
    }

    // 경매 상태 정보
    // Prebid - 0; Bidding - 1; Reveal - 2; Done - 3;
    enum Phase {
        Prebid,
        Bidding,
        Reveal,
        Done
    }

    // 입찰자->경매번호->입찰가
    mapping(address => mapping(uint256 => uint256)) bids;
    // 입찰자->경매번호->입찰자번호
    mapping(address => mapping(uint256 => uint256)) biddersNumber;

    uint256 testingNumber;
    uint256 public numAuctions;
    Auction[] public auctions;

    // events
    // auction phase events
    event AuctionCreated();
    event AuctionPrebid(uint256 _auctionId, address _bidder, uint256 _value);
    event AuctionBid(uint256 _auctionId, address _bidder, uint256 _value);
    event AuctionReveal(uint256 _auctionId, address _bidder, uint256 _value);
    event AuctionEnded(uint256 _auctionId, address _highestBidder, uint256 _highestBid);
    // place bidders events
    event NowHighestBidder(uint256 _auctionId, address _bidder, uint256 _value);
    event BidFail(uint256 _auctionId, address _bidder, uint256 _value);
    // withdraw event
    event Withdraw(uint256 _auctionId, address _bidder, uint256 _value);

    /// @notice 경매 참가자들을 얻기 위한 함수
    /// @dev    auction id 를 통해 경매 입찰자들 정보를 가져옴
    /// @param  _auctionId auction's id
    /// @return Bidder[] return to auction by auction id
    function getAuctionBidders(uint256 _auctionId)
        external
        view
        returns (Bidder[] memory)
    {
        Auction memory auction = auctions[_auctionId];
        return auction.bidders;
    }

    // 경매 생성
    /// @notice 경매 생성 함수
    /// @dev    경매 물건 정보를 전달받아 저장
    /// @param  _seller 경매 판매자
    /// @param  _title 제목
    /// @param  _description 설명
    /// @param  _minimumPrice 최소가격
    /// @return uint256 auction id
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

    /// @notice 예비 입찰 함수
    /// @dev    value를 입력받아 bids에 address와 해시하여 저장
    /// @param  _auctionId 경매 번호
    /// @param  _value 예비입찰가
    function prebid(uint256 _auctionId, uint256 _value) public {
        // check valid
        Auction storage auction = auctions[_auctionId];
        require(msg.sender != auction.seller, "seller bid");                // check no seller
        require(_auctionId <= numAuctions, "wrong auction id");            // check auction id
        require(auction.currentPhase == Phase.Prebid, "phase error");       // check phase
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

    /// @notice 내가 입찰한 가격을 확인하는 함수
    /// @dev    bids mapping을 통해 입찰가를 확인
    /// @param  _auctionId auction id
    function getMyBid(uint256 _auctionId) external view returns (uint256) {
        Auction memory auction = auctions[_auctionId];
        require(msg.sender != auction.seller, "seller bid");        // check no seller
        require(_auctionId <= numAuctions, "wrong auction id");    // check auction id
        return bids[msg.sender][_auctionId];
    }

    /// @notice 본 입찰을 하는 함수
    /// @dev    prebid로 입력한 입찰가를 확인하고 address와 value를 해시하여 저장
    /// @param  _auctionId auction id(uint256)
    function bid(uint256 _auctionId) public payable {
        // check valid
        Auction storage auction = auctions[_auctionId];
        require(msg.sender != auction.seller, "seller bid");            // check no seller
        require(_auctionId <= numAuctions, "wrong auction id");        // check auction id
        require(auction.currentPhase == Phase.Bidding, "phase error");  // check phase
        require(                                                        // check prebid bid value
            msg.value == bids[msg.sender][_auctionId],
            "Not same value as the prebid"
        );

        // hashing(address, value)
        bytes32 _blindedBid = keccak256(
            abi.encodePacked(msg.sender, msg.value)
        );

        // push bid
        auction.bidders.push(Bidder(payable(msg.sender), _blindedBid, false));

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

    /// @notice 입찰가를 입력하고 경매결과를 산정하는 함수
    /// @dev    placeBid 함수로 낙찰자를 선정하면서 경매결과를 전달받음
    /// @param  _auctionId auction id(uint256)
    /// @param  _value 입찰가 확인(uint256)
    function reveal(uint256 _auctionId, uint256 _value) public {
        // check valid
        Auction storage auction = auctions[_auctionId];
        require(msg.sender != auction.seller, "seller reveal");         // check no seller
        require(_auctionId <= numAuctions, "wrong auction id");        // check auction id
        require(auction.currentPhase == Phase.Reveal, "phase error");   // check phase
        require(                                                        // check bid value
            _value == bids[msg.sender][_auctionId],
            "Not same value as the prebid"
        );

        // check bid result
        if (placeBid(_auctionId, msg.sender, _value)) {
            emit NowHighestBidder(_auctionId, msg.sender, _value);
        } else {
            emit BidFail(_auctionId, msg.sender, _value);
        }

        // set checked bidder
        uint256 biddersIndex = biddersNumber[msg.sender][_auctionId];
        auction.bidders[biddersIndex].revealed = true;
        auction.revealedCount++;

        // change phase
        if (auction.bidders.length == auction.revealedCount) {
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

    /// @notice 경매결과를 선별하는 함수
    /// @dev    결과값을 bool로 리턴하여 reveal에서 이벤트 호출
    /// @param  _auctionId auction id(uint256)
    /// @param  _bidder 경매 결과 확인자 주소(address)
    /// @param  _value 입찰가(uint256)
    /// @return success (bool) 경매결과
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

    /// @notice 입찰금 반환 함수
    /// @dev    낙찰자를 제외한 입찰자만 입찰금 반환 가능
    /// @param  _auctionId auction id(uint256)
    function withdraw(uint256 _auctionId) public {
        // check valid
        Auction storage auction = auctions[_auctionId];
        require(auction.seller != msg.sender, "seller withdraw");           // check seller
        require(auction.highestBidder != msg.sender, "winner withdraw");    // check winner
        require(auction.currentPhase == Phase.Done, "phase error");         // check phase
        uint256 amount = bids[msg.sender][_auctionId];
        require(amount > 0, "No return amount");                            // check withdraw amount

        // withdraw bid
        payable(msg.sender).transfer(amount);

        // event
        emit Withdraw(_auctionId, msg.sender, amount);
    }

    /// @notice 경매 판매자가 낙찰금을 가져가는 함수
    /// @dev    경매 완료단계에 낙찰금을 판매자가 가져감
    /// @param  _auctionId auction id(uint256)
    function auctionEnd(uint256 _auctionId) public {
        // check valid
        Auction storage auction = auctions[_auctionId];
        require(msg.sender == auction.seller, "only seller");        // check only seller
        require(_auctionId <= numAuctions, "wrong auction id");     // check auction id
        require(auction.currentPhase == Phase.Done);                 // check phase

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

    // 테스트를 위한 함수, 블록 3개 생성을 기준으로 경매단계가 넘어가기 때문
    function getCurrentBlockNumber() public view returns (uint256) {
        return block.number;
    }

    function generateBlock() public {
        testingNumber++;
    }
}
