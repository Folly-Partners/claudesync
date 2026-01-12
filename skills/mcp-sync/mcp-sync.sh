#!/bin/bash
# MCP Server Sync - Check and manage MCP server configuration
#
# Claude Code natively supports ${VAR} expansion in mcp.json.
# This script helps verify credentials are available.

set -e

MCP_JSON="$HOME/.claude/mcp.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[mcp-sync]${NC} $1"; }
log_success() { echo -e "${GREEN}[mcp-sync]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[mcp-sync]${NC} $1"; }
log_error() { echo -e "${RED}[mcp-sync]${NC} $1"; }

# Check dependencies
check_deps() {
    if ! command -v jq &> /dev/null; then
        log_error "jq is required. Install with: brew install jq"
        exit 1
    fi
}

# Extract ${VAR} references from mcp.json
get_required_vars() {
    if [ -f "$MCP_JSON" ]; then
        grep -oE '\$\{[A-Z_][A-Z0-9_]*\}' "$MCP_JSON" 2>/dev/null | \
            sed 's/\${\([^}]*\)}/\1/' | \
            grep -v '^HOME$' | \
            sort -u
    fi
}

# Check if env var is set
check_var() {
    local var="$1"
    if [ -n "${!var}" ]; then
        return 0
    fi
    # Also check deep-env
    if command -v deep-env &> /dev/null; then
        if deep-env get "$var" &> /dev/null; then
            return 0
        fi
    fi
    return 1
}

# List servers in mcp.json
list_servers() {
    log_info "MCP servers in ~/.claude/mcp.json:"
    echo ""

    if [ ! -f "$MCP_JSON" ]; then
        log_warn "No mcp.json found"
        return
    fi

    jq -r '.mcpServers | to_entries[] | "\(.key)|\(.value.type)"' "$MCP_JSON" 2>/dev/null | \
    while IFS='|' read -r name type; do
        printf "  %-20s %s\n" "$name" "($type)"
    done
}

# Check credentials
check_credentials() {
    log_info "Checking environment variables for MCP servers..."
    echo ""

    local vars=$(get_required_vars)
    local missing=0
    local found=0

    if [ -z "$vars" ]; then
        log_success "No credential variables found in mcp.json"
        return 0
    fi

    echo "Required environment variables:"
    for var in $vars; do
        if check_var "$var"; then
            echo -e "  ${GREEN}$var${NC} - set"
            ((found++))
        else
            echo -e "  ${RED}$var${NC} - MISSING"
            ((missing++))
        fi
    done

    echo ""
    if [ $missing -gt 0 ]; then
        log_warn "$missing variable(s) missing"
        echo ""
        echo "To fix:"
        echo "  1. Store in deep-env:  deep-env store VAR_NAME 'value'"
        echo "  2. Push to iCloud:     deep-env push"
        echo "  3. Reload shell:       source ~/.zshrc"
        return 1
    else
        log_success "All variables available!"
    fi
}

# Reload environment from deep-env
reload_env() {
    log_info "Reloading environment from deep-env..."
    if command -v deep-env &> /dev/null; then
        eval "$(deep-env export 2>/dev/null)"
        log_success "Environment reloaded"
        echo ""
        check_credentials
    else
        log_error "deep-env not found"
    fi
}

# Show help
show_help() {
    cat << EOF
MCP Server Sync - Check MCP server configuration

Claude Code natively expands \${VAR} in mcp.json. This script helps
verify that required environment variables are available.

Usage: mcp-sync.sh [command]

Commands:
  check             Check if required env vars are set (default)
  list              List servers in mcp.json
  reload            Reload env vars from deep-env and check
  help              Show this help

How it works:
  - mcp.json uses \${HOME} for paths (always available)
  - mcp.json uses \${VAR} for credentials
  - Credentials stored in deep-env (macOS Keychain)
  - deep-env export loads them into your shell

Setup on new Mac:
  deep-env pull          # Pull credentials from iCloud
  source ~/.zshrc        # Reload shell to get env vars

EOF
}

# Main
check_deps

case "${1:-check}" in
    check)
        check_credentials
        ;;
    list)
        list_servers
        ;;
    reload)
        reload_env
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
