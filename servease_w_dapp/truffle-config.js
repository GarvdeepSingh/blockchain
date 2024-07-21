const { compile } = require("truffle");

module.exports = {
  networks: {
    development:{
      host:"192.168.181.159",
      port:7545,
      networks_id:"*"
    }
  },
  contracts_directory: "./contrats",
  compiler: {
    solc: {
      version:"0.8.19",
      optimizer:{
        enabled: true,
        runs: 200
      }
    }
  },
  db:{
    enabled: false
  }
}

// const { compile } = require("truffle");

// module.exports = {
//   networks: {
//     development: {
//       host: "127.0.0.1",
//       port: 7545,
//       network_id: "*" // Fixed the key to network_id
//     }
//   },
//   contracts_directory: "./contracts", // Fixed the typo here
//   compilers: { // Changed from compiler to compilers
//     solc: {
//       version: "0.8.19",
//       optimizer: {
//         enabled: true,
//         runs: 200
//       }
//     }
//   },
//   db: {
//     enabled: false
//   }
// }
