export const somniaMainnet = {
  id: 5031,
  name: "Somnia Mainnet",
  rpcHttpUrl: "https://api.infra.mainnet.somnia.network/",
  rpcWsUrl: "wss://api.infra.mainnet.somnia.network/ws",
  explorerUrl: "https://explorer.somnia.network/",
} as const;

export const somniaTestnet = {
  id: 50312,
  name: "Somnia Shannon Testnet",
  rpcHttpUrl: "https://dream-rpc.somnia.network/",
  rpcWsUrl: "wss://dream-rpc.somnia.network/ws",
  explorerUrl: "https://shannon-explorer.somnia.network/",
} as const;
