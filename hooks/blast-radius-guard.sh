#!/bin/bash
# PreToolUse hook for Bash: blast radius guardrails
# Blocks dangerous commands, forces confirmation on risky ones, adds safe flags where possible

# Read the tool input from stdin
INPUT=$(cat)

# Extract the command from the JSON input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# If no command, allow (shouldn't happen)
if [ -z "$COMMAND" ]; then
    echo '{"permissionDecision": "allow"}'
    exit 0
fi

# ============================================================================
# DENY OUTRIGHT - These commands are too dangerous to ever run
# ============================================================================

# Fork bomb detection
if echo "$COMMAND" | grep -qE ':\(\)\s*\{\s*:\|:&\s*\}\s*;:'; then
    echo '{"permissionDecision": "deny", "reason": "Fork bomb detected - this would crash your system"}'
    exit 0
fi

# Destructive rm patterns (beyond what's already in deny list)
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*[rf][a-zA-Z]*\s+)*(/|~|\$HOME|\*|\.\./)'; then
    echo '{"permissionDecision": "deny", "reason": "Dangerous rm pattern targeting root, home, or parent directories"}'
    exit 0
fi

# mkfs without confirmation (wipes filesystems)
if echo "$COMMAND" | grep -qE '^mkfs'; then
    echo '{"permissionDecision": "deny", "reason": "mkfs would wipe a filesystem - too dangerous for automated execution"}'
    exit 0
fi

# dd without safety (can overwrite disks)
if echo "$COMMAND" | grep -qE '^dd\s'; then
    echo '{"permissionDecision": "deny", "reason": "dd can overwrite disks - too dangerous for automated execution"}'
    exit 0
fi

# chmod -R 777 (security nightmare)
if echo "$COMMAND" | grep -qE 'chmod\s+(-[a-zA-Z]*R[a-zA-Z]*\s+)*777'; then
    echo '{"permissionDecision": "deny", "reason": "chmod -R 777 is a security vulnerability - never do this"}'
    exit 0
fi

# Curl piped to shell (arbitrary code execution)
if echo "$COMMAND" | grep -qE 'curl\s.*\|\s*(ba)?sh|wget\s.*\|\s*(ba)?sh'; then
    echo '{"permissionDecision": "deny", "reason": "Piping curl/wget to shell executes arbitrary code - download and inspect first"}'
    exit 0
fi

# History destruction
if echo "$COMMAND" | grep -qE 'history\s+-c|>\s*~/\..*history|rm\s+.*\..*history'; then
    echo '{"permissionDecision": "deny", "reason": "Refusing to destroy shell history"}'
    exit 0
fi

# ============================================================================
# FORCE CONFIRMATION - Risky commands that need human approval
# ============================================================================

# Production environment detection
if echo "$COMMAND" | grep -qiE '(prod|production)'; then
    echo '{"permissionDecision": "ask", "reason": "Command appears to target production environment"}'
    exit 0
fi

# Terraform apply/destroy
if echo "$COMMAND" | grep -qE 'terraform\s+(apply|destroy)'; then
    # Check if --auto-approve is present (even riskier)
    if echo "$COMMAND" | grep -qE '\-\-auto-approve'; then
        echo '{"permissionDecision": "deny", "reason": "terraform with --auto-approve is too risky for automated execution"}'
    else
        echo '{"permissionDecision": "ask", "reason": "Terraform apply/destroy modifies infrastructure"}'
    fi
    exit 0
fi

# kubectl delete (especially namespaces, deployments, etc.)
if echo "$COMMAND" | grep -qE 'kubectl\s+delete'; then
    echo '{"permissionDecision": "ask", "reason": "kubectl delete removes Kubernetes resources"}'
    exit 0
fi

# kubectl apply to kube-system or other critical namespaces
if echo "$COMMAND" | grep -qE 'kubectl\s+.*(-n|--namespace)\s*(kube-system|kube-public|default)'; then
    echo '{"permissionDecision": "ask", "reason": "Command targets critical Kubernetes namespace"}'
    exit 0
fi

# Docker system prune
if echo "$COMMAND" | grep -qE 'docker\s+(system\s+)?prune'; then
    echo '{"permissionDecision": "ask", "reason": "docker prune removes unused data"}'
    exit 0
fi

# Git push --force
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(\-f|\-\-force)'; then
    echo '{"permissionDecision": "ask", "reason": "Force push can overwrite remote history"}'
    exit 0
fi

# Git reset --hard
if echo "$COMMAND" | grep -qE 'git\s+reset\s+.*\-\-hard'; then
    echo '{"permissionDecision": "ask", "reason": "git reset --hard discards uncommitted changes"}'
    exit 0
fi

# Database drops
if echo "$COMMAND" | grep -qiE 'drop\s+(database|table|schema)|truncate\s+table'; then
    echo '{"permissionDecision": "ask", "reason": "Command would destroy database objects"}'
    exit 0
fi

# npm/yarn publish
if echo "$COMMAND" | grep -qE '(npm|yarn|pnpm)\s+publish'; then
    echo '{"permissionDecision": "ask", "reason": "Publishing packages is irreversible"}'
    exit 0
fi

# AWS destructive operations
if echo "$COMMAND" | grep -qE 'aws\s+.*(delete|terminate|remove|destroy)'; then
    echo '{"permissionDecision": "ask", "reason": "AWS destructive operation detected"}'
    exit 0
fi

# Heroku production
if echo "$COMMAND" | grep -qE 'heroku\s+.*\-\-app.*prod'; then
    echo '{"permissionDecision": "ask", "reason": "Heroku command targeting production app"}'
    exit 0
fi

# ============================================================================
# AUTO-REWRITE - Add safe flags where applicable
# ============================================================================

# Add --dry-run to rsync if not present
if echo "$COMMAND" | grep -qE '^rsync\s' && ! echo "$COMMAND" | grep -qE '\-\-dry-run|\-n\s'; then
    SAFE_CMD=$(echo "$COMMAND" | sed 's/^rsync /rsync --dry-run /')
    echo "{\"permissionDecision\": \"allow\", \"reason\": \"Added --dry-run to rsync for safety\", \"hookSpecificOutput\": {\"for PreToolUse\": {\"hookEventName\": \"PreToolUse\", \"updatedInput\": {\"command\": \"$SAFE_CMD\"}}}}"
    exit 0
fi

# Add --dry-run to rm if it looks like a batch delete and not already present
if echo "$COMMAND" | grep -qE 'rm\s+.*(\*|find)' && ! echo "$COMMAND" | grep -qE '\-\-dry-run|\-i\s'; then
    echo '{"permissionDecision": "ask", "reason": "Batch rm operation - consider using -i (interactive) flag"}'
    exit 0
fi

# ============================================================================
# DEFAULT - Allow everything else
# ============================================================================

echo '{"permissionDecision": "allow"}'
