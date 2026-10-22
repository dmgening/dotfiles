# Git workflow

- Never commit directly to main/master. Create a feature branch for the work and commit there; merge or open a PR when done.
- Always merge feature branches with `--no-ff` (never fast-forward into main/master), so each integration is recorded as an explicit merge commit.
- Commit messages: the subject says what changes, the body opens with why.
  - Subject: `<area>: <what changes, as observable behaviour>`, imperative, ≤ 72 chars. No mechanics in the subject. When the branch is linked to a Jira task (`git config branch.<branch>.jira`, or a key in the branch name), prefix the key: `<KEY>: <area>: …`.
  - Body: `Why:` the problem or goal, taken from the task and the conversation, not from the diff. `How:` the key decisions in 1–3 lines, with the identifiers someone would grep for. Optional `Note:` trade-offs, risks, what is deliberately left out.
  - If you can't state the why, ask me instead of paraphrasing the diff.
  - MR descriptions and release notes follow the same order: why, then what, then how.
  - The git `commit-msg` hook (`~/.config/git/hooks`) checks this for your commits: it adds a missing Jira key and drops a session scope like `wip(1a2b3c4d)` itself, and rejects a subject over 72 chars or a body without `Why:`. On a rejection, rewrite the message and commit again; never `--no-verify`.

# Knowledge base

- I keep a Zettelkasten vault at @~/Documents/ZettelkastenVault/. Agents may read from it for additional context when helpful (e.g. domains, projects, people, daily notes). Treat it as read-only reference unless I explicitly ask you to modify it.

# Work

Employer-specific instructions live in the private dotfiles (`~/Projects/dotfiles-private/<company>/`), never in this public repo.

@~/.claude/CLAUDE.work.md
