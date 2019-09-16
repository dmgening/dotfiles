for src in runcoms locals; do
    script="$ZDOTDIR/$src/zshrc.zsh"
    if [[ -f $script ]]; then;
        source $script
    fi
done
