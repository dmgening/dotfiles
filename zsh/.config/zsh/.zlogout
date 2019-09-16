for src in runcoms locals; do
    script="$ZDOTDIR/$src/zlogout.zsh"
    if [[ -f $script ]]; then;
        source $script
    fi
done
