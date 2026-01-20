#!/bin/bash
# Component detection and hash computation
# Computes hashes of plugin components for change detection

# Exclusion patterns for hashing
EXCLUDE_DIRS=(
    "node_modules"
    "venv"
    "dist"
    "__pycache__"
    ".git"
    ".DS_Store"
)

EXCLUDE_EXTENSIONS=(
    "pyc"
    "pyo"
    "egg-info"
)

# ============================================================================
# Hash Computation
# ============================================================================

# Compute hash of a single file
compute_file_hash() {
    local file="$1"
    shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1
}

# Compute hash of a directory (excluding specified patterns)
compute_dir_hash() {
    local dir="$1"

    if [ ! -d "$dir" ]; then
        echo ""
        return 1
    fi

    # Build find exclusion arguments
    local find_args=()
    for excl in "${EXCLUDE_DIRS[@]}"; do
        find_args+=(-not -path "*/$excl/*")
    done
    for ext in "${EXCLUDE_EXTENSIONS[@]}"; do
        find_args+=(-not -name "*.$ext")
    done

    # Find all files, sort them, compute combined hash
    find "$dir" -type f "${find_args[@]}" -print0 2>/dev/null | \
        sort -z | \
        xargs -0 shasum -a 256 2>/dev/null | \
        shasum -a 256 | \
        cut -d' ' -f1
}

# ============================================================================
# Component Hash Functions
# ============================================================================

# Compute hash for a skill directory
compute_skill_hash() {
    local skill_dir="$1"
    compute_dir_hash "$skill_dir"
}

# Compute hash for a server directory
compute_server_hash() {
    local server_dir="$1"
    compute_dir_hash "$server_dir"
}

# Compute hash for commands directory
compute_commands_hash() {
    local commands_dir="$1"
    compute_dir_hash "$commands_dir"
}

# Compute hash for hooks directory
compute_hooks_hash() {
    local hooks_dir="$1"
    compute_dir_hash "$hooks_dir"
}

# Compute hash for agents directory
compute_agents_hash() {
    local agents_dir="$1"
    compute_dir_hash "$agents_dir"
}

# Compute hash for MCP config file
compute_mcp_config_hash() {
    local mcp_file="$1"
    if [ -f "$mcp_file" ]; then
        compute_file_hash "$mcp_file"
    else
        echo ""
    fi
}

# Compute hash for global commands directory (~/.claude/commands)
compute_global_commands_hash() {
    local commands_dir="$HOME/.claude/commands"
    if [ -d "$commands_dir" ]; then
        compute_dir_hash "$commands_dir"
    else
        echo ""
    fi
}

# Compute hash for user CLAUDE.md file (~/.claude/CLAUDE.md)
compute_user_claude_md_hash() {
    local claude_md="$HOME/.claude/CLAUDE.md"
    if [ -f "$claude_md" ]; then
        compute_file_hash "$claude_md"
    else
        echo ""
    fi
}

# ============================================================================
# Main Hash Collection
# ============================================================================

# Compute hashes for all components in the plugin directory
# Outputs JSON to stdout
compute_all_local_hashes() {
    local plugin_dir="$1"

    echo "{"

    # Skills - each skill is tracked separately
    local skills_json=""
    if [ -d "$plugin_dir/skills" ]; then
        for skill_path in "$plugin_dir/skills"/*; do
            if [ -d "$skill_path" ]; then
                local skill_name=$(basename "$skill_path")
                local skill_hash=$(compute_skill_hash "$skill_path")
                if [ -n "$skill_hash" ]; then
                    [ -n "$skills_json" ] && skills_json+=","
                    skills_json+="\"skills/$skill_name\":\"$skill_hash\""
                fi
            fi
        done
    fi

    # Servers - each server is tracked separately
    local servers_json=""
    if [ -d "$plugin_dir/servers" ]; then
        for server_path in "$plugin_dir/servers"/*; do
            if [ -d "$server_path" ]; then
                local server_name=$(basename "$server_path")
                local server_hash=$(compute_server_hash "$server_path")
                if [ -n "$server_hash" ]; then
                    [ -n "$servers_json" ] && servers_json+=","
                    servers_json+="\"servers/$server_name\":\"$server_hash\""
                fi
            fi
        done
    fi

    # Commands - entire directory tracked as one
    local commands_hash=""
    if [ -d "$plugin_dir/commands" ]; then
        commands_hash=$(compute_commands_hash "$plugin_dir/commands")
    fi

    # Hooks - entire directory tracked as one
    local hooks_hash=""
    if [ -d "$plugin_dir/hooks" ]; then
        hooks_hash=$(compute_hooks_hash "$plugin_dir/hooks")
    fi

    # Agents - entire directory tracked as one
    local agents_hash=""
    if [ -d "$plugin_dir/agents" ]; then
        agents_hash=$(compute_agents_hash "$plugin_dir/agents")
    fi

    # MCP config
    local mcp_hash=""
    if [ -f "$plugin_dir/.mcp.json" ]; then
        mcp_hash=$(compute_mcp_config_hash "$plugin_dir/.mcp.json")
    fi

    # Global commands - ~/.claude/commands (separate from plugin commands)
    local global_commands_hash=""
    global_commands_hash=$(compute_global_commands_hash)

    # User CLAUDE.md - ~/.claude/CLAUDE.md
    local user_claude_md_hash=""
    user_claude_md_hash=$(compute_user_claude_md_hash)

    # Build output JSON
    local output=""

    # Add skills
    if [ -n "$skills_json" ]; then
        output+="$skills_json"
    fi

    # Add servers
    if [ -n "$servers_json" ]; then
        [ -n "$output" ] && output+=","
        output+="$servers_json"
    fi

    # Add commands
    if [ -n "$commands_hash" ]; then
        [ -n "$output" ] && output+=","
        output+="\"commands\":\"$commands_hash\""
    fi

    # Add hooks
    if [ -n "$hooks_hash" ]; then
        [ -n "$output" ] && output+=","
        output+="\"hooks\":\"$hooks_hash\""
    fi

    # Add agents
    if [ -n "$agents_hash" ]; then
        [ -n "$output" ] && output+=","
        output+="\"agents\":\"$agents_hash\""
    fi

    # Add MCP config
    if [ -n "$mcp_hash" ]; then
        [ -n "$output" ] && output+=","
        output+="\"mcp-config\":\"$mcp_hash\""
    fi

    # Add global commands
    if [ -n "$global_commands_hash" ]; then
        [ -n "$output" ] && output+=","
        output+="\"global-commands\":\"$global_commands_hash\""
    fi

    # Add user CLAUDE.md
    if [ -n "$user_claude_md_hash" ]; then
        [ -n "$output" ] && output+=","
        output+="\"user-claude-md\":\"$user_claude_md_hash\""
    fi

    echo "$output"
    echo "}"
}

# ============================================================================
# Comparison Functions
# ============================================================================

# Global arrays for diff results (bash 3 compatible - no namerefs)
DIFF_TO_PUSH=()
DIFF_TO_PULL=()

# Compare local hashes with remote manifest
# Sets global arrays: DIFF_TO_PUSH (local newer) and DIFF_TO_PULL (remote newer)
diff_components() {
    local local_hashes_file="$1"
    local remote_manifest_file="$2"

    # Reset global arrays
    DIFF_TO_PUSH=()
    DIFF_TO_PULL=()

    # Read local hashes
    local local_hashes=$(cat "$local_hashes_file")

    # Check if remote manifest exists
    if [ ! -f "$remote_manifest_file" ]; then
        # No remote - push everything
        while IFS= read -r key; do
            [ -n "$key" ] && DIFF_TO_PUSH+=("$key")
        done < <(echo "$local_hashes" | jq -r 'keys[]' 2>/dev/null)
        return
    fi

    # Read remote manifest
    local remote_manifest=$(cat "$remote_manifest_file")

    # Get all local component keys
    local local_keys=$(echo "$local_hashes" | jq -r 'keys[]' 2>/dev/null)

    # Get all remote component keys (flatten the nested structure)
    local remote_keys=$(echo "$remote_manifest" | jq -r '
        .components |
        (
            (.skills // {} | keys | map("skills/" + .)) +
            (.servers // {} | keys | map("servers/" + .)) +
            (if .commands.hash and .commands.hash != "" then ["commands"] else [] end) +
            (if .hooks.hash and .hooks.hash != "" then ["hooks"] else [] end) +
            (if .agents.hash and .agents.hash != "" then ["agents"] else [] end) +
            (if ."mcp-config".hash and ."mcp-config".hash != "" then ["mcp-config"] else [] end) +
            (if ."global-commands".hash and ."global-commands".hash != "" then ["global-commands"] else [] end) +
            (if ."user-claude-md".hash and ."user-claude-md".hash != "" then ["user-claude-md"] else [] end)
        )[]
    ' 2>/dev/null)

    # For each local component
    while IFS= read -r key; do
        [ -z "$key" ] && continue

        local local_hash=$(echo "$local_hashes" | jq -r ".[\"$key\"] // empty" 2>/dev/null)
        local remote_hash=""
        local remote_updated_at=0

        # Get remote hash based on component type
        case "$key" in
            skills/*)
                local skill_name="${key#skills/}"
                remote_hash=$(echo "$remote_manifest" | jq -r ".components.skills[\"$skill_name\"].hash // empty" 2>/dev/null)
                remote_updated_at=$(echo "$remote_manifest" | jq -r ".components.skills[\"$skill_name\"].updated_at // 0" 2>/dev/null)
                ;;
            servers/*)
                local server_name="${key#servers/}"
                remote_hash=$(echo "$remote_manifest" | jq -r ".components.servers[\"$server_name\"].hash // empty" 2>/dev/null)
                remote_updated_at=$(echo "$remote_manifest" | jq -r ".components.servers[\"$server_name\"].updated_at // 0" 2>/dev/null)
                ;;
            commands)
                remote_hash=$(echo "$remote_manifest" | jq -r '.components.commands.hash // empty' 2>/dev/null)
                remote_updated_at=$(echo "$remote_manifest" | jq -r '.components.commands.updated_at // 0' 2>/dev/null)
                ;;
            hooks)
                remote_hash=$(echo "$remote_manifest" | jq -r '.components.hooks.hash // empty' 2>/dev/null)
                remote_updated_at=$(echo "$remote_manifest" | jq -r '.components.hooks.updated_at // 0' 2>/dev/null)
                ;;
            agents)
                remote_hash=$(echo "$remote_manifest" | jq -r '.components.agents.hash // empty' 2>/dev/null)
                remote_updated_at=$(echo "$remote_manifest" | jq -r '.components.agents.updated_at // 0' 2>/dev/null)
                ;;
            mcp-config)
                remote_hash=$(echo "$remote_manifest" | jq -r '.components."mcp-config".hash // empty' 2>/dev/null)
                remote_updated_at=$(echo "$remote_manifest" | jq -r '.components."mcp-config".updated_at // 0' 2>/dev/null)
                ;;
            global-commands)
                remote_hash=$(echo "$remote_manifest" | jq -r '.components."global-commands".hash // empty' 2>/dev/null)
                remote_updated_at=$(echo "$remote_manifest" | jq -r '.components."global-commands".updated_at // 0' 2>/dev/null)
                ;;
            user-claude-md)
                remote_hash=$(echo "$remote_manifest" | jq -r '.components."user-claude-md".hash // empty' 2>/dev/null)
                remote_updated_at=$(echo "$remote_manifest" | jq -r '.components."user-claude-md".updated_at // 0' 2>/dev/null)
                ;;
        esac

        if [ "$local_hash" != "$remote_hash" ]; then
            if [ -z "$remote_hash" ]; then
                # New local component - push
                DIFF_TO_PUSH+=("$key")
            else
                # Both exist but different - need to determine which is newer
                # We'll push if we don't have a local state file showing we already pulled this
                # For now, trust that local changes should be pushed
                DIFF_TO_PUSH+=("$key")
            fi
        fi
    done <<< "$local_keys"

    # Check for remote-only components (need to pull)
    while IFS= read -r key; do
        [ -z "$key" ] && continue

        local local_hash=$(echo "$local_hashes" | jq -r ".[\"$key\"] // empty" 2>/dev/null)

        if [ -z "$local_hash" ]; then
            # Remote only - pull
            DIFF_TO_PULL+=("$key")
        fi
    done <<< "$remote_keys"
}

# Get the hash of a component from the remote manifest
get_remote_hash() {
    local manifest_file="$1"
    local component="$2"

    if [ ! -f "$manifest_file" ]; then
        echo ""
        return
    fi

    case "$component" in
        skills/*)
            local skill_name="${component#skills/}"
            jq -r ".components.skills[\"$skill_name\"].hash // empty" "$manifest_file" 2>/dev/null
            ;;
        servers/*)
            local server_name="${component#servers/}"
            jq -r ".components.servers[\"$server_name\"].hash // empty" "$manifest_file" 2>/dev/null
            ;;
        commands)
            jq -r '.components.commands.hash // empty' "$manifest_file" 2>/dev/null
            ;;
        hooks)
            jq -r '.components.hooks.hash // empty' "$manifest_file" 2>/dev/null
            ;;
        agents)
            jq -r '.components.agents.hash // empty' "$manifest_file" 2>/dev/null
            ;;
        mcp-config)
            jq -r '.components."mcp-config".hash // empty' "$manifest_file" 2>/dev/null
            ;;
        global-commands)
            jq -r '.components."global-commands".hash // empty' "$manifest_file" 2>/dev/null
            ;;
        user-claude-md)
            jq -r '.components."user-claude-md".hash // empty' "$manifest_file" 2>/dev/null
            ;;
        *)
            echo ""
            ;;
    esac
}

# Get the updated_at timestamp of a component from the remote manifest
get_remote_updated_at() {
    local manifest_file="$1"
    local component="$2"

    if [ ! -f "$manifest_file" ]; then
        echo "0"
        return
    fi

    case "$component" in
        skills/*)
            local skill_name="${component#skills/}"
            jq -r ".components.skills[\"$skill_name\"].updated_at // 0" "$manifest_file" 2>/dev/null
            ;;
        servers/*)
            local server_name="${component#servers/}"
            jq -r ".components.servers[\"$server_name\"].updated_at // 0" "$manifest_file" 2>/dev/null
            ;;
        commands)
            jq -r '.components.commands.updated_at // 0' "$manifest_file" 2>/dev/null
            ;;
        hooks)
            jq -r '.components.hooks.updated_at // 0' "$manifest_file" 2>/dev/null
            ;;
        agents)
            jq -r '.components.agents.updated_at // 0' "$manifest_file" 2>/dev/null
            ;;
        mcp-config)
            jq -r '.components."mcp-config".updated_at // 0' "$manifest_file" 2>/dev/null
            ;;
        global-commands)
            jq -r '.components."global-commands".updated_at // 0' "$manifest_file" 2>/dev/null
            ;;
        user-claude-md)
            jq -r '.components."user-claude-md".updated_at // 0' "$manifest_file" 2>/dev/null
            ;;
        *)
            echo "0"
            ;;
    esac
}
