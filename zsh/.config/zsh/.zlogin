for src in runcoms locals; do
    script="$ZDOTDIR/$src/zlogin.zsh"
    if [[ -f $script ]]; then;
        source $script
    fi
done
