_make_completion_enhanced() {
  local cur target cache="$HOME/.cache/make-completion-enhanced.cache"
  cur="${COMP_WORDS[COMP_CWORD]}"
  target="${COMP_WORDS[1]}"

  if [[ ! -f "$cache" || Makefile -nt "$cache" ]]; then
    awk '
    BEGIN { tgt="__global__" }
    /^## TARGET / { tgt=$3 }
    /^## PARAM / {
      name=$3; sub(":", "", name)
      vals=""
      for (i=4;i<=NF;i++) if ($i !~ /TYPE=|REQUIRED|DEFAULT=/) vals=vals" "$i
      print name"|"tgt"|"vals
    }' Makefile > "$cache"
  fi

  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "$(awk -F: '/^[a-zA-Z0-9_.-]+:/{print $1}' Makefile)" -- "$cur") )
    return
  fi

  COMPREPLY=( $(awk -F'|' -v t="$target" '
    ($2=="__global__"||$2==t){split($3,v," ");for(i in v)print $1"="v[i]}
  ' "$cache" | compgen -W "$(cat)" -- "$cur") )
}
complete -F _make_completion_enhanced make
