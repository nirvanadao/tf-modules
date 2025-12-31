#!/usr/bin/env bash
#
# Generate Terraform module documentation using terraform-docs.
#
# Usage:
#   ./scripts/generate-docs.sh           # Generate docs for all modules
#   ./scripts/generate-docs.sh --check   # Check if docs are up to date (for CI)
#   ./scripts/generate-docs.sh <module>  # Generate docs for a specific module
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULES_DIR="$ROOT_DIR/modules"
CONFIG_FILE="$ROOT_DIR/.terraform-docs.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if terraform-docs is installed
check_terraform_docs() {
  if ! command -v terraform-docs &> /dev/null; then
    echo -e "${RED}Error: terraform-docs is not installed.${NC}"
    echo ""
    echo "Install it with:"
    echo "  brew install terraform-docs        # macOS"
    echo "  go install github.com/terraform-docs/terraform-docs@latest  # Go"
    echo ""
    echo "Or download from: https://terraform-docs.io/user-guide/installation/"
    exit 1
  fi
}

# Generate docs for a single module
generate_module_docs() {
  local module_path="$1"
  local module_name=$(basename "$module_path")

  # Skip if no .tf files
  if ! ls "$module_path"/*.tf &> /dev/null; then
    echo -e "${YELLOW}Skipping $module_name (no .tf files)${NC}"
    return 0
  fi

  # Ensure README.md exists with markers
  local readme="$module_path/README.md"
  if [[ ! -f "$readme" ]]; then
    echo "# $module_name" > "$readme"
    echo "" >> "$readme"
    echo "<!-- BEGIN_TF_DOCS -->" >> "$readme"
    echo "<!-- END_TF_DOCS -->" >> "$readme"
    echo -e "${YELLOW}Created $readme${NC}"
  elif ! grep -q "BEGIN_TF_DOCS" "$readme"; then
    echo "" >> "$readme"
    echo "<!-- BEGIN_TF_DOCS -->" >> "$readme"
    echo "<!-- END_TF_DOCS -->" >> "$readme"
    echo -e "${YELLOW}Added markers to $readme${NC}"
  fi

  # Generate docs
  terraform-docs -c "$CONFIG_FILE" "$module_path"
  echo -e "${GREEN}✓ $module_name${NC}"
}

# Check if docs are up to date (returns non-zero if changes needed)
check_docs() {
  local has_changes=0

  for module_dir in "$MODULES_DIR"/*/; do
    if [[ -d "$module_dir" ]]; then
      local module_name=$(basename "$module_dir")
      local readme="$module_dir/README.md"

      # Skip if no .tf files
      if ! ls "$module_dir"/*.tf &> /dev/null; then
        continue
      fi

      # Generate to temp file and compare
      local temp_readme=$(mktemp)
      if [[ -f "$readme" ]]; then
        cp "$readme" "$temp_readme"
      fi

      terraform-docs -c "$CONFIG_FILE" "$module_dir" 2>/dev/null

      if [[ -f "$readme" ]] && ! diff -q "$readme" "$temp_readme" > /dev/null 2>&1; then
        echo -e "${RED}✗ $module_name - docs out of date${NC}"
        has_changes=1
        # Restore original
        cp "$temp_readme" "$readme"
      else
        echo -e "${GREEN}✓ $module_name${NC}"
      fi

      rm -f "$temp_readme"
    fi
  done

  if [[ $has_changes -eq 1 ]]; then
    echo ""
    echo -e "${RED}Some module docs are out of date. Run './scripts/generate-docs.sh' to update.${NC}"
    exit 1
  fi

  echo ""
  echo -e "${GREEN}All module docs are up to date.${NC}"
}

# Main
main() {
  check_terraform_docs

  cd "$ROOT_DIR"

  # Check mode
  if [[ "${1:-}" == "--check" ]]; then
    echo "Checking if documentation is up to date..."
    echo ""
    check_docs
    exit 0
  fi

  # Single module mode
  if [[ -n "${1:-}" ]]; then
    local module_path="$MODULES_DIR/$1"
    if [[ ! -d "$module_path" ]]; then
      echo -e "${RED}Error: Module '$1' not found at $module_path${NC}"
      exit 1
    fi
    echo "Generating docs for $1..."
    generate_module_docs "$module_path"
    exit 0
  fi

  # All modules
  echo "Generating documentation for all modules..."
  echo ""

  for module_dir in "$MODULES_DIR"/*/; do
    if [[ -d "$module_dir" ]]; then
      generate_module_docs "$module_dir"
    fi
  done

  echo ""
  echo -e "${GREEN}Done! Documentation generated for all modules.${NC}"
}

main "$@"
