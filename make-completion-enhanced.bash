_make_completion_enhanced() {
  local cur target cache_dir cache
  cache_dir="$HOME/.cache/make-completion-enhanced"
  mkdir -p "$cache_dir"
  cache="$cache_dir/$(pwd | tr '/' '_').cache"
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
    }
    /^## ARGS / {
      pos=$3; sub(":", "", pos)
      vals=""
      for (i=4;i<=NF;i++) vals=vals" "$i
      print "__args_"pos"__|"tgt"|"vals
    }
    /^## OPT / {
      name=$3; sub(":", "", name)
      vals=""
      for (i=4;i<=NF;i++) vals=vals" "$i
      print name"|"tgt"|"vals
    }' Makefile > "$cache"
  fi

  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "$(awk -F: '/^[a-zA-Z0-9_.-]+:/{print $1}' Makefile)" -- "$cur") )
    return
  fi

  if [[ "$cur" == -* ]]; then
    COMPREPLY=( $(awk -F'|' -v t="$target" '
      ($2=="__global__"||$2==t) && $1~/^-/ {
        if ($3!="" && $1~/^--/) { split($3,v," "); for(i in v) print $1"="v[i] }
        print $1
      }
    ' "$cache" | compgen -W "$(cat)" -- "$cur") )
    return
  fi

  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  if [[ "$prev" == -* ]]; then
    local opt_vals
    opt_vals=$(awk -F'|' -v t="$target" -v opt="$prev" '
      ($2=="__global__"||$2==t) && $1==opt && $3!="" { print $3 }
    ' "$cache")
    if [[ -n "$opt_vals" ]]; then
      COMPREPLY=( $(compgen -W "$opt_vals" -- "$cur") )
      return
    fi
  fi

  local pos=$(( COMP_CWORD - 1 ))
  COMPREPLY=( $(awk -F'|' -v t="$target" -v pos="$pos" '
    ($2=="__global__"||$2==t){
      split($3,v," ")
      if ($1=="__args_"pos"__") { for(i in v) print v[i] }
      else if ($1!~/^__args_/ && $1!~/^-/) { for(i in v) print $1"="v[i] }
    }
  ' "$cache" | compgen -W "$(cat)" -- "$cur") )
}
complete -F _make_completion_enhanced make
