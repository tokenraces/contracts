require('dotenv').config()

const HDWalletProvider = require('@truffle/hdwallet-provider')
const chainId = process.env.CHAIN_ID
const chainGas = process.env.CHAIN_GAS
// ** Providers
const biggestRaceProvider = new HDWalletProvider({
  privateKeys: [process.env.BIGGEST_RACE_PRIVATE_KEY],
  providerOrUrl: process.env.PROVIDER
})
const middleRaceProvider = new HDWalletProvider({
  privateKeys: [process.env.MIDDLE_RACE_PRIVATE_KEY],
  providerOrUrl: process.env.PROVIDER
})
const littleRaceProvider = new HDWalletProvider({
  privateKeys: [process.env.LITTLE_RACE_PRIVATE_KEY],
  providerOrUrl: process.env.PROVIDER
})
const smallestRaceProvider = new HDWalletProvider({
  privateKeys: [process.env.SMALLEST_RACE_PRIVATE_KEY],
  providerOrUrl: process.env.PROVIDER
})
const starterRaceProvider = new HDWalletProvider({
  privateKeys: [process.env.STARTER_RACE_PRIVATE_KEY],
  providerOrUrl: process.env.PROVIDER
})
const specialRaceProvider = new HDWalletProvider({
  privateKeys: [process.env.SPECIAL_RACE_PRIVATE_KEY],
  providerOrUrl: process.env.PROVIDER
})

module.exports = {
  networks: {
    biggest: {
      provider: () => biggestRaceProvider,
      network_id: chainId,
      gas: chainGas
    },
    middle: {
      provider: () => middleRaceProvider,
      network_id: chainId,
      gas: chainGas
    },
    little: {
      provider: () => littleRaceProvider,
      network_id: chainId,
      gas: chainGas
    },
    smallest: {
      provider: () => smallestRaceProvider,
      network_id: chainId,
      gas: chainGas
    },
    starter: {
      provider: () => starterRaceProvider,
      network_id: chainId,
      gas: chainGas
    },
    special: {
      provider: () => specialRaceProvider,
      network_id: chainId,
      gas: chainGas
    }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.11",    // Fetch exact version from solc-bin (default: truffle's version)
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  },
  db: {
    enabled: false
  },
  plugins: [
    'truffle-plugin-verify'    
  ],
  api_keys: {
    bscscan: process.env.BSC_API_KEY,
    etherscan:process.env.ETH_API_KEY
  }
};
