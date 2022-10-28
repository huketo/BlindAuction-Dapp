import web3 from "./web3";

const address = "0x64799306Ba05103030E7B0024B1bC442D837b870";
const ABI = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "_auctionId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "_bidder",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
    ],
    name: "AuctionBid",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [],
    name: "AuctionCreated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "_auctionId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "_highestBidder",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_highestBid",
        type: "uint256",
      },
    ],
    name: "AuctionEnded",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "_auctionId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "_bidder",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
    ],
    name: "AuctionPrebid",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "_auctionId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "_bidder",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
    ],
    name: "AuctionReveal",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "_auctionId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "_bidder",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
    ],
    name: "BidFail",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "_auctionId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "_bidder",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
    ],
    name: "NowHighestBidder",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "_auctionId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "_bidder",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
    ],
    name: "Withdraw",
    type: "event",
  },
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
        internalType: "uint256",
        name: "auctionId",
        type: "uint256",
      },
      {
        internalType: "address payable",
        name: "seller",
        type: "address",
      },
      {
        internalType: "string",
        name: "title",
        type: "string",
      },
      {
        internalType: "string",
        name: "description",
        type: "string",
      },
      {
        internalType: "uint256",
        name: "minimumPrice",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "prebidderCount",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "revealedCount",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "highestBidder",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "highestBid",
        type: "uint256",
      },
      {
        internalType: "enum BlindAuction.Phase",
        name: "currentPhase",
        type: "uint8",
      },
      {
        internalType: "uint256",
        name: "phaseBlockNumber",
        type: "uint256",
      },
      {
        internalType: "bool",
        name: "isAuctionEnd",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
    constant: true,
  },
  {
    inputs: [],
    name: "numAuctions",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
    constant: true,
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_auctionId",
        type: "uint256",
      },
    ],
    name: "getAuctionBidders",
    outputs: [
      {
        components: [
          {
            internalType: "address payable",
            name: "addr",
            type: "address",
          },
          {
            internalType: "bytes32",
            name: "blindedBid",
            type: "bytes32",
          },
          {
            internalType: "bool",
            name: "revealed",
            type: "bool",
          },
        ],
        internalType: "struct BlindAuction.Bidder[]",
        name: "",
        type: "tuple[]",
      },
    ],
    stateMutability: "view",
    type: "function",
    constant: true,
  },
  {
    inputs: [
      {
        internalType: "address payable",
        name: "_seller",
        type: "address",
      },
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
        name: "_minimumPrice",
        type: "uint256",
      },
    ],
    name: "createAuction",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_auctionId",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
    ],
    name: "prebid",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_auctionId",
        type: "uint256",
      },
    ],
    name: "getMyBid",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
    constant: true,
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_auctionId",
        type: "uint256",
      },
    ],
    name: "bid",
    outputs: [],
    stateMutability: "payable",
    type: "function",
    payable: true,
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_auctionId",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
    ],
    name: "reveal",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_auctionId",
        type: "uint256",
      },
    ],
    name: "withdraw",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_auctionId",
        type: "uint256",
      },
    ],
    name: "auctionEnd",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "getCurrentBlockNumber",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
    constant: true,
  },
  {
    inputs: [],
    name: "generateBlock",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const instance = new web3.eth.Contract(ABI, address);

export default instance;
