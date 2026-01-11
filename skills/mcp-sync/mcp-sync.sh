#!/bin/bash
# MCP Server Sync - Expands templates and syncs MCP servers across machines
# Part of ~/.claude/ sync infrastructure
#
# Features:
# - ${HOME} expansion for paths
# - ${ENV:KEY} expansion from deep-env (synced credentials)
# - ${LOCAL:KEY} for machine-specific tokens (read from existing config)
# - _localAuth flag to preserve servers requiring local OAuth
# - Preserves local-only servers already configured

set -e

TEMPLATE_FILE="$HOME/.claude/mcp-servers.template.json"
TARGET_FILE="$HOME/.claude.json"
BACKUP_FILE="$HOME/.claude.json.backup"

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
log_dim() { echo -e "${DIM}[mcp-sync] $1${NC}"; }

# Check dependencies
check_deps() {
    if ! command -v jq &> /dev/null; then
        log_error "jq is required. Install with: brew install jq"
        exit 1
    fi
    if ! command -v deep-env &> /dev/null; then
        log_warn "deep-env not found - synced credentials won't be expanded"
    fi
}

# Get credential from deep-env
get_env_credential() {
    local key="$1"
    if command -v deep-env &> /dev/null; then
        local value=$(deep-env get "$key" 2>/dev/null || echo "")
        if [ -n "$value" ]; then
            echo "$value"
            return 0
        fi
    fi
    return 1
}

# Get local credential from existing ~/.claude.json
get_local_credential() {
    local server="$1"
    local path="$2"

    if [ -f "$TARGET_FILE" ]; then
        # Try to extract the value from existing config
        local value=$(jq -r ".mcpServers[\"$server\"]$path // empty" "$TARGET_FILE" 2>/dev/null)
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
            return 0
        fi
    fi
    return 1
}

# Expand all variables in a server config
expand_server() {
    local server_name="$1"
    local server_json="$2"

    # Check if this is a localAuth server
    local is_local_auth=$(echo "$server_json" | jq -r '._localAuth // false')

    # Expand ${HOME}
    server_json="${server_json//\$\{HOME\}/$HOME}"

    # Expand ${ENV:KEY} from deep-env
    while [[ "$server_json" =~ \$\{ENV:([A-Z_][A-Z0-9_]*)\} ]]; do
        local full_match="${BASH_REMATCH[0]}"
        local key="${BASH_REMATCH[1]}"
        local value=$(get_env_credential "$key")

        if [ -z "$value" ]; then
            log_warn "  Missing credential: $key"
            return 1
        fi

        local escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')
        server_json="${server_json//$full_match/$escaped_value}"
    done

    # Expand ${LOCAL:KEY} from existing config
    # For these, we look at the current server config in ~/.claude.json
    while [[ "$server_json" =~ \$\{LOCAL:([A-Z_][A-Z0-9_]*)\} ]]; do
        local full_match="${BASH_REMATCH[0]}"
        local key="${BASH_REMATCH[1]}"

        # Try to get from existing config based on key name
        local value=""
        case "$key" in
            *TOKEN*|*KEY*)
                # Look in headers.Authorization or env
                value=$(jq -r ".mcpServers[\"$server_name\"].headers.Authorization // empty" "$TARGET_FILE" 2>/dev/null | sed 's/Bearer //')
                if [ -z "$value" ] || [ "$value" == "null" ]; then
                    value=$(jq -r ".mcpServers[\"$server_name\"].env.$key // empty" "$TARGET_FILE" 2>/dev/null)
                fi
                ;;
        esac

        if [ -z "$value" ] || [ "$value" == "null" ]; then
            log_dim "  $server_name: requires local setup (${key} not found locally)"
            return 1
        fi

        local escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')
        server_json="${server_json//$full_match/$escaped_value}"
    done

    # Remove metadata fields before output
    server_json=$(echo "$server_json" | jq 'del(._localAuth)')

    echo "$server_json"
    return 0
}

# Get list of local-only servers from metadata
get_local_only_servers() {
    if [ -f "$TEMPLATE_FILE" ]; then
        jq -r '._metadata.localOnly // [] | .[]' "$TEMPLATE_FILE" 2>/dev/null
    fi
}

# Merge mcpServers into target file
merge_config() {
    local new_servers="$1"

    # Backup current config
    if [ -f "$TARGET_FILE" ]; then
        cp "$TARGET_FILE" "$BACKUP_FILE"
    fi

    if [ -f "$TARGET_FILE" ]; then
        # Get existing servers that are in localOnly list (preserve them)
        local local_only=$(get_local_only_servers)
        local preserved_servers="{}"

        for server in $local_only; do
            local existing=$(jq ".mcpServers[\"$server\"] // null" "$TARGET_FILE" 2>/dev/null)
            if [ -n "$existing" ] && [ "$existing" != "null" ]; then
                preserved_servers=$(echo "$preserved_servers" | jq --arg s "$server" --argjson c "$existing" '. + {($s): $c}')
                log_dim "  Preserved local-only: $server"
            fi
        done

        # Merge: new servers + preserved local-only servers
        local merged_servers=$(echo "$new_servers" | jq --argjson p "$preserved_servers" '. + $p')

        # Update target file
        jq --argjson servers "$merged_servers" '.mcpServers = $servers' "$TARGET_FILE" > "${TARGET_FILE}.tmp"
        mv "${TARGET_FILE}.tmp" "$TARGET_FILE"
    else
        # Create new file
        echo "{\"mcpServers\": $new_servers}" | jq '.' > "$TARGET_FILE"
    fi
}

# Main sync function
sync_servers() {
    log_info "Syncing MCP servers..."

    if [ ! -f "$TEMPLATE_FILE" ]; then
        log_error "Template not found: $TEMPLATE_FILE"
        exit 1
    fi

    local synced_servers="{}"
    local skipped=0
    local synced=0

    # Get all server names from template
    local servers=$(jq -r '.mcpServers | keys[]' "$TEMPLATE_FILE")

    for server in $servers; do
        local server_json=$(jq ".mcpServers[\"$server\"]" "$TEMPLATE_FILE")

        # Try to expand this server
        local expanded
        if expanded=$(expand_server "$server" "$server_json"); then
            if [ -n "$expanded" ]; then
                synced_servers=$(echo "$synced_servers" | jq --arg s "$server" --argjson c "$expanded" '. + {($s): $c}')
                log_success "  Synced: $server"
                ((synced++))
            else
                ((skipped++))
            fi
        else
            ((skipped++))
        fi
    done

    # Merge into target
    merge_config "$synced_servers"

    echo ""
    log_success "Synced $synced server(s)"
    if [ $skipped -gt 0 ]; then
        log_dim "Skipped $skipped server(s) requiring local setup"
    fi

    # Show setup instructions for skipped servers
    local setup_info=$(jq -r '._metadata.requiresSetup // {} | to_entries[] | "  \(.key): \(.value)"' "$TEMPLATE_FILE" 2>/dev/null)
    if [ -n "$setup_info" ] && [ $skipped -gt 0 ]; then
        echo ""
        log_info "To set up skipped servers on this machine:"
        echo "$setup_info"
    fi
}

# List current servers
list_servers() {
    log_info "MCP servers in template:"
    echo ""

    if [ -f "$TEMPLATE_FILE" ]; then
        # Build regex pattern for local-only servers
        local local_only=$(get_local_only_servers | paste -sd'|' -)

        jq -r '.mcpServers | to_entries[] | "\(.key)|\(.value.type)|\(.value._localAuth // false)"' "$TEMPLATE_FILE" | while IFS='|' read -r name type local_auth; do
            local status="sync"
            local note=""

            if [ "$local_auth" == "true" ]; then
                status="local-auth"
                note=" (requires local setup)"
            elif [ -n "$local_only" ] && echo "$name" | grep -qE "^($local_only)$"; then
                status="local-only"
                note=" (machine-specific)"
            fi

            printf "  %-20s %-8s %-12s%s\n" "$name" "($type)" "[$status]" "$note"
        done
    else
        log_warn "No template file found"
    fi
}

# Check for missing credentials
check_credentials() {
    log_info "Checking credentials..."
    echo ""

    local missing=0
    local found=0

    if [ -f "$TEMPLATE_FILE" ]; then
        # Check ENV credentials (synced)
        local env_keys=$(grep -oE '\$\{ENV:[A-Z_][A-Z0-9_]*\}' "$TEMPLATE_FILE" 2>/dev/null | sed 's/\${ENV:\([^}]*\)}/\1/' | sort -u)

        if [ -n "$env_keys" ]; then
            echo "Synced credentials (deep-env):"
            for key in $env_keys; do
                if get_env_credential "$key" > /dev/null 2>&1; then
                    echo -e "  ${GREEN}$key${NC}"
                    ((found++))
                else
                    echo -e "  ${RED}$key - MISSING${NC}"
                    echo "    Run: deep-env store $key <value>"
                    ((missing++))
                fi
            done
            echo ""
        fi

        # Check LOCAL credentials
        local local_keys=$(grep -oE '\$\{LOCAL:[A-Z_][A-Z0-9_]*\}' "$TEMPLATE_FILE" 2>/dev/null | sed 's/\${LOCAL:\([^}]*\)}/\1/' | sort -u)

        if [ -n "$local_keys" ]; then
            echo "Local credentials (machine-specific):"
            for key in $local_keys; do
                # These need to be set up on each machine
                echo -e "  ${YELLOW}$key${NC} - set up locally per machine"
            done
            echo ""
        fi
    fi

    if [ $missing -gt 0 ]; then
        log_warn "$missing synced credential(s) missing"
        return 1
    else
        log_success "All synced credentials found!"
    fi
}

# Show help
show_help() {
    cat << EOF
MCP Server Sync - Sync MCP servers across machines

Usage: mcp-sync.sh [command]

Commands:
  sync              Expand template and sync to ~/.claude.json (default)
  list              List servers and their sync status
  check             Check for missing credentials
  help              Show this help

Template Variables:
  \${HOME}           Home directory (works on any Mac)
  \${ENV:KEY}        Credential from deep-env (synced across machines)
  \${LOCAL:KEY}      Credential from local config (machine-specific)

Server Flags:
  _localAuth: true  Server requires local OAuth setup
  _metadata.localOnly: ["name"]  Server is completely machine-specific

Files:
  Template: ~/.claude/mcp-servers.template.json
  Target:   ~/.claude.json

Examples:
  mcp-sync.sh              # Sync all compatible servers
  mcp-sync.sh list         # See which servers sync vs stay local
  mcp-sync.sh check        # Verify credentials are set up

EOF
}

# Main
check_deps

case "${1:-sync}" in
    sync)
        sync_servers
        ;;
    list)
        list_servers
        ;;
    check)
        check_credentials
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
