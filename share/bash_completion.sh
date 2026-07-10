_cds()
{
    local cur opt
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    dir_nicknames=$HOME/.local/share/cds/dir_nicknames
    names=$(awk -F, '{printf "%s ", $1}' $dir_nicknames 2>&1) && : || names=""
    if [[ $COMP_CWORD == 1 ]]; then
    COMPREPLY=( $(compgen -W "add del help $names" -- "$cur" ) )
    return 0
    fi
}

complete -F _cds cds
