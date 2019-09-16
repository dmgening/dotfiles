for src in runcoms locals; do
    script="$ZDOTDIR/$src/zshenv.zsh"
    if [[ -f $script ]]; then;
        source $script
    fi
done
