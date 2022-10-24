<template>
  <div class="p-12">
    <h1 class="text-2xl font-bold mb-5">부동산 경매 Dapp</h1>
    <!-- Seller -->
    <h2 class="font-bold text-xl mb-2">매물등록</h2>
    <div class="p-5 border border-black flex flex-col gap-10 mb-10">
      <div class="flex justify-between">
        <div
          class="bg-gray-400 inline-block w-24 text-center border border-black text-white"
        >
          매물
        </div>
        <button
          class="bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600"
          @click="generateBlock"
        >
          블록 생성
        </button>
      </div>

      <div class="p-3 flex">
        <div class="flex flex-col gap-1 w-1/2">
          <div>
            <label for="product-name">매물이름: </label>
            <input
              type="text"
              placeholder="매물이름을 입력하세요."
              class="border border-gray-400 focus:border-gray-500 pl-0.5"
              v-model="title"
            />
          </div>
          <div>
            <label for="product-description">설명: </label>
            <input
              type="text"
              placeholder="매물설명을 입력하세요."
              class="border border-gray-400 focus:border-gray-500 pl-0.5"
              v-model="description"
            />
          </div>
          <div>
            <label for="minimum-price">최소입찰금액: </label>
            <input
              type="text"
              placeholder="최소금액을 입력하세요."
              class="border border-gray-400 focus:border-gray-500 pl-0.5"
              v-model="minimumBid"
            />
            <span class="ml-2">(ETH)</span>
          </div>
        </div>
        <div class="w-1/2 relative">
          <button
            class="absolute bottom-0 bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600"
            @click="createAuction"
          >
            매물등록
          </button>
        </div>
      </div>
    </div>
    <!-- Bidder -->
    <h2 class="font-bold text-xl mb-2">매물목록</h2>
    <div
      v-for="(auction, key) in auctionList"
      :key="key"
      class="p-5 border border-black flex flex-col gap-10 mb-5"
    >
      <div>
        <div>
          <div
            class="bg-gray-400 inline-block w-24 text-center border border-black text-white"
          >
            경매 {{ auction.auctionId }}
          </div>
          <span class="ml-3">{{ auction.seller }}</span>
          <div class="float-right">
            <button
              class="bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600 mr-2"
              @click="generateBlock"
            >
              블록 생성
            </button>
            <button
              class="bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600"
              @click="getMyBid(auction.auctionId)"
            >
              나의 입찰가
            </button>
          </div>
        </div>
        <div class="p-3 flex">
          <div class="flex flex-col gap-1 w-1/2">
            <div>
              <p for="product-name">매물이름: {{ auction.title }}</p>
            </div>
            <div>
              <p for="product-description">설명: {{ auction.description }}</p>
            </div>
            <div class="flex">
              <p for="minimum-price">
                최소입찰금액: {{ auction.minimumPrice }}
              </p>
              <span class="ml-2">(ETH)</span>
            </div>
            <div>
              <p>진행상황: {{ auction.currentPhase }}</p>
            </div>
          </div>
        </div>
      </div>

      <div>
        <div
          class="bg-gray-400 inline-block w-24 text-center border border-black text-white"
        >
          예비입찰
        </div>
        <div class="p-3 flex">
          <div class="flex flex-col gap-1 w-1/2">
            <div>
              <label for="product-name">입찰 금액: </label>
              <input
                type="text"
                placeholder="매물이름을 입력하세요."
                class="border border-gray-400 focus:border-gray-500 pl-0.5"
                v-model="prebidPriceList[key]"
              />
              <span class="ml-2">(ETH)</span>
            </div>
          </div>
          <div class="w-1/2 relative">
            <button
              class="absolute bottom-0 bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600"
              @click="pushPrebid(auction.auctionId)"
            >
              입찰가격등록
            </button>
          </div>
        </div>
      </div>

      <div class="border-b border-dashed border-sky-500 pb-3">
        <div
          class="bg-gray-400 inline-block w-24 text-center border border-black text-white"
        >
          입찰
        </div>
        <div class="p-3 flex">
          <div class="flex flex-col gap-1 w-1/2">
            <div>
              <label for="product-name">입찰 금액: </label>
              <input
                type="text"
                placeholder="매물이름을 입력하세요."
                class="border border-gray-400 focus:border-gray-500 pl-0.5"
                v-model="bidPriceList[key]"
              />
              <span class="ml-2">(ETH)</span>
            </div>
          </div>
          <div class="w-1/2 relative">
            <button
              class="absolute bottom-0 bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600"
              @click="pushBid(auction.auctionId)"
            >
              입찰등록
            </button>
          </div>
        </div>
      </div>

      <div>
        <div class="flex justify-between">
          <div
            class="bg-gray-400 inline-block w-24 text-center border border-black text-white mb-2"
          >
            공표
          </div>
          <button
            class="bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600"
            @click="pushReveal(auction.auctionId)"
          >
            입찰 확인
          </button>
        </div>
        <div class="mb-12">
          <span class="mr-24">입찰자: {{ MyAddress }}</span>
          <label for="reveal">입찰금액: </label>
          <input
            type="text"
            class="border border-gray-400 focus:border-gray-500 pl-0.5"
            v-model="revealPriceList[key]"
          />
        </div>
        <div v-if="isAuctionDone" class="flex justify-between">
          <div>낙찰자: {{ auction.highestBidder }}</div>
          <button
            v-if="auction.seller == MyAddress"
            class="bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600"
            @click="pushAuctionEnd(auction.auctionId)"
          >
            정산
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import web3 from "./network/web3";
import BlindAuction from "./network/BlindAuction";
import { onBeforeMount, ref } from "vue";

const title = ref("");
const minimumBid = ref("0");
const description = ref("");

const auctionList = ref([]);

const prebidPriceList = ref([]);
const bidPriceList = ref([]);
const revealPriceList = ref([]);

const isAuctionDone = ref(false);
const MyAddress = ref("");

setInterval(() => {
  const fromAddress = web3.eth.accounts.givenProvider.selectedAddress;
  const toChecksumAddress = web3.utils.toChecksumAddress(fromAddress);
  MyAddress.value = toChecksumAddress;
}, 1000);

const getAuctionData = (index) => {
  BlindAuction.methods
    .auctions(index)
    .call()
    .then((auction) => {
      // wei -> ether
      const toEtherMinimum = web3.utils.fromWei(auction.minimumPrice, "ether");
      const toEtherHightestBid = web3.utils.fromWei(
        auction.highestBid,
        "ether"
      );
      // get auction data
      const auctionData = {
        auctionId: auction.auctionId,
        seller: auction.seller,
        title: auction.title,
        description: auction.description,
        minimumPrice: toEtherMinimum,
        prebidderCount: auction.prebidderCount,
        highestBidder: auction.highestBidder,
        highestBid: toEtherHightestBid,
        currentPhase: auction.currentPhase,
        phaseBlockNumber: auction.phaseBlockNumber,
      };
      BlindAuction.methods
        .getAuctionBidders(index)
        .call()
        .then((bidders) => {
          console.log(bidders);
          auctionData["bidders"] = bidders;
          console.log(auctionData);
        });
      // push auction data
      auctionList.value[index] = auctionData;
      // phase done check
      if (auction.currentPhase == 3) {
        isAuctionDone.value = true;
      }
    });
};

onBeforeMount(() => {
  const fromAddress = web3.eth.accounts.givenProvider.selectedAddress;
  const toChecksumAddress = web3.utils.toChecksumAddress(fromAddress);
  MyAddress.value = toChecksumAddress;
  // before mount get auctions
  console.log(BlindAuction.methods);
  BlindAuction.methods
    .numAuctions()
    .call()
    .then((auctionLength) => {
      console.log("auctions counts:", auctionLength);
      if (auctionLength > 0) {
        for (let i = 0; i < auctionLength; i++) {
          getAuctionData(i);
          prebidPriceList.value.push("0");
          bidPriceList.value.push("0");
          revealPriceList.value.push("0");
        }
      }
    })
    .catch((err) => console.log(err));
});

const createAuction = () => {
  web3.eth
    .getAccounts()
    .then((accounts) => {
      // ether -> wei
      const _minimumBid = web3.utils.toWei(minimumBid.value, "ether");
      // create acution
      console.log(accounts[0]);
      return BlindAuction.methods
        .createAuction(accounts[0], title.value, description.value, _minimumBid)
        .send({ from: accounts[0] });
    })
    .then((auctionId) => {
      // initialize create auction form
      title.value = "";
      description.value = "";
      minimumBid.value = 0;

      prebidPriceList.value.push("0");
      bidPriceList.value.push("0");
      revealPriceList.value.push("0");

      // return auction
      return BlindAuction.methods.auctions(auctionId).call();
    })
    .then((auction) => {
      console.log(auction);
      const toEtherMinimum = web3.utils.fromWei(auction.minimumPrice, "ether");
      const toEtherHightestBid = web3.utils.fromWei(
        auction.highestBid,
        "ether"
      );
      const auctionData = {
        auctionId: auction.auctionId,
        seller: auction.seller,
        title: auction.title,
        description: auction.description,
        minimumPrice: toEtherMinimum,
        prebidderCount: auction.prebidderCount,
        highestBidder: auction.highestBidder,
        highestBid: toEtherHightestBid,
        currentPhase: auction.currentPhase,
        phaseBlockNumber: auction.phaseBlockNumber,
      };
      BlindAuction.methods
        .getAuctionBidders(auction.auctionId)
        .call()
        .then((bidders) => {
          console.log(bidders);
          auctionData["bidders"] = bidders;
          console.log(auctionData);
        });
      auctionList.value.push(auctionData);
    })
    .catch((err) => {
      console.log(err);
    });
};

const pushPrebid = async (auctionId) => {
  console.log(prebidPriceList.value[auctionId]);
  // ether -> wei
  const prebidPriceWei = web3.utils.toWei(
    prebidPriceList.value[auctionId],
    "ether"
  );
  // get bider address
  const fromAddress = web3.eth.accounts.givenProvider.selectedAddress;
  console.log(fromAddress);
  // prebid in contract
  await BlindAuction.methods
    .prebid(auctionId, prebidPriceWei)
    .send({ from: fromAddress, gasPrice: 20000000000, gas: "6721975" })
    .then(() => {
      console.log("prebid success");
    })
    .catch((err) => {
      console.log(err);
    });
  getAuctionData(auctionId);
};

const getMyBid = (auctionId) => {
  const fromAddress = web3.eth.accounts.givenProvider.selectedAddress;
  BlindAuction.methods
    .getMyBid(auctionId)
    .call({ from: fromAddress })
    .then((bid) =>
      console.log("My bid:", web3.utils.fromWei(bid, "ether") + " ether")
    )
    .catch((err) => console.log(err));
};

const pushBid = async (auctionId) => {
  console.log(bidPriceList.value[auctionId]);
  // ether -> wei
  const bidPriceWei = web3.utils.toWei(bidPriceList.value[auctionId], "ether");
  // get bider address
  const fromAddress = web3.eth.accounts.givenProvider.selectedAddress;
  console.log(fromAddress);
  // bid in contract
  await BlindAuction.methods
    .bid(auctionId)
    .send({
      from: fromAddress,
      gasPrice: 20000000000,
      gas: "6721975",
      value: bidPriceWei,
    })
    .then(() => {
      console.log("bid success");
    })
    .catch((err) => {
      console.log(err);
    });
  getAuctionData(auctionId);
};

const pushReveal = (auctionId) => {
  // ether -> wei
  const bidPriceWei = web3.utils.toWei(
    revealPriceList.value[auctionId],
    "ether"
  );
  // get bidder address
  const fromAddress = web3.eth.accounts.givenProvider.selectedAddress;
  console.log(fromAddress);
  // reveal in contract
  BlindAuction.methods
    .reveal(auctionId, bidPriceWei)
    .send({ from: fromAddress, gasPrice: 20000000000, gas: "6721975" })
    .then(() => console.log("reveal success"))
    .catch((err) => console.log(err));
  getAuctionData(auctionId);
};

const pushAuctionEnd = (auctionId) => {
  // get bidder address
  const fromAddress = web3.eth.accounts.givenProvider.selectedAddress;
  const toChecksumAddress = web3.utils.toChecksumAddress(fromAddress);
  BlindAuction.methods
    .auctions(auctionId)
    .call()
    .then((auction) => console.log(auction.currentPhase));
  // check seller
  if (auctionList.value[auctionId].seller == toChecksumAddress) {
    // auction end
    BlindAuction.methods
      .auctionEnd(auctionId)
      .send({ from: toChecksumAddress, gasPrice: 20000000000, gas: "6721975" })
      .then(() => console.log("auction end"))
      .catch((err) => console.log(err));
    getAuctionData(auctionId);
  }
};

const generateBlock = () => {
  const fromAddress = web3.eth.accounts.givenProvider.selectedAddress;
  BlindAuction.methods
    .generateBlock()
    .send({ from: fromAddress, gasPrice: 20000000000, gas: "6721975" })
    .then(() => console.log("block generate"))
    .catch((err) => console.log(err));
};
</script>
