var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "bleak dawn grant dwarf rebuild boost crazy dinosaur solve plate trash dutch";

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
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