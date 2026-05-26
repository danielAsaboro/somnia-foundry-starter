#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[bootstrap] preparing local Somnia workspace"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "[bootstrap] created .env from .env.example"
else
  echo "[bootstrap] .env already exists"
fi

mkdir -p contracts test script src

echo "[bootstrap] running environment checks"
bash scripts/check-env.sh || true

echo "[bootstrap] done"
