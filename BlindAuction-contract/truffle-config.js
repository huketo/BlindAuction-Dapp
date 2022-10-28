const HDWalletProvider = require("@truffle/hdwallet-provider");
const fs = require("fs");
module.exports = {
  networks: {
    ganache: {
      host: "172.31.48.1",
      port: 8545,
      network_id: "5777",
    },
    inf_BlindAuction_goerli: {
      network_id: 5,
      gasPrice: 500000000000,
      provider: new HDWalletProvider(
        fs.readFileSync(
          "/home/huketo/BlindAuction-Dapp/BlindAuction-contract/mnemoncis.env",
          "utf-8"
        ),
        "https://goerli.infura.io/v3/96f3d6e518c84534a7340030172de801"
      ),
    },
    inf_BlindAuction_sepolia: {
      network_id: 11155111,
      gasPrice: 350000000000,
      provider: new HDWalletProvider(
        fs.readFileSync(
          "/home/huketo/BlindAuction-Dapp/BlindAuction-contract/mnemoncis.env",
          "utf-8"
        ),
        "https://sepolia.infura.io/v3/96f3d6e518c84534a7340030172de801"
      ),
    },
  },
  mocha: {},
  compilers: {
    solc: {
      version: "0.8.17",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: "byzantium",
      },
    },
  },
};
