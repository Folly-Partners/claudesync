#!/bin/bash
# Build servers after pulling from registry
# Handles npm install, pip install with rollback on failure

# ============================================================================
# Build Detection
# ============================================================================

# Detect build type for a server directory
detect_build_type() {
    local server_dir="$1"

    if [ -f "$server_dir/package.json" ]; then
        echo "node"
    elif [ -f "$server_dir/requirements.txt" ]; then
        echo "python"
    elif [ -f "$server_dir/Cargo.toml" ]; then
        echo "rust"
    elif [ -f "$server_dir/go.mod" ]; then
        echo "go"
    else
        echo "none"
    fi
}

# Get build command for a server from manifest
get_build_cmd() {
    local server_name="$1"

    if [ -f "$REGISTRY/manifest.json" ]; then
        local cmd=$(jq -r ".components.servers[\"$server_name\"].build_cmd // empty" "$REGISTRY/manifest.json" 2>/dev/null)
        if [ -n "$cmd" ]; then
            echo "$cmd"
            return
        fi
    fi

    # Default build commands based on type
    local server_dir="$PLUGIN_DIR/servers/$server_name"
    local build_type=$(detect_build_type "$server_dir")

    case "$build_type" in
        node)
            echo "npm install && npm run build"
            ;;
        python)
            echo "python3 -m venv venv && ./venv/bin/pip install -r requirements.txt"
            ;;
        rust)
            echo "cargo build --release"
            ;;
        go)
            echo "go build"
            ;;
        *)
            echo ""
            ;;
    esac
}

# ============================================================================
# Build Functions
# ============================================================================

# Build a Node.js server
build_node_server() {
    local server_dir="$1"
    local log_file="$2"

    (
        cd "$server_dir"

        # Check if we should use npm or bun
        if command -v bun &>/dev/null && [ -f "bun.lockb" ]; then
            echo "Installing dependencies with bun..."
            bun install

            if [ -f "package.json" ] && jq -e '.scripts.build' package.json > /dev/null 2>&1; then
                echo "Building with bun..."
                bun run build
            fi
        else
            echo "Installing dependencies with npm..."
            npm install

            if [ -f "package.json" ] && jq -e '.scripts.build' package.json > /dev/null 2>&1; then
                echo "Building with npm..."
                npm run build
            fi
        fi
    ) >> "$log_file" 2>&1
}

# Build a Python server
build_python_server() {
    local server_dir="$1"
    local log_file="$2"

    (
        cd "$server_dir"

        # Create or update venv
        if [ ! -d "venv" ]; then
            echo "Creating Python virtual environment..."
            python3 -m venv venv
        fi

        echo "Installing Python dependencies..."
        ./venv/bin/pip install --upgrade pip
        ./venv/bin/pip install -r requirements.txt
    ) >> "$log_file" 2>&1
}

# Build a Rust server
build_rust_server() {
    local server_dir="$1"
    local log_file="$2"

    (
        cd "$server_dir"
        echo "Building Rust server..."
        cargo build --release
    ) >> "$log_file" 2>&1
}

# Build a Go server
build_go_server() {
    local server_dir="$1"
    local log_file="$2"

    (
        cd "$server_dir"
        echo "Building Go server..."
        go build
    ) >> "$log_file" 2>&1
}

# ============================================================================
# Safe Build with Rollback
# ============================================================================

# Build a server safely with rollback on failure
build_server_safe() {
    local server_name="$1"

    local server_dir="$PLUGIN_DIR/servers/$server_name"
    local log_file="$BUILD_LOG"
    local build_type=$(detect_build_type "$server_dir")

    # Log build start
    echo "" >> "$log_file"
    echo "========================================" >> "$log_file"
    echo "Building: $server_name" >> "$log_file"
    echo "Type: $build_type" >> "$log_file"
    echo "Time: $(date)" >> "$log_file"
    echo "========================================" >> "$log_file"

    if [ "$build_type" = "none" ]; then
        echo "No build required for $server_name" >> "$log_file"
        return 0
    fi

    # Backup existing dependencies
    local backup_node_modules=""
    local backup_venv=""
    local backup_dist=""

    if [ -d "$server_dir/node_modules" ]; then
        backup_node_modules=$(mktemp -d)
        cp -r "$server_dir/node_modules" "$backup_node_modules/"
    fi

    if [ -d "$server_dir/venv" ]; then
        backup_venv=$(mktemp -d)
        cp -r "$server_dir/venv" "$backup_venv/"
    fi

    if [ -d "$server_dir/dist" ]; then
        backup_dist=$(mktemp -d)
        cp -r "$server_dir/dist" "$backup_dist/"
    fi

    # Attempt build
    local build_result=0

    case "$build_type" in
        node)
            if ! build_node_server "$server_dir" "$log_file"; then
                build_result=1
            fi
            ;;
        python)
            if ! build_python_server "$server_dir" "$log_file"; then
                build_result=1
            fi
            ;;
        rust)
            if ! build_rust_server "$server_dir" "$log_file"; then
                build_result=1
            fi
            ;;
        go)
            if ! build_go_server "$server_dir" "$log_file"; then
                build_result=1
            fi
            ;;
    esac

    if [ $build_result -ne 0 ]; then
        echo "BUILD FAILED - Restoring backup" >> "$log_file"

        # Restore backups
        if [ -n "$backup_node_modules" ] && [ -d "$backup_node_modules/node_modules" ]; then
            rm -rf "$server_dir/node_modules"
            mv "$backup_node_modules/node_modules" "$server_dir/"
        fi

        if [ -n "$backup_venv" ] && [ -d "$backup_venv/venv" ]; then
            rm -rf "$server_dir/venv"
            mv "$backup_venv/venv" "$server_dir/"
        fi

        if [ -n "$backup_dist" ] && [ -d "$backup_dist/dist" ]; then
            rm -rf "$server_dir/dist"
            mv "$backup_dist/dist" "$server_dir/"
        fi

        # Cleanup temp dirs
        [ -n "$backup_node_modules" ] && rm -rf "$backup_node_modules"
        [ -n "$backup_venv" ] && rm -rf "$backup_venv"
        [ -n "$backup_dist" ] && rm -rf "$backup_dist"

        return 1
    fi

    echo "BUILD SUCCEEDED" >> "$log_file"

    # Cleanup backups on success
    [ -n "$backup_node_modules" ] && rm -rf "$backup_node_modules"
    [ -n "$backup_venv" ] && rm -rf "$backup_venv"
    [ -n "$backup_dist" ] && rm -rf "$backup_dist"

    return 0
}

# Check if a server needs rebuild
needs_rebuild() {
    local server_name="$1"

    local server_dir="$PLUGIN_DIR/servers/$server_name"
    local build_type=$(detect_build_type "$server_dir")

    case "$build_type" in
        node)
            # Needs rebuild if node_modules doesn't exist
            [ ! -d "$server_dir/node_modules" ]
            ;;
        python)
            # Needs rebuild if venv doesn't exist
            [ ! -d "$server_dir/venv" ]
            ;;
        rust)
            # Needs rebuild if target/release doesn't exist
            [ ! -d "$server_dir/target/release" ]
            ;;
        go)
            # Go servers usually need rebuild
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Build if needed (check if dependencies exist)
build_if_needed() {
    local plugin_dir="$1"
    local component="$2"

    # Only applies to servers
    if [[ "$component" != servers/* ]]; then
        return 0
    fi

    local server_name="${component#servers/}"

    if needs_rebuild "$server_name"; then
        build_server_safe "$server_name"
    fi
}
