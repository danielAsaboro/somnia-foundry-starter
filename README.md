# Somnia Dev Workspace

Local starter workspace for building on Somnia with Foundry first and TypeScript utilities around it.

## What this gives you

- Official Somnia mainnet/testnet network defaults
- Foundry contract, test, and deploy scaffold
- One-command environment verification
- Local bootstrap script for `.env` and missing-tool checks
- `just` commands so the common flow stays short

## Current workspace status

Machine checks completed on 2026-05-19:

- Present: `node`, `npm`, `pnpm`, `forge`, `cast`, `anvil`, `cargo`, `rustup`, `docker`, `just`, `jq`, `direnv`, `solc`
- Docker daemon was not running during verification

## Quick start

```bash
cp .env.example .env
bash scripts/check-env.sh
just test
```

If you want a forked local node:

```bash
source .env
anvil --fork-url "$SOMNIA_RPC_TESTNET"
```

## Common commands

```bash
just check
just build
just test
just deploy-local
just deploy-testnet
just deploy-testnet-legacy
just fork-testnet
```

## Live Somnia status

Validated on Somnia Shannon testnet on 2026-05-19:

- Faucet-funded deployer: `0x208cf4Ad614d7fc613E52b7b7D8b413422F1C286`
- Live `Counter` deployment: `0xdE1Bb2dd0ac54790e7908bE701eD2f7BA102377A`
- Verified state change: `increment()` succeeded and `getNumber()` returned `1`

## Shannon deployment notes

- `foundry.toml` targets `evm_version = "paris"` because Somnia rejected the default newer bytecode path on this machine.
- Standard Foundry broadcasts under-estimated gas for live Somnia contract creation in this workspace.
- The working live path is `node --env-file=.env scripts/deploy-somnia-live.mjs`, exposed as `pnpm run deploy:testnet:legacy`.
- The direct deploy script uses a legacy transaction and a high explicit gas limit for reliable Shannon deployment.

## Workspace layout

```text
contracts/   Solidity sources
test/        Foundry tests
script/      Foundry deploy scripts
scripts/     Shell setup and verification helpers
src/         TypeScript app or agent code
resources/   Planning and supporting docs
```

## Somnia network values

- Testnet chain ID: `50312`
- Mainnet chain ID: `5031`
- Testnet RPC: `https://dream-rpc.somnia.network/`
- Mainnet RPC: `https://api.infra.mainnet.somnia.network/`
- Testnet WebSocket: `wss://dream-rpc.somnia.network/ws`
- Testnet explorer: `https://shannon-explorer.somnia.network/`
- Mainnet explorer: `https://explorer.somnia.network/`

These values were taken from the official Somnia docs on 2026-05-19.

## Next build step

The repo is ready for you to add either:

- a pure Foundry protocol in `contracts/`
- a frontend in `src/`
- agent services in `src/agents/`

If you build for the Agentathon, start by replacing `contracts/Counter.sol` with the first end-to-end Somnia demo contract you want to deploy.
