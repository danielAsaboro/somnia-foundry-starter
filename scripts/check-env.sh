#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

required_commands=(
  git
  node
  npm
  pnpm
  forge
  cast
  anvil
  cargo
  rustup
  jq
  just
)

optional_commands=(
  brew
  docker
  docker-compose
  direnv
  solc
)

status=0

print_section() {
  printf "\n[%s]\n" "$1"
}

check_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf "ok   %-15s %s\n" "$name" "$(command -v "$name")"
  else
    printf "miss %-15s not installed\n" "$name"
    status=1
  fi
}

check_optional_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf "ok   %-15s %s\n" "$name" "$(command -v "$name")"
  else
    printf "warn %-15s optional but recommended\n" "$name"
  fi
}

print_section "required commands"
for cmd in "${required_commands[@]}"; do
  check_command "$cmd"
done

print_section "optional commands"
for cmd in "${optional_commands[@]}"; do
  check_optional_command "$cmd"
done

print_section "versions"
node --version || true
pnpm --version || true
forge --version | head -n 1 || true
cargo --version || true

print_section "environment files"
if [[ -f .env ]]; then
  echo "ok   .env present"
else
  echo "warn .env missing; copy .env.example to .env"
fi

if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  source .env

  print_section "somnia variables"
  for var_name in SOMNIA_RPC_MAINNET SOMNIA_RPC_TESTNET SOMNIA_MAINNET_CHAIN_ID SOMNIA_TESTNET_CHAIN_ID; do
    if [[ -n "${!var_name:-}" ]]; then
      printf "ok   %s=%s\n" "$var_name" "${!var_name}"
    else
      printf "warn %s is empty\n" "$var_name"
    fi
  done

  if [[ "${VERIFY_RPC:-0}" == "1" && -n "${SOMNIA_RPC_TESTNET:-}" ]]; then
    print_section "rpc verification"
    if cast chain-id --rpc-url "$SOMNIA_RPC_TESTNET" >/tmp/somnia_chain_id.txt 2>/tmp/somnia_chain_id.err; then
      printf "ok   testnet chain id %s\n" "$(cat /tmp/somnia_chain_id.txt)"
    else
      echo "warn RPC verification failed"
      cat /tmp/somnia_chain_id.err
    fi
  fi
fi

print_section "docker daemon"
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    echo "ok   docker daemon running"
  else
    echo "warn docker installed but daemon unavailable"
  fi
fi

exit "$status"

