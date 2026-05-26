/**
 * Minimal agent invocation example.
 *
 * How it works:
 *   1. Calls requestValue on the deployed AgentExample contract.
 *   2. The contract forwards the request to the Somnia Agent platform.
 *   3. A subcommittee of validators independently fetch the URL, reach consensus,
 *      and the platform calls handleResponse back on the contract — no polling needed.
 *
 * Usage:
 *   node --env-file=.env --experimental-strip-types agents/request.ts
 *
 * Required env vars (see .env.example):
 *   PRIVATE_KEY             — caller wallet
 *   AGENT_EXAMPLE_ADDRESS   — deployed AgentExample contract
 *   SOMNIA_RPC_TESTNET      — Somnia Shannon RPC
 */

import { Contract, JsonRpcProvider, Wallet } from "ethers";
import { somniaTestnet } from "../config/somnia.ts";
import { logAgent, nowIso } from "./types.ts";

const abi = [
  "function requestValue(string url, string selector) payable returns (uint256)",
  "function requiredDeposit() view returns (uint256)",
  "function lastObservedValue() view returns (uint256)",
  "function lastStatus() view returns (uint8)",
] as const;

const rpcUrl = process.env.SOMNIA_RPC_TESTNET ?? somniaTestnet.rpcHttpUrl;
const privateKey = process.env.PRIVATE_KEY;
const contractAddress = process.env.AGENT_EXAMPLE_ADDRESS;

if (!privateKey) throw new Error("PRIVATE_KEY is required in .env");
if (!contractAddress) throw new Error("AGENT_EXAMPLE_ADDRESS is required in .env");

// chainId must be explicit — ethers won't auto-detect it correctly on Somnia
const provider = new JsonRpcProvider(rpcUrl, {
  chainId: somniaTestnet.id,
  name: "somnia-shannon",
});
const wallet = new Wallet(privateKey, provider);
const contract = new Contract(contractAddress, abi, wallet);

// Replace with any public JSON endpoint and a dot-path selector.
// The agent returns the value scaled by 10^DECIMALS (8 in the contract),
// so a BTC price of $76,500 comes back as 7_650_000_000_000.
const URL =
  "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd";
const SELECTOR = "bitcoin.usd";

async function main() {
  const deposit: bigint = await contract.requiredDeposit();

  logAgent({
    timestamp: nowIso(),
    role: "Requester",
    action: "request.prepare",
    status: "planned",
    message: `Requesting "${SELECTOR}" from ${URL}`,
    data: { deposit: deposit.toString() },
  });

  // The platform's createRequest call is expensive (~200k gas inside the contract).
  // Ethers' auto-estimate often undershoots it — add 30% headroom.
  const gasEstimate = await contract.requestValue.estimateGas(URL, SELECTOR, { value: deposit });
  const tx = await contract.requestValue(URL, SELECTOR, {
    value: deposit,
    gasLimit: (gasEstimate * 130n) / 100n,
  });

  logAgent({
    timestamp: nowIso(),
    role: "Requester",
    action: "request.sent",
    txHash: tx.hash,
    status: "sent",
    message: "Request submitted to Somnia Agent platform.",
  });

  await tx.wait();

  // Status is "pending" not "complete" — the on-chain work (the callback) hasn't
  // happened yet. Watch for ValueReceived on the contract to know when it does.
  logAgent({
    timestamp: nowIso(),
    role: "Requester",
    action: "request.confirmed",
    txHash: tx.hash,
    status: "pending",
    message: [
      "Request confirmed. The agent subcommittee will fetch the value,",
      "reach consensus, and call handleResponse on your contract.",
      `Track it: ${somniaTestnet.explorerUrl}tx/${tx.hash}`,
    ].join(" "),
  });
}

main().catch((error: unknown) => {
  logAgent({
    timestamp: nowIso(),
    role: "Auditor",
    action: "request.failed",
    status: "failed",
    message: error instanceof Error ? error.message : String(error),
  });
  process.exitCode = 1;
});
