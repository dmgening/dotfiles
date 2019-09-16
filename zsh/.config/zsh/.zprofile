for src in runcoms locals; do
    script="$ZDOTDIR/$src/zprofile.zsh"
    if [[ -f $script ]]; then;
        source $script
    fi
done
