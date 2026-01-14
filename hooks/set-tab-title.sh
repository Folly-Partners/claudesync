#!/bin/bash
# Hook to set terminal tab title based on project name mentioned in prompt
# Matches various patterns and normalizes project names

# Read the user's prompt from stdin
prompt=$(cat)

# Convert prompt to lowercase for matching
prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

# Define projects: "match_pattern|Display Name"
# Match patterns are lowercase, can include multiple aliases separated by |
projects=(
    "deep.?personality|dp|Deep Personality"
    "dealhunter|deal.?hunter|Deal Hunter"
    "superthings|super.?things|things.?mcp|SuperThings"
    "journal|Journal"
    "email.?triage|email|Email Triage"
    "shawnigan.?retreats|shawnigan|retreats|Shawnigan Retreats"
    "overstory|Overstory"
    "sigma|Sigma"
    "metamcp|meta.?mcp|MetaMCP"
    "andrews.?plugin|plugin|Andrews Plugin"
    "deep.?background|background|Deep Background"
    "limitless|limitless.?api|Limitless API"
    "things.?today.?panel|things.?panel|xcode|Things Today Panel"
)

# Function to set terminal tab title
set_tab_title() {
    local title="$1"
    # Set tab title (works for Terminal.app and iTerm2)
    printf '\e]1;%s\a' "$title"
    # Also set window title
    printf '\e]2;%s\a' "$title"
}

# Patterns that indicate project context
# Matches: "In X -", "in X,", "on X:", "for X", "working on X", "X project", etc.
context_patterns=(
    "^[[:space:]]*(in|on|for|at)[[:space:]]+"
    "^[[:space:]]*(working|work)[[:space:]]+(on|in|with)[[:space:]]+"
    "^[[:space:]]*(let'?s?|lets?)[[:space:]]+(work|go|start|continue)[[:space:]]+(on|in|with)?[[:space:]]*"
    "^[[:space:]]*(switch|switching|move|moving)[[:space:]]+(to|over to)[[:space:]]+"
    "^[[:space:]]*(open|opening|load|loading)[[:space:]]+"
    "^[[:space:]]*(back to|return to|returning to)[[:space:]]+"
)

# Check each project
for project_def in "${projects[@]}"; do
    # Split into patterns and display name (last field after |)
    display_name="${project_def##*|}"
    patterns="${project_def%|*}"

    # Convert patterns to regex (replace | with actual OR)
    # Each pattern can match with word boundaries
    IFS='|' read -ra pattern_array <<< "$patterns"

    for pattern in "${pattern_array[@]}"; do
        # Skip if pattern is same as display name (it's the last field)
        [[ "$pattern" == "$display_name" ]] && continue

        # Check with context patterns first (higher confidence)
        for ctx_pattern in "${context_patterns[@]}"; do
            if [[ "$prompt_lower" =~ $ctx_pattern$pattern ]]; then
                set_tab_title "$display_name"
                exit 0
            fi
        done

        # Check for project name followed by delimiter (-, :, ,, .)
        if [[ "$prompt_lower" =~ ^[[:space:]]*$pattern[[:space:]]*[-:,\.] ]] || \
           [[ "$prompt_lower" =~ [[:space:]]$pattern[[:space:]]*[-:,\.] ]]; then
            set_tab_title "$display_name"
            exit 0
        fi

        # Check for "X project" pattern
        if [[ "$prompt_lower" =~ $pattern[[:space:]]+(project|repo|codebase|app) ]]; then
            set_tab_title "$display_name"
            exit 0
        fi
    done
done

# Fallback: Check for generic "In X -" pattern for unlisted projects
if [[ "$prompt" =~ ^[[:space:]]*[Ii]n[[:space:]]+([^-,:]+)[[:space:]]*[-,:] ]]; then
    project_name="${BASH_REMATCH[1]}"
    # Trim whitespace
    project_name=$(echo "$project_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ -n "$project_name" && ${#project_name} -gt 1 && ${#project_name} -lt 50 ]]; then
        set_tab_title "$project_name"
        exit 0
    fi
fi

# Always exit successfully
exit 0
