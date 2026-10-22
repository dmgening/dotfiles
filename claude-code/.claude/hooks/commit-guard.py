#!/usr/bin/env python3
"""PreToolUse Bash: don't let Claude skip the git commit-msg hook (~/.config/git/hooks).

Denies `git commit/merge … --no-verify` (or `git commit -n`) and `git -c core.hooksPath=…`.
On a command it cannot parse it lets the call through.
"""
import json
import re
import shlex
import sys

REASON = ("Don't bypass git hooks: the commit-msg hook enforces the commit format from "
          "~/.claude/CLAUDE.md (\"Commit messages\"). Drop --no-verify / the core.hooksPath override "
          "and fix the message instead. If the user explicitly asked to skip hooks, ask them to run it.")


def bypasses(tokens):
    for i, t in enumerate(tokens):
        if t != "git":
            continue
        args = tokens[i + 1:]
        # git -c core.hooksPath=... <cmd>
        if any(a.startswith("core.hooksPath=") or a.startswith("core.hookspath=") for a in args[:6]):
            return True
        j = 0
        while j < len(args) and args[j].startswith("-"):
            j += 2 if args[j] in ("-C", "-c", "--git-dir", "--work-tree", "--namespace") else 1
        sub = args[j] if j < len(args) else ""
        rest = args[j + 1:]
        if sub in ("commit", "merge", "cherry-pick", "revert", "am", "rebase"):
            if "--no-verify" in rest:
                return True
            if sub == "commit" and any(re.fullmatch(r"-[a-zA-Z]*n[a-zA-Z]*", a) and "m" not in a[:a.index("n")] for a in rest):
                return True
    return False


def main():
    try:
        payload = json.load(sys.stdin)
        cmd = (payload.get("tool_input") or {}).get("command", "")
        if "git" not in cmd or ("--no-verify" not in cmd and "hooksPath" not in cmd.replace("hookspath", "hooksPath")
                                and not re.search(r"\scommit\b.*\s-[a-zA-Z]*n", cmd)):
            return
        tokens = shlex.split(re.sub(r"[;&|]+", " ; ", cmd), comments=True)
        tokens = ["git" if t.endswith("/git") else t for t in tokens]
        if bypasses(tokens):
            print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                                     "permissionDecision": "deny",
                                                     "permissionDecisionReason": REASON}}))
    except Exception as e:
        print(f"commit-guard: {e}", file=sys.stderr)


if __name__ == "__main__":
    main()
