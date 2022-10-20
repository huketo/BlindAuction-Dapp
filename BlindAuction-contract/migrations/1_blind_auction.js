const BlindAuctionList = artifacts.require("BlindAuctionList");
module.exports = function (_deployer) {
  // Use deployer to state migration tasks.
  _deployer.deploy(BlindAuctionList);
};
