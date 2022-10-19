const BlindAuction = artifacts.require("BlindAuction");
module.exports = function (_deployer) {
  // Use deployer to state migration tasks.
  _deployer.deploy(BlindAuction);
};
