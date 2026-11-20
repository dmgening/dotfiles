#
# conf.d/020-prompt.fish
#
# Settings for functions/fish_prompt.fish and fish_right_prompt.fish.
# fish_git_prompt reads its variables once, on first use, so they're set
# here rather than inside the prompt.
#
# git status runs on every prompt. If a huge repo makes it slow, turn the
# dirty check off for that repo only:
#   git config bash.showDirtyState false
#   git config bash.showUntrackedFiles false
#

status is-interactive; or return

# A venv's activate.fish would otherwise wrap fish_prompt with "(name) ".
set -gx VIRTUAL_ENV_DISABLE_PROMPT 1

# Branch, then * for any change (fish_prompt folds staged, unstaged and
# untracked into one), then ⇡/⇣ against the upstream.
set -g __fish_git_prompt_showdirtystate 1
set -g __fish_git_prompt_showuntrackedfiles 1
set -g __fish_git_prompt_showupstream auto
set -g __fish_git_prompt_char_stateseparator ''
set -g __fish_git_prompt_char_dirtystate '*'
set -g __fish_git_prompt_char_stagedstate '*'
set -g __fish_git_prompt_char_untrackedfiles '*'
set -g __fish_git_prompt_char_upstream_ahead ' ⇡'
set -g __fish_git_prompt_char_upstream_behind ' ⇣'
set -g __fish_git_prompt_char_upstream_diverged ' ⇣⇡'
set -g __fish_git_prompt_char_upstream_equal ''
set -g __fish_git_prompt_color_upstream cyan
set -g __fish_git_prompt_color_merging yellow
