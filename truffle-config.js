const HDWalletProvider = require('@truffle/hdwallet-provider');
require('dotenv').config();

module.exports = {
  networks: {
    loc_development: {
      network_id: "1688688752950",
      port: 8545,
      host: "127.0.0.1"
    },
    sepolia: {
      provider: function () {
        return new HDWalletProvider([process.env.PRIVATE_KEY], "https://rpc.sepolia.org");
      },
      network_id: '11155111'
    },
    loc_development_development: {
      network_id: "*",
      port: 8545,
      host: "127.0.0.1"
    }
  },
  mocha: {},
  compilers: {
    solc: {
      version: "0.8.20"
    }
  }
};
