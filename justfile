set shell := ["zsh", "-lc"]

default:
    @just --list

check:
    bash scripts/check-env.sh

bootstrap:
    bash scripts/bootstrap.sh

build:
    forge build

test:
    forge test -vvv

format:
    forge fmt

fork-testnet:
    source .env && anvil --fork-url "$SOMNIA_RPC_TESTNET"

deploy-local:
    forge script script/DeployCounter.s.sol:DeployCounter --rpc-url http://127.0.0.1:8545 --broadcast

deploy-testnet:
    forge script script/DeployCounter.s.sol:DeployCounter --rpc-url somnia_testnet --broadcast

deploy-testnet-legacy:
    node --env-file=.env scripts/deploy-somnia-live.mjs

deploy-agent-example:
    forge script script/DeployAgentExample.s.sol:DeployAgentExample --rpc-url somnia_testnet --broadcast

request:
    node --env-file=.env --experimental-strip-types agents/request.ts
