#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["anthropic"]
# ///
"""Updates Terminal tab title with project name and task summary using Claude API."""

import json
import os
import subprocess
import sys

import anthropic


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


def get_title_from_prompt(prompt: str) -> str:
    """Use Claude Haiku to generate a terminal tab title."""
    if not ensure_anthropic_key():
        return prompt[:40].split('\n')[0]
    try:
        client = anthropic.Anthropic()
        response = client.messages.create(
            model="claude-haiku-3-5-latest",
            max_tokens=50,
            messages=[{
                "role": "user",
                "content": (
                    "Generate a short terminal tab title (max 40 chars) from this user request. "
                    "Format: 'ProjectName: Task' if a project is mentioned, otherwise just 'Task'. "
                    "Common project names: Deep Personality, Claude Code. "
                    "Output ONLY the title, no quotes or explanation.\n\n"
                    f"{prompt[:500]}"  # Limit input length
                )
            }]
        )
        return response.content[0].text.strip()
    except Exception:
        # Fallback: first 40 chars of prompt
        return prompt[:40].split('\n')[0]


def set_tab_title(title: str):
    """Set macOS Terminal tab title using ANSI escape sequence."""
    # Write to the terminal, not stdout (which Claude captures)
    try:
        with open('/dev/tty', 'w') as tty:
            tty.write(f'\033]1;{title}\007')
            tty.flush()
    except Exception:
        pass  # Silently fail if no TTY


def main():
    # Read hook input from stdin
    try:
        hook_input = json.loads(sys.stdin.read())
    except json.JSONDecodeError:
        return

    # Get user prompt (only present in UserPromptSubmit)
    user_prompt = hook_input.get("user_prompt", "")
    hook_event = hook_input.get("hook_event_name", "")

    if hook_event == "SessionStart":
        set_tab_title("Claude Code")
    elif user_prompt:
        title = get_title_from_prompt(user_prompt)
        set_tab_title(title)


if __name__ == "__main__":
    main()
