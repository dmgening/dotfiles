#
# functions/ask.fish
#
# A one-shot question to a small local model in LM Studio, for quick shell
# answers without leaving the terminal:
#   ask how to find files over 1 GB
#   cat error.log | ask what is wrong here
#   ask 'what is 17*23'      (quote * and other wildcards)
# The model is loaded at login by ~/.local/bin/lms-autoload (make lmstudio),
# which names the same model; without it lms chat loads the model on the
# first call (~5 s) and LM Studio unloads it after an hour idle. A 4B model
# gets commands wrong now and then: read them before running.
#
# Qwen3.5 thinks before every answer by default, and lms chat --reasoning off
# doesn't stop it for a model downloaded without an LM Studio manifest. In the
# model's chat_template.jinja and in chat_template in tokenizer_config.json,
#   enable_thinking is defined and enable_thinking is false
# is changed to
#   enable_thinking is not defined or enable_thinking is false
# so it answers at once. Redo it if LM Studio downloads the model again.
#

function ask --description 'Ask the small local model in LM Studio'
    set -l lms ~/.lmstudio/bin/lms
    if not test -x $lms
        echo 'ask: LM Studio is not installed (no ~/.lmstudio/bin/lms)' >&2
        return 1
    end
    set -l model qwen3.5-4b-mlx
    set -l system 'Answer briefly, in the language of the question. For shell questions: macOS, fish shell; give the command first, then at most one line of explanation. No markdown headings.'

    set -l prompt (string join ' ' -- $argv)
    # Only a pipe or a file: other non-tty stdins, like a socket a launcher
    # passes on, may never send EOF, and cat would wait forever.
    if test -p /dev/stdin; or test -f /dev/stdin
        set -l input (cat | string collect)
        set prompt "$prompt"\n\n"$input"
    end
    if test -z "$(string trim -- "$prompt")"
        echo 'usage: ask <question>   or   <command> | ask <question>' >&2
        return 1
    end

    # lms chat reads a non-tty stdin too; it has been read above.
    $lms chat $model --dont-fetch-catalog -y -s "$system" -p "$prompt" </dev/null
end
