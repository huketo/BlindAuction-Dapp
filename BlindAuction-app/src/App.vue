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
      v-if="auctionList"
      v-for="(auction, key) in auctionList"
      :key="key"
      class="p-5 border border-black flex flex-col gap-10 mb-5"
    >
      <div>
        <div>
          <div
            class="bg-gray-400 inline-block w-24 text-center border border-black text-white"
          >
            경매 {{ auction?.auctionId }}
          </div>
          <span class="ml-3">판매자: {{ auction?.seller }}</span>
          <div class="float-right">
            <button
              class="bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600"
              @click="getMyBid(auction?.auctionId)"
            >
              나의 입찰가
            </button>
          </div>
        </div>
        <div class="p-3 flex">
          <div class="flex flex-col gap-1 w-1/2">
            <div>
              <p for="product-name">매물이름: {{ auction?.title }}</p>
            </div>
            <div>
              <p for="product-description">설명: {{ auction?.description }}</p>
            </div>
            <div class="flex">
              <p for="minimum-price">
                최소입찰금액: {{ auction?.minimumPrice }}
              </p>
              <span class="ml-2">(ETH)</span>
            </div>
            <div>
              <span>진행상황: </span>
              <span v-if="auction?.currentPhase == 0">예비입찰</span>
              <span v-if="auction?.currentPhase == 1">입찰</span>
              <span v-if="auction?.currentPhase == 2">공표</span>
              <span v-if="auction?.currentPhase == 3">경매종료</span>
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
                placeholder="예비입찰금 입력"
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
                placeholder="입찰금 입력"
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
        </div>
        <div class="mb-8 flex">
          <div class="w-1/2">
            <label for="reveal" class="ml-2">입찰 금액: </label>
            <input
              type="text"
              class="border border-gray-400 focus:border-gray-500 pl-0.5"
              placeholder="입찰금 확인"
              v-model="revealPriceList[key]"
            />
            <span class="ml-2">(ETH)</span>
          </div>
          <button
            v-if="auction?.currentPhase == 2"
            class="bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600"
            @click="pushReveal(auction.auctionId)"
          >
            입찰 확인
          </button>
        </div>
        <!-- Reveal -->
        <!-- <div>{{ auctionCheckList }}</div> -->
        <div v-if="auction.checkedBidders" class="pb-5">
          <div v-for="checkedBidder in auction.checkedBidders" class="ml-2 m-1">
            <div class="flex">
              <div class="w-1/2">
                <span>입찰자: </span>
                <span>{{ checkedBidder[0] }}</span>
              </div>
              <div>
                <span>입찰금: </span>
                <span
                  >{{
                    web3?.utils?.fromWei(checkedBidder[1], "ether")
                  }}
                  (ETH)</span
                >
              </div>
            </div>
          </div>
        </div>
        <!-- Done -->
        <div
          v-if="auction.currentPhase == 3"
          class="pt-5 ml-2 border-t border-dashed border-sky-500"
        >
          <div class="flex">
            <div class="w-1/2">낙찰자: {{ auction?.highestBidder }}</div>
            <div>낙찰금: {{ auction?.highestBid }} (ETH)</div>
          </div>

          <div class="flex justify-between mt-3">
            <button
              class="bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600"
              @click="pushWithdraw(auction?.auctionId)"
            >
              반환
            </button>
            <button
              v-if="auction?.seller == MyAddress"
              class="bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600"
              @click="pushAuctionEnd(auction?.auctionId)"
            >
              정산
            </button>
          </div>
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
const minimumBid = ref("");
const description = ref("");

const auctionList = ref([]);
const auctionCheckList = ref([]);

const prebidPriceList = ref([]);
const bidPriceList = ref([]);
const revealPriceList = ref([]);

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
      // push bidders
      BlindAuction.methods
        .getAuctionBidders(index)
        .call()
        .then((bidders) => {
          console.log(bidders);
          auctionData["bidders"] = bidders;
          console.log(auctionData);
        });
      // push checked bidders
      BlindAuction.methods
        .getAuctionCheckedBidders(index)
        .call()
        .then((checkedBidders) => {
          console.log(checkedBidders);
          auctionData["checkedBidders"] = checkedBidders;
          auctionCheckList.value.push(checkedBidders);
          console.log(auctionData);
        });
      // push auction data
      auctionList.value[index] = auctionData;
      console.log(auctionData);
    });
};

onBeforeMount(async () => {
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
          prebidPriceList.value.push("");
          bidPriceList.value.push("");
          revealPriceList.value.push("");
        }
      }
    });
});

const createAuction = () => {
  web3.eth
    .getAccounts()
    .then((accounts) => {
      // ether -> wei
      const _minimumBid = web3.utils.toWei(minimumBid.value, "ether");
      // create acution
      console.log(accounts[0]);
      BlindAuction.methods
        .createAuction(accounts[0], title.value, description.value, _minimumBid)
        .send({ from: accounts[0] })
        .then(() => {
          // initialize create auction form
          title.value = "";
          description.value = "";
          minimumBid.value = 0;

          prebidPriceList.value.push("");
          bidPriceList.value.push("");
          revealPriceList.value.push("");

          BlindAuction.methods
            .numAuctions()
            .call()
            .then((num) => {
              const index = num - 1;

              return BlindAuction.methods.auctions(index).call();
            })
            .then((auction) => {
              console.log(auction);
              const toEtherMinimum = web3.utils.fromWei(
                auction.minimumPrice,
                "ether"
              );
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
            });
        });
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
      alert("My bid: " + web3.utils.fromWei(bid, "ether") + " ether")
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
    .then(() => {
      console.log("reveal success");
    })
    .catch((err) => console.log(err));
  getAuctionData(auctionId);
};

const pushWithdraw = (auctionId) => {
  // get bidder address
  const fromAddress = web3.eth.accounts.givenProvider.selectedAddress;
  BlindAuction.methods
    .withdraw(auctionId)
    .send({ from: fromAddress, gasPrice: 20000000000, gas: "6721975" })
    .then(() => alert("withdraw success"))
    .catch((err) => console.log(err));
};

const pushAuctionEnd = (auctionId) => {
  // get seller address
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
  }
};
</script>
