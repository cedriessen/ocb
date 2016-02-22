# Bash completion for OCB

# By convention, the function name starts with an underscore.
_ocb_complete ()
{
  # Pointer to current completion word.
  # By convention, it's named "cur" but this isn't strictly necessary.
  local cur

  # Array variable storing the possible completions.
  COMPREPLY=()
  cur=${COMP_WORDS[COMP_CWORD]}

  case "$cur" in
    -*)
    opts=$(ocb --bash-complete)
    COMPREPLY=( $( compgen -W "$opts" -- $cur ) );;
    *)
    modules=$(find modules -type d -mindepth 1 -maxdepth 1 2>/dev/null)
    COMPREPLY=( $( compgen -W "$modules" -- $cur ) );;

#   Generate the completion matches and load them into $COMPREPLY array.
#   xx) May add more cases here.
#   yy)
#   zz)
  esac

  return 0
}
complete -F _ocb_complete ocb
