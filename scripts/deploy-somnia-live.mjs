import artifact from "../out/Counter.sol/Counter.json" with { type: "json" };
import { JsonRpcProvider, Wallet, Contract, ContractFactory } from "ethers";

const rpcUrl = process.env.SOMNIA_RPC_TESTNET;
const privateKey = process.env.PRIVATE_KEY;

if (!rpcUrl) {
  throw new Error("SOMNIA_RPC_TESTNET is required");
}

if (!privateKey) {
  throw new Error("PRIVATE_KEY is required");
}

const provider = new JsonRpcProvider(rpcUrl, {
  chainId: 50312,
  name: "somnia-shannon",
});

const wallet = new Wallet(privateKey, provider);
const feeData = await provider.getFeeData();
const nonce = await provider.getTransactionCount(wallet.address);

const factory = new ContractFactory(artifact.abi, artifact.bytecode.object, wallet);
const unsignedDeployTx = await factory.getDeployTransaction();
if (!unsignedDeployTx.data) {
  throw new Error("Deploy transaction did not include bytecode");
}

const deploymentTx = {
  chainId: 50312,
  data: unsignedDeployTx.data,
  gasLimit: 10_000_000n,
  gasPrice: feeData.gasPrice ?? 12_000_000_001n,
  nonce,
  type: 0,
  value: 0n,
};

console.log(
  JSON.stringify(
    {
      from: wallet.address,
      nonce,
      gasLimit: deploymentTx.gasLimit.toString(),
      gasPrice: deploymentTx.gasPrice.toString(),
      chainId: deploymentTx.chainId,
      dataLength: deploymentTx.data.length,
    },
    null,
    2,
  ),
);

const tx = await wallet.sendTransaction(deploymentTx);
console.log(`txHash=${tx.hash}`);

const receipt = await tx.wait();
if (!receipt) {
  throw new Error("No receipt returned");
}

console.log(
  JSON.stringify(
    {
      status: receipt.status,
      blockNumber: receipt.blockNumber,
      gasUsed: receipt.gasUsed.toString(),
      contractAddress: receipt.contractAddress,
    },
    null,
    2,
  ),
);

if (receipt.status !== 1) {
  throw new Error(`Deployment failed with status ${receipt.status}`);
}

const counter = new Contract(receipt.contractAddress, artifact.abi, provider);
const number = await counter.getNumber();
console.log(`getNumber=${number.toString()}`);
