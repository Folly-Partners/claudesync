#!/bin/bash
# Manifest management and conflict detection
# Handles registry initialization, manifest updates, and conflict resolution

# ============================================================================
# Registry Initialization
# ============================================================================

# Initialize the iCloud registry if it doesn't exist
init_registry_if_needed() {
    if [ -f "$REGISTRY/manifest.json" ]; then
        return 0
    fi

    local machine_id=$(get_machine_id)
    local now=$(date +%s)
    local now_iso=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Create directory structure
    mkdir -p "$REGISTRY/components/skills"
    mkdir -p "$REGISTRY/components/servers"
    mkdir -p "$REGISTRY/components/commands"
    mkdir -p "$REGISTRY/components/hooks"
    mkdir -p "$REGISTRY/components/agents"
    mkdir -p "$REGISTRY/machines"

    # Create initial manifest
    cat > "$REGISTRY/manifest.json" << EOF
{
  "version": 1,
  "runtime": {
    "node": "20",
    "python": "3.11"
  },
  "created_at": "$now_iso",
  "created_by": "$machine_id",
  "components": {
    "skills": {},
    "servers": {},
    "commands": {
      "hash": "",
      "updated_at": 0,
      "updated_by": ""
    },
    "hooks": {
      "hash": "",
      "updated_at": 0,
      "updated_by": ""
    },
    "agents": {
      "hash": "",
      "updated_at": 0,
      "updated_by": ""
    },
    "mcp-config": {
      "hash": "",
      "updated_at": 0,
      "updated_by": "",
      "encrypted": false
    }
  }
}
EOF

    # Push all current components to initialize
    if [ -d "$PLUGIN_DIR" ]; then
        push_all_components "$PLUGIN_DIR" "$machine_id"
    fi

    log_debug "Registry initialized at $REGISTRY"
}

# ============================================================================
# Manifest Update Functions
# ============================================================================

# Update manifest for a skill or server component
update_manifest_component() {
    local component_type="$1"  # skills or servers
    local component_name="$2"
    local machine_id="$3"
    local timestamp="$4"
    local source_dir="$5"

    local manifest="$REGISTRY/manifest.json"

    if [ ! -f "$manifest" ]; then
        log_error "Manifest not found"
        return 1
    fi

    # Compute hash
    local hash=$(compute_dir_hash "$source_dir")

    # Update manifest using jq
    local temp_manifest=$(mktemp)

    jq --arg type "$component_type" \
       --arg name "$component_name" \
       --arg hash "$hash" \
       --argjson updated_at "$timestamp" \
       --arg updated_by "$machine_id" \
       --arg file "$component_type/${component_name}.tar.gz" \
       '.components[$type][$name] = {
         "hash": $hash,
         "updated_at": $updated_at,
         "updated_by": $updated_by,
         "file": $file
       }' "$manifest" > "$temp_manifest"

    # Atomic update
    mv "$temp_manifest" "$manifest"
}

# Update manifest for a server with build info
update_manifest_server() {
    local server_name="$1"
    local machine_id="$2"
    local timestamp="$3"
    local source_dir="$4"

    local manifest="$REGISTRY/manifest.json"

    if [ ! -f "$manifest" ]; then
        log_error "Manifest not found"
        return 1
    fi

    # Compute hash
    local hash=$(compute_dir_hash "$source_dir")

    # Detect build type and command
    local build_type=$(detect_build_type "$source_dir")
    local build_cmd=$(get_build_cmd "$server_name")

    # Update manifest using jq
    local temp_manifest=$(mktemp)

    jq --arg name "$server_name" \
       --arg hash "$hash" \
       --argjson updated_at "$timestamp" \
       --arg updated_by "$machine_id" \
       --arg file "servers/${server_name}.tar.gz" \
       --arg build_type "$build_type" \
       --arg build_cmd "$build_cmd" \
       '.components.servers[$name] = {
         "hash": $hash,
         "updated_at": $updated_at,
         "updated_by": $updated_by,
         "file": $file,
         "build_type": $build_type,
         "build_cmd": $build_cmd
       }' "$manifest" > "$temp_manifest"

    # Atomic update
    mv "$temp_manifest" "$manifest"
}

# Update manifest for simple components (commands, hooks, agents)
update_manifest_simple() {
    local component_type="$1"  # commands, hooks, agents
    local machine_id="$2"
    local timestamp="$3"
    local source_dir="$4"

    local manifest="$REGISTRY/manifest.json"

    if [ ! -f "$manifest" ]; then
        log_error "Manifest not found"
        return 1
    fi

    # Compute hash
    local hash=$(compute_dir_hash "$source_dir")

    # Update manifest using jq
    local temp_manifest=$(mktemp)

    jq --arg type "$component_type" \
       --arg hash "$hash" \
       --argjson updated_at "$timestamp" \
       --arg updated_by "$machine_id" \
       '.components[$type] = {
         "hash": $hash,
         "updated_at": $updated_at,
         "updated_by": $updated_by
       }' "$manifest" > "$temp_manifest"

    # Atomic update
    mv "$temp_manifest" "$manifest"
}

# Update manifest for MCP config
update_manifest_mcp_config() {
    local machine_id="$1"
    local timestamp="$2"
    local source_file="$3"

    local manifest="$REGISTRY/manifest.json"

    if [ ! -f "$manifest" ]; then
        log_error "Manifest not found"
        return 1
    fi

    # Compute hash
    local hash=$(compute_file_hash "$source_file")

    # Update manifest using jq
    local temp_manifest=$(mktemp)

    jq --arg hash "$hash" \
       --argjson updated_at "$timestamp" \
       --arg updated_by "$machine_id" \
       '.components."mcp-config" = {
         "hash": $hash,
         "updated_at": $updated_at,
         "updated_by": $updated_by,
         "encrypted": false
       }' "$manifest" > "$temp_manifest"

    # Atomic update
    mv "$temp_manifest" "$manifest"
}

# ============================================================================
# Machine State Management
# ============================================================================

# Update machine state in registry
update_machine_state() {
    local machine_id="$1"
    local timestamp="$2"

    local machine_file="$REGISTRY/machines/${machine_id}.json"
    local state_file="$STATE_FILE"

    # Read current synced hashes
    local synced_components="{}"
    if [ -f "$state_file" ]; then
        synced_components=$(cat "$state_file")
    fi

    # Create machine state file
    cat > "$machine_file" << EOF
{
  "hostname": "$machine_id",
  "last_sync": $timestamp,
  "last_push": $timestamp,
  "last_pull": $timestamp,
  "synced_components": $synced_components
}
EOF
}

# ============================================================================
# Conflict Detection
# ============================================================================

# Check for conflicts before pushing
check_for_conflict() {
    local component="$1"
    local local_hash="$2"
    local machine_id="$3"

    local manifest="$REGISTRY/manifest.json"

    if [ ! -f "$manifest" ]; then
        return 1  # No conflict if no manifest
    fi

    local remote_hash=$(get_remote_hash "$manifest" "$component")
    local remote_updated_at=$(get_remote_updated_at "$manifest" "$component")
    local remote_updated_by=""

    # Get remote updated_by
    case "$component" in
        skills/*)
            local name="${component#skills/}"
            remote_updated_by=$(jq -r ".components.skills[\"$name\"].updated_by // empty" "$manifest" 2>/dev/null)
            ;;
        servers/*)
            local name="${component#servers/}"
            remote_updated_by=$(jq -r ".components.servers[\"$name\"].updated_by // empty" "$manifest" 2>/dev/null)
            ;;
        commands|hooks|agents)
            remote_updated_by=$(jq -r ".components.$component.updated_by // empty" "$manifest" 2>/dev/null)
            ;;
        mcp-config)
            remote_updated_by=$(jq -r '.components."mcp-config".updated_by // empty' "$manifest" 2>/dev/null)
            ;;
    esac

    # No conflict if hashes match
    if [ "$local_hash" = "$remote_hash" ]; then
        return 1
    fi

    # No conflict if remote is empty
    if [ -z "$remote_hash" ]; then
        return 1
    fi

    # No conflict if we were the last updater
    if [ "$remote_updated_by" = "$machine_id" ]; then
        return 1
    fi

    # Check if updates are within conflict window
    local now=$(date +%s)
    local time_diff=$((now - remote_updated_at))

    if [ $time_diff -lt $CONFLICT_WINDOW ]; then
        return 0  # Conflict detected
    fi

    return 1  # No conflict (remote is older)
}

# Log a conflict
log_conflict() {
    local component="$1"
    local local_hash="$2"
    local remote_hash="$3"
    local machine_id="$4"
    local remote_machine="$5"

    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    echo "[$timestamp] CONFLICT: $component" >> "$CONFLICTS_LOG"
    echo "  Local ($machine_id): $local_hash" >> "$CONFLICTS_LOG"
    echo "  Remote ($remote_machine): $remote_hash" >> "$CONFLICTS_LOG"
    echo "  Resolution: Local wins (most recent)" >> "$CONFLICTS_LOG"
    echo "" >> "$CONFLICTS_LOG"
}

# Handle a conflict by keeping both versions
handle_conflict() {
    local component="$1"
    local machine_id="$2"

    local manifest="$REGISTRY/manifest.json"

    # Get remote info
    local remote_machine=""
    local remote_hash=""

    case "$component" in
        skills/*)
            local name="${component#skills/}"
            remote_machine=$(jq -r ".components.skills[\"$name\"].updated_by // empty" "$manifest" 2>/dev/null)
            remote_hash=$(jq -r ".components.skills[\"$name\"].hash // empty" "$manifest" 2>/dev/null)

            # Keep both versions
            local remote_tarball="$REGISTRY/components/skills/${name}.tar.gz"
            local conflict_tarball="$REGISTRY/components/skills/${name}.${remote_machine}.tar.gz"
            if [ -f "$remote_tarball" ]; then
                cp "$remote_tarball" "$conflict_tarball"
            fi
            ;;
        servers/*)
            local name="${component#servers/}"
            remote_machine=$(jq -r ".components.servers[\"$name\"].updated_by // empty" "$manifest" 2>/dev/null)
            remote_hash=$(jq -r ".components.servers[\"$name\"].hash // empty" "$manifest" 2>/dev/null)

            # Keep both versions
            local remote_tarball="$REGISTRY/components/servers/${name}.tar.gz"
            local conflict_tarball="$REGISTRY/components/servers/${name}.${remote_machine}.tar.gz"
            if [ -f "$remote_tarball" ]; then
                cp "$remote_tarball" "$conflict_tarball"
            fi
            ;;
        *)
            # For simple components, just log the conflict
            remote_machine=$(jq -r ".components.$component.updated_by // empty" "$manifest" 2>/dev/null)
            remote_hash=$(jq -r ".components.$component.hash // empty" "$manifest" 2>/dev/null)
            ;;
    esac

    # Get local hash
    local local_hash=""
    if [ -f "$STATE_FILE" ]; then
        local_hash=$(jq -r ".[\"$component\"] // empty" "$STATE_FILE" 2>/dev/null)
    fi

    # Log the conflict
    log_conflict "$component" "$local_hash" "$remote_hash" "$machine_id" "$remote_machine"

    log_info "Conflict detected for $component (logged to $CONFLICTS_LOG)"
}

# ============================================================================
# Runtime Version Check
# ============================================================================

# Check if runtime versions match
check_runtime_versions() {
    local manifest="$REGISTRY/manifest.json"

    if [ ! -f "$manifest" ]; then
        return 0
    fi

    local required_node=$(jq -r '.runtime.node // "18"' "$manifest" 2>/dev/null)
    local required_python=$(jq -r '.runtime.python // "3.11"' "$manifest" 2>/dev/null)

    # Check Node.js
    if command -v node &>/dev/null; then
        local actual_node=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
        if [ "$actual_node" != "$required_node" ]; then
            log_debug "Warning: Node.js $required_node required, found $actual_node"
        fi
    fi

    # Check Python
    if command -v python3 &>/dev/null; then
        local actual_python=$(python3 --version 2>/dev/null | sed 's/Python //' | cut -d. -f1,2)
        if [ "$actual_python" != "$required_python" ]; then
            log_debug "Warning: Python $required_python required, found $actual_python"
        fi
    fi
}
