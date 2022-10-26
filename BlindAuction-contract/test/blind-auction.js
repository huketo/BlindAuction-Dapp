const BlindAuction = artifacts.require("BlindAuction");
const truffleAssert = require("truffle-assertions");
const assert = require("chai").assert;

contract("BlindAuction", (accounts) => {
  const success = "0x01";
  let blindAuction;
  // error 설정
  const onlySellerError = "Only seller can perform this action";
  const onlyBidderError = "Only bidder can perform this action";
  const validPhaseError = "Invalid phase";
  const badBidError = "not matching prebid";
  const badRevealError = "not matching bid";

  // Account 설정
  const sellerAddress = accounts[1];
  const firstBidderAddress = accounts[2];
  const secondBidderAddress = accounts[3];
  const thirdBidderAddress = accounts[4];

  // bid 설정
  let BID1 = 1000;
  let BID2 = 1200;
  let BID3 = 800;

  // Auction 설정
  let createAuction;
  let auction;
  const auctionTitle = "Title_01";
  const auctionDescription = "Description_01";
  const auctionMinimumPrice = 500;
  // phase 설정
  const prebidPhase = 0;
  const bidPhase = 1;
  const revealPhase = 2;
  const donePhase = 3;

  beforeEach("Setup contract for each test", async () => {
    blindAuction = await BlindAuction.new();

    // auction create
    createAuction = await blindAuction.createAuction(
      sellerAddress,
      auctionTitle,
      auctionDescription,
      auctionMinimumPrice
    );
    // created auction
    auction = await blindAuction.auctions(0);
  });

  describe("Auction Created.", async () => {
    it("Success Created.", async function () {
      // check created auction
      assert.equal(auction.auctionId, 0);
      assert.equal(auction.seller, sellerAddress);
      assert.equal(auction.title, auctionTitle);
      assert.equal(auction.description, auctionDescription);
      assert.equal(auction.minimumPrice, auctionMinimumPrice);
    });
  });

  describe("Prebid Phase.", async () => {
    it("Success on single prebid.", async function () {
      // Prebidding
      await blindAuction.prebid(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // After Prebidding
      auction = await blindAuction.auctions(0);
      /* check prebidder count */
      assert.equal(auction.prebidderCount, 1);
      /* check prebid */
      let myBid = await blindAuction.getMyBid(auction.auctionId, {
        from: firstBidderAddress,
      });
      assert.equal(BID1, myBid);
    });

    it("Failure on prebid smaller minimum price.", async function () {
      // prebid - value error
      truffleAssert.fails(
        blindAuction.prebid(auction.auctionId, 300, {
          from: firstBidderAddress,
        }),
        truffleAssert.ErrorType.REVERT,
        null,
        "minimum price error"
      );
    });

    it("Failure on prebid different phase.", async function () {
      // Block generate 3
      for (let i = 0; i < 3; i++) {
        await blindAuction.generateBlock();
      }
      // first bidder prebid -> Phase change(Bidding)
      await blindAuction.prebid(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // check change phase
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, bidPhase);
      // prebid - phase error
      await truffleAssert.fails(
        blindAuction.prebid(auction.auctionId, String(BID2), {
          from: secondBidderAddress,
        }),
        truffleAssert.ErrorType.REVERT,
        null,
        validPhaseError
      );
    });
  });

  describe("Bid Phase.", async () => {
    it("Success on single bid.", async function () {
      // Block generate 3
      for (let i = 0; i < 3; i++) {
        await blindAuction.generateBlock();
      }
      // first bidder prebid -> Phase change(Bidding)
      await blindAuction.prebid(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // check change phase
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, bidPhase);
      // first bidder bid
      await blindAuction.bid(auction.auctionId, {
        from: firstBidderAddress,
        value: String(BID1),
      });
      // check bidder
      let bidders = await blindAuction.getAuctionBidders(0);
      assert.equal(bidders[0].addr, firstBidderAddress);
    });

    it("Failure on bid not same value.", async function () {
      // Block generate 3
      for (let i = 0; i < 3; i++) {
        await blindAuction.generateBlock();
      }
      // first bidder prebid -> Phase change(Bidding)
      await blindAuction.prebid(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // check change phase
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, bidPhase);
      // bid - not same value error
      await truffleAssert.fails(
        blindAuction.bid(auction.auctionId, {
          from: firstBidderAddress,
          value: String(BID2),
        }),
        truffleAssert.ErrorType.REVERT,
        null,
        "not same value bid"
      );
    });
    it("Failure on bid different phase.", async function () {
      // bid - different phase
      await truffleAssert.fails(
        blindAuction.bid(auction.auctionId, {
          from: firstBidderAddress,
          value: String(BID1),
        }),
        truffleAssert.ErrorType.REVERT,
        null,
        "different phase bid"
      );
    });
  });

  describe("Reveal Phase.", async () => {
    it("Success on single reveal.", async function () {
      // Block generate 3
      for (let i = 0; i < 3; i++) {
        await blindAuction.generateBlock();
      }
      // first bidder prebid -> Phase change(Bidding)
      await blindAuction.prebid(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // check change phase - bid
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, bidPhase);
      // Block generate 3
      for (let i = 0; i < 3; i++) {
        await blindAuction.generateBlock();
      }
      // first bidder bid -> Phase change(Reveal)
      await blindAuction.bid(auction.auctionId, {
        from: firstBidderAddress,
        value: String(BID1),
      });
      // check change phase - reveal
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, revealPhase);
      // first bidder reveal
      await blindAuction.reveal(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // after reveal
      auction = await blindAuction.auctions(0);
      // check checked bidders
      let checkedBidders = await blindAuction.getAuctionCheckedBidders(
        auction.auctionId
      );
      assert.equal(checkedBidders[0].addr, firstBidderAddress);
      // check highest bidder
      assert.equal(auction.highestBidder, firstBidderAddress);
      // check highest bid
      assert.equal(auction.highestBid, BID1);
    });

    it("Failure on reveal not same value", async function () {
      // Block generate 3
      for (let i = 0; i < 3; i++) {
        await blindAuction.generateBlock();
      }
      // first bidder prebid -> Phase change(Bidding)
      await blindAuction.prebid(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // check change phase - bid
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, bidPhase);
      // Block generate 3
      for (let i = 0; i < 3; i++) {
        await blindAuction.generateBlock();
      }
      // first bidder bid -> Phase change(Reveal)
      await blindAuction.bid(auction.auctionId, {
        from: firstBidderAddress,
        value: String(BID1),
      });
      // check change phase - reveal
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, revealPhase);
      // reveal - not same value
      await truffleAssert.fails(
        blindAuction.reveal(auction.auctionId, String(BID2), {
          from: firstBidderAddress,
        }),
        truffleAssert.ErrorType.REVERT,
        null,
        "not same value reveal"
      );
    });

    it("Failure on reveal different phase", async function () {
      // reveal - differnet phase
      await truffleAssert.fails(
        blindAuction.reveal(auction.auctionId, String(BID1), {
          from: firstBidderAddress,
        }),
        truffleAssert.ErrorType.REVERT,
        null,
        "different phase reveal"
      );
    });
  });

  describe("Done Phase.", async () => {
    it("Success on withdraw fail bidder", async function () {
      // Block generate 1
      await blindAuction.generateBlock();
      // first bidder prebid
      await blindAuction.prebid(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // second bidder prebid -> Phase change(Bidding)
      await blindAuction.prebid(auction.auctionId, String(BID2), {
        from: secondBidderAddress,
      });
      // check change phase - bid
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, bidPhase);

      // Block generate 1
      await blindAuction.generateBlock();
      // first bidder bid
      await blindAuction.bid(auction.auctionId, {
        from: firstBidderAddress,
        value: String(BID1),
      });
      // second bidder bid -> Phase change(Reveal)
      await blindAuction.bid(auction.auctionId, {
        from: secondBidderAddress,
        value: String(BID2),
      });
      // check change phase - reveal
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, revealPhase);
      // first bidder reveal
      await blindAuction.reveal(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // second bidder reveal -> Phase change(Done)
      await blindAuction.reveal(auction.auctionId, String(BID2), {
        from: secondBidderAddress,
      });
      // check change phase - done
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, donePhase);
      // check highest bidder
      assert.equal(auction.highestBidder, secondBidderAddress);
      // withdraw
      await blindAuction.withdraw(auction.auctionId, {
        from: firstBidderAddress,
      });
    });

    it("Success on take highest bid seller", async function () {
      // Block generate 1
      await blindAuction.generateBlock();
      // first bidder prebid
      await blindAuction.prebid(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // second bidder prebid -> Phase change(Bidding)
      await blindAuction.prebid(auction.auctionId, String(BID2), {
        from: secondBidderAddress,
      });
      // check change phase - bid
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, bidPhase);

      // Block generate 1
      await blindAuction.generateBlock();
      // first bidder bid
      await blindAuction.bid(auction.auctionId, {
        from: firstBidderAddress,
        value: String(BID1),
      });
      // second bidder bid -> Phase change(Reveal)
      await blindAuction.bid(auction.auctionId, {
        from: secondBidderAddress,
        value: String(BID2),
      });
      // check change phase - reveal
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, revealPhase);
      // first bidder reveal
      await blindAuction.reveal(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // second bidder reveal -> Phase change(Done)
      await blindAuction.reveal(auction.auctionId, String(BID2), {
        from: secondBidderAddress,
      });
      // check change phase - done
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, donePhase);
      // check highest bidder
      assert.equal(auction.highestBidder, secondBidderAddress);
      // take bid seller
      await blindAuction.auctionEnd(auction.auctionId, {
        from: sellerAddress,
      });
    });

    it("Failure on done different phase", async function () {
      await truffleAssert.fails(
        blindAuction.auctionEnd(auction.auctionId, {
          from: sellerAddress,
        }),
        truffleAssert.ErrorType.REVERT,
        null,
        "different phase done"
      );
    });

    it("Failure on done seller withdraw", async function () {
      // Block generate 1
      await blindAuction.generateBlock();
      // first bidder prebid
      await blindAuction.prebid(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // second bidder prebid -> Phase change(Bidding)
      await blindAuction.prebid(auction.auctionId, String(BID2), {
        from: secondBidderAddress,
      });
      // check change phase - bid
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, bidPhase);

      // Block generate 1
      await blindAuction.generateBlock();
      // first bidder bid
      await blindAuction.bid(auction.auctionId, {
        from: firstBidderAddress,
        value: String(BID1),
      });
      // second bidder bid -> Phase change(Reveal)
      await blindAuction.bid(auction.auctionId, {
        from: secondBidderAddress,
        value: String(BID2),
      });
      // check change phase - reveal
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, revealPhase);
      // first bidder reveal
      await blindAuction.reveal(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // second bidder reveal -> Phase change(Done)
      await blindAuction.reveal(auction.auctionId, String(BID2), {
        from: secondBidderAddress,
      });
      // check change phase - done
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, donePhase);
      // check highest bidder
      assert.equal(auction.highestBidder, secondBidderAddress);
      // withdraw - seller error
      await truffleAssert.fails(
        blindAuction.withdraw(auction.auctionId, {
          from: sellerAddress,
        }),
        truffleAssert.ErrorType.REVERT,
        null,
        "seller withdraw"
      );
    });
    it("Failure on done bidder take highest bid", async function () {
      // Block generate 1
      await blindAuction.generateBlock();
      // first bidder prebid
      await blindAuction.prebid(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // second bidder prebid -> Phase change(Bidding)
      await blindAuction.prebid(auction.auctionId, String(BID2), {
        from: secondBidderAddress,
      });
      // check change phase - bid
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, bidPhase);

      // Block generate 1
      await blindAuction.generateBlock();
      // first bidder bid
      await blindAuction.bid(auction.auctionId, {
        from: firstBidderAddress,
        value: String(BID1),
      });
      // second bidder bid -> Phase change(Reveal)
      await blindAuction.bid(auction.auctionId, {
        from: secondBidderAddress,
        value: String(BID2),
      });
      // check change phase - reveal
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, revealPhase);
      // first bidder reveal
      await blindAuction.reveal(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // second bidder reveal -> Phase change(Done)
      await blindAuction.reveal(auction.auctionId, String(BID2), {
        from: secondBidderAddress,
      });
      // check change phase - done
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, donePhase);
      // check highest bidder
      assert.equal(auction.highestBidder, secondBidderAddress);
      // take highest bid - bidder error
      await truffleAssert.fails(
        blindAuction.auctionEnd(auction.auctionId, {
          from: firstBidderAddress,
        }),
        truffleAssert.ErrorType.REVERT,
        null,
        "bidder can not take highest bid"
      );
    });
  });

  describe("Full Auction Run.", async () => {
    it("Success on simulated auction with 3 bidders (accounts).", async function () {
      // Prebidding
      // first bidder prebid
      await blindAuction.prebid(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // second bidder prebid
      await blindAuction.prebid(auction.auctionId, String(BID2), {
        from: secondBidderAddress,
      });
      // third bidder prebid -> Phase change(Bidding)
      await blindAuction.prebid(auction.auctionId, String(BID3), {
        from: thirdBidderAddress,
      });
      // check change phase - bid
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, bidPhase);

      // Bidding
      // first bidder bid
      await blindAuction.bid(auction.auctionId, {
        from: firstBidderAddress,
        value: String(BID1),
      });
      // second bidder bid
      await blindAuction.bid(auction.auctionId, {
        from: secondBidderAddress,
        value: String(BID2),
      });
      // third bidder bid -> Phase change(Reveal)
      await blindAuction.bid(auction.auctionId, {
        from: thirdBidderAddress,
        value: String(BID3),
      });
      // check change phase - reveal
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, revealPhase);

      // Reveal
      // first bidder reveal
      await blindAuction.reveal(auction.auctionId, String(BID1), {
        from: firstBidderAddress,
      });
      // second bidder reveal
      await blindAuction.reveal(auction.auctionId, String(BID2), {
        from: secondBidderAddress,
      });
      // third bidder reveal -> Phase change(Done)
      await blindAuction.reveal(auction.auctionId, String(BID3), {
        from: thirdBidderAddress,
      });
      // check change phase - done
      auction = await blindAuction.auctions(0);
      assert.equal(auction.currentPhase, donePhase);

      // Done
      // check highest bidder
      assert.equal(auction.highestBidder, secondBidderAddress);
      // check highest bid
      assert.equal(auction.highestBid, BID2);

      // Before Balance
      let firstBalBefore = Number(
        web3.utils.fromWei(
          await web3.eth.getBalance(firstBidderAddress),
          "ether"
        )
      );
      let secondBalBefore = Number(
        web3.utils.fromWei(
          await web3.eth.getBalance(secondBidderAddress),
          "ether"
        )
      );
      let thirdBalBefore = Number(
        web3.utils.fromWei(
          await web3.eth.getBalance(thirdBidderAddress),
          "ether"
        )
      );

      // Withdraw
      // withdraw - first bidder
      await blindAuction.withdraw(auction.auctionId, {
        from: firstBidderAddress,
      });
      // withdraw - third bidder
      await blindAuction.withdraw(auction.auctionId, {
        from: thirdBidderAddress,
      });

      // After Balance
      let firstBalAfter = Number(
        web3.utils.fromWei(
          await web3.eth.getBalance(firstBidderAddress),
          "ether"
        )
      );
      let secondBalAfter = Number(
        web3.utils.fromWei(
          await web3.eth.getBalance(secondBidderAddress),
          "ether"
        )
      );
      let thirdBalAfter = Number(
        web3.utils.fromWei(
          await web3.eth.getBalance(thirdBidderAddress),
          "ether"
        )
      );

      // Balance
      assert.closeTo(firstBalBefore, firstBalAfter, 0.1, "Full value recieved");
      assert.closeTo(thirdBalBefore, thirdBalAfter, 0.1, "Full value recieved");
      assert.closeTo(
        secondBalBefore - secondBalAfter,
        BID2,
        1200,
        "Difference recieved"
      );

      // seller balance - before
      let sellerBalBefore = Number(
        web3.utils.fromWei(await web3.eth.getBalance(sellerAddress), "ether")
      );
      // seller take bid
      await blindAuction.auctionEnd(auction.auctionId, {
        from: sellerAddress,
      });
      // seller balance - after
      let sellerBalAfter = Number(
        web3.utils.fromWei(await web3.eth.getBalance(sellerAddress), "ether")
      );

      assert.closeTo(
        sellerBalAfter - secondBalBefore,
        BID2,
        1200,
        "Highest bid recieved"
      );
    });
  });
});
