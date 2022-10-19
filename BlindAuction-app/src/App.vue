<template>
  <div class="p-12">
    <h1 class="text-2xl font-bold mb-5">부동산 경매 Dapp</h1>
    <div class="p-5 border border-black flex flex-col gap-10">
      <div>
        <div
          class="bg-gray-400 inline-block w-24 text-center border border-black text-white"
        >
          경매
        </div>
        <div class="p-3 flex">
          <div class="flex flex-col gap-1 w-1/2">
            <div>
              <label for="product-name">매물이름: </label>
              <input
                type="text"
                placeholder="매물이름을 입력하세요."
                required
                class="border border-gray-400 focus:border-gray-500 pl-0.5"
              />
            </div>
            <div>
              <label for="product-description">설명: </label>
              <input
                type="text"
                placeholder="매물설명을 입력하세요."
                required
                class="border border-gray-400 focus:border-gray-500 pl-0.5"
              />
            </div>
            <div>
              <label for="minimum-price">최소입찰금액: </label>
              <input
                type="text"
                placeholder="최소금액을 입력하세요."
                required
                class="border border-gray-400 focus:border-gray-500 pl-0.5"
              />
            </div>
          </div>
          <div class="w-1/2 relative">
            <button
              class="absolute bottom-0 bg-sky-500 w-32 border border-black text-white rounded hover:bg-sky-600"
            >
              경매시작
            </button>
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
                required
                class="border border-gray-400 focus:border-gray-500 pl-0.5"
              />
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
                required
                class="border border-gray-400 focus:border-gray-500 pl-0.5"
              />
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

<script setup></script>
