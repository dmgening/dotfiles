#
# Select editors
#
typeset -ga editors
editors=(emacsclient nvim vim nano)

for editor in "${(@)editors}"; do

    binpath="$(which ${(L)editor})"
    disabled_var="EDITORS_SKIP_${(U)editor}"
    disabled="${(P)disabled_var}"
    #disabled="${(P)$(echo "EDITORS_SKIP_${(U)editor}")}"

    if [[ -f "$binpath" && -z "$disabled" ]]; then
        export EDITOR="$binpath"
        export VISUAL="$EDITOR"
        break
    fi
done

unset editors_config