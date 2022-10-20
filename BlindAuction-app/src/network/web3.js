import Web3 from "web3";

let web3;

if (window.ethereum) {
  web3 = new Web3(ethereum);
  try {
    // Request account access if needed
    ethereum.enable();
  } catch (error) {
    // User denied account access...
  }
} else if (typeof window.web3 !== "undefined") {
  // Legacy dapp browsers...
  web3 = new Web3(window.web3.currentProvider);
} else {
  // Non-dapp browsers...
  console.log(
    "Non-Ethereum browser detected. You should consider trying MetaMask!"
  );
}
console.log(web3);
export default web3;
