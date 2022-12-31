var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "useful size grain draft combine humor already body wait trash stumble install"; // from ganache UI

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:7545/", 0, 50);
      },
      network_id: '*'
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
  
};