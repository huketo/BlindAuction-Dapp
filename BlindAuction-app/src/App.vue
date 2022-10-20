<template>
  <div class="p-12">
    <h1 class="text-2xl font-bold mb-5">부동산 경매 Dapp</h1>
    <!-- Seller -->
    <h2 class="font-bold text-xl mb-2">매물등록</h2>
    <div class="p-5 border border-black flex flex-col gap-10 mb-10">
      <div
        class="bg-gray-400 inline-block w-24 text-center border border-black text-white"
      >
        매물
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
            경매 {{ key + 1 }}
          </div>
          <span class="ml-3">{{ auction }}</span>
        </div>
        <div class="p-3 flex">
          <div class="flex flex-col gap-1 w-1/2">
            <div>
              <!-- <p for="product-name">매물이름: {{ auctionDataList[key][0] }}</p> -->
            </div>
            <div>
              <p for="product-description">
                <!-- 설명: {{ auctionDataList[key][1] }} -->
              </p>
            </div>
            <div class="flex">
              <p for="minimum-price">
                <!-- 최소입찰금액: {{ auctionDataList[key][2] }} -->
              </p>
              <span class="ml-2">(ETH)</span>
            </div>
            <div>
              <!-- <p>진행상황: {{ auctionDataList[key][3] }}</p> -->
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
              />
              <span class="ml-2">(ETH)</span>
            </div>
          </div>
          <div class="w-1/2 relative">
            <button
              class="absolute bottom-0 bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600"
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
              />
              <span class="ml-2">(ETH)</span>
            </div>
          </div>
          <div class="w-1/2 relative">
            <button
              class="absolute bottom-0 bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600"
            >
              입찰등록
            </button>
          </div>
        </div>
      </div>

      <div>
        <div class="mb-12">
          <span class="mr-24">입찰자: </span>
          <span>입찰금액: </span>
        </div>
        <div>낙찰자:</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import web3 from "./network/web3";
import BlindAuction from "./network/BlindAuction";
import BlindAuctionList from "./network/BlindAuctionList";
import { onBeforeMount, ref } from "vue";

const title = ref("");
const minimumBid = ref(0);
const description = ref("");

const amount = ref(0);
const auctionList = ref([]);
const auctionDataList = ref([]);
let auctionListDev = [];

let isShow = false;
let isBid = false;
let isFin = false;

let bidPrice = "";
const auctionAdress = ref("");
let bidders = 0;

onBeforeMount(() => {
  // before mount get auctions
  BlindAuctionList.methods
    .returnAllAuctions()
    .call()
    .then((auctions) => {
      console.log(auctions);
      auctionList.value = auctions;
    });
  auctionList.value.forEach((address) => {
    auctionDataList.value.push(
      BlindAuction(address).methods.returnContents().call()
    );
  });
});

const createAuction = () => {
  web3.eth
    .getAccounts()
    .then((accounts) => {
      // ether -> wei
      const _minimumBid = web3.utils.toWei(minimumBid.value, "ether");
      // create acution
      return BlindAuctionList.methods
        .createAuction(title.value, description.value, _minimumBid)
        .send({ from: accounts[0] });
    })
    .then(() => {
      // initialize create auction form
      title.value = "";
      description.value = "";
      minimumBid.value = 0;
      // get auctions
      return BlindAuctionList.methods.returnAllAuctions().call();
    })
    .then((auctions) => {
      const index = auctions.length - 1;
      console.log(auctions[index]);
      console.log(auctions);
      // get contract address of auctions
      auctionAdress.value = auctions[index];
      // set address and get content
      const auctionInstance = BlindAuction(auctions[index]);
      console.log(auctionInstance);
      return auctionInstance.methods.returnContents().call();
    })
    .then((lists) => {
      console.log(lists);
      const auctionLists = lists;
      // wei -> ether
      auctionLists[2] = web3.utils.fromWei(auctionLists[2], "ether");
      auctionDataList.value.push(auctionLists);
      // auction update page
      amount.value += 1;
    })
    .catch((err) => {
      console.log(err);
    });
};

const handleBidSubmit = () => {};

const handleFinalize = () => {};
</script>
