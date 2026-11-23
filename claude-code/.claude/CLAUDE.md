# Git workflow

- Never commit directly to main/master. Create a feature branch for the work and commit there; merge or open a PR when done.
- Always merge feature branches with `--no-ff` (never fast-forward into main/master), so each integration is recorded as an explicit merge commit.
- Commit messages: the subject says what changes, the body opens with why.
  - Subject: `<area>: <what changes, as observable behaviour>`, imperative, ≤ 72 chars. No mechanics in the subject. When the branch is linked to a Jira task (`git config branch.<branch>.jira`, or a key in the branch name), prefix the key: `<KEY>: <area>: …`.
  - Body: `Why:` the problem or goal, taken from the task and the conversation, not from the diff. `How:` the key decisions in 1–3 lines, with the identifiers someone would grep for. Optional `Note:` trade-offs, risks, what is deliberately left out.
  - If you can't state the why, ask me instead of paraphrasing the diff.
  - MR descriptions and release notes follow the same order: why, then what, then how.
  - The git `commit-msg` hook (`~/.config/git/hooks`) checks this for your commits: it adds a missing Jira key and drops a session scope like `wip(1a2b3c4d)` itself, and rejects a subject over 72 chars or a body without `Why:`. On a rejection, rewrite the message and commit again; never `--no-verify`.

# Project tooling

- A project's tools and dev dependencies (runtimes, CLIs, linters, formatters, code generators) come from mise. Not Homebrew, `go install`, `npm i -g`, `pip install`, `curl | sh`, or nvm/pyenv/gvm.
- Where the pin goes depends on whether the repo uses mise:
  - The repo has a `mise.toml` or `.tool-versions`, or it is one of my personal repos (`~/Projects/personal/`): run `mise use <tool>@<version>` from the project root and commit the file it changes.
  - Otherwise: `mise use --env local <tool>@<version>`, which writes `mise.local.toml`. My global gitignore covers it; never commit it or add any other mise file to the repo.
- Pin a concrete version, not `latest`. Never put project tools in the global config (`mise use -g`).
- A tool missing from the mise registry goes through a backend: `go:`, `npm:`, `pipx:`, `cargo:`, `ubi:`.
- Libraries the code imports stay with the language's package manager (`go.mod`, `package.json`, `pyproject.toml`); mise is for the tools that build, check and run the code.
- If a tool is missing or runs at the wrong version, run `mise install` or `mise exec -- <cmd>` instead of installing it another way.

# Knowledge base

- My knowledge bases live in `~/Vaults/`, one vault per context: each employer, personal life, freelance, and so on. When you lack information (domains, projects, people, decisions, daily notes), look in the vault for the current context before guessing or asking me.
- Each vault has an `AGENTS.md` at its root with its layout and rules for reading and writing. Read it before you work in that vault and follow it.
- You may write to a vault without asking me, within what its `AGENTS.md` allows. Pick the vault from the conversation's context: the repo, company or client we are working on. If it is unclear which one, ask.
- Never mix contexts: a note about one company, client or my personal life never goes into another context's vault, and facts from one context's vault never end up in work for another.

# Work

Employer-specific instructions live in the private dotfiles (`~/Projects/dotfiles-private/<company>/`), never in this public repo.

@~/.claude/CLAUDE.work.md
