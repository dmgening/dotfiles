zmodload zsh/zprof

for src in runcoms locals; do
    script="$ZDOTDIR/$src/zshrc.zsh"
    if [[ -f $script ]]; then;
        source $script
    fi
done

[[ -n "$ZSHRC_PROFILER" ]] && zprof