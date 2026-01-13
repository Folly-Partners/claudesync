#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["anthropic"]
# ///
"""Sets terminal tab title to project name on first prompt of session."""

import json
import os
import subprocess
import sys

MARKER_DIR = "/tmp/claude-tab-titles"


def ensure_anthropic_key():
    """Ensure ANTHROPIC_API_KEY is set, fetching from deep-env if needed."""
    if os.environ.get("ANTHROPIC_API_KEY"):
        return True
    try:
        result = subprocess.run(
            ["deep-env", "get", "ANTHROPIC_API_KEY"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0 and result.stdout.strip():
            os.environ["ANTHROPIC_API_KEY"] = result.stdout.strip()
            return True
    except Exception:
        pass
    return False


def get_project_name(prompt: str) -> str:
    """Use Claude Haiku to extract project name from prompt."""
    if not ensure_anthropic_key():
        return "Claude Code"
    try:
        import anthropic
        client = anthropic.Anthropic()
        response = client.messages.create(
            model="claude-haiku-3-5-latest",
            max_tokens=30,
            messages=[{
                "role": "user",
                "content": (
                    "Extract the project name from this message. "
                    "Output ONLY the project name (2-4 words max), nothing else. "
                    "If no clear project is mentioned, output 'Claude Code'.\n\n"
                    f"{prompt[:500]}"
                )
            }]
        )
        return response.content[0].text.strip()
    except Exception:
        return "Claude Code"


def set_tab_title(title: str):
    """Set macOS Terminal/iTerm2 tab title using AppleScript."""
    try:
        # Escape single quotes in title
        safe_title = title.replace("'", "'\\''")

        # Try iTerm2 first, fall back to Terminal.app
        script = f'''
        tell application "System Events"
            set frontApp to name of first application process whose frontmost is true
        end tell

        if frontApp is "iTerm2" then
            tell application "iTerm2"
                tell current session of current tab of current window
                    set name to "{safe_title}"
                end tell
            end tell
        else if frontApp is "Terminal" then
            tell application "Terminal"
                set custom title of front window to "{safe_title}"
            end tell
        end if
        '''
        subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            timeout=5
        )
    except Exception:
        pass


def main():
    try:
        hook_input = json.loads(sys.stdin.read())
    except json.JSONDecodeError:
        return

    session_id = hook_input.get("session_id", "")
    if not session_id:
        return

    # Check if already ran this session
    os.makedirs(MARKER_DIR, exist_ok=True)
    marker_file = os.path.join(MARKER_DIR, session_id)
    if os.path.exists(marker_file):
        return  # Already set title for this session

    # Get project name from first prompt
    user_prompt = hook_input.get("user_prompt", "")
    if not user_prompt:
        return

    title = get_project_name(user_prompt)
    set_tab_title(title)

    # Mark as done for this session
    with open(marker_file, 'w') as f:
        f.write(title)


if __name__ == "__main__":
    main()
