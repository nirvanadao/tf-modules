#!/usr/bin/env bash
#
# Validate all Terraform modules.
#
# Usage:
#   ./scripts/validate-all.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULES_DIR="$ROOT_DIR/modules"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

failed=0

for dir in "$MODULES_DIR"/*/; do
  module=$(basename "$dir")

  # Skip if no .tf files
  if ! ls "$dir"/*.tf &>/dev/null; then
    continue
  fi

  # Init (suppress output)
  if ! terraform -chdir="$dir" init -backend=false -input=false >/dev/null 2>&1; then
    echo -e "${RED}✗ $module (init failed)${NC}"
    failed=1
    continue
  fi

  # Validate
  if terraform -chdir="$dir" validate >/dev/null 2>&1; then
    echo -e "${GREEN}✓ $module${NC}"
  else
    echo -e "${RED}✗ $module${NC}"
    terraform -chdir="$dir" validate 2>&1 | head -20
    failed=1
  fi
done

exit $failed
