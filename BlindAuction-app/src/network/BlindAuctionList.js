import web3 from "./web3";

const address = "0x1935EA233B3d64aDb56B87Af7b3C43A78592e34b";
const ABI = [
  {
    inputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    name: "auctions",
    outputs: [
      {
        internalType: "contract BlindAuction",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
    constant: true,
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "_title",
        type: "string",
      },
      {
        internalType: "string",
        name: "_description",
        type: "string",
      },
      {
        internalType: "uint256",
        name: "_minimumBid",
        type: "uint256",
      },
    ],
    name: "createAuction",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "returnAllAuctions",
    outputs: [
      {
        internalType: "contract BlindAuction[]",
        name: "",
        type: "address[]",
      },
    ],
    stateMutability: "view",
    type: "function",
    constant: true,
  },
  {
    inputs: [],
    name: "generateBlockTest",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const instance = new web3.eth.Contract(ABI, address);

export default instance;
