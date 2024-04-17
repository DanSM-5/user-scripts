#!/usr/bin/env bash

# Script to change shebangs. It will append a new line at the top of a file.
# It doesn't remove previous shebang, it just moves to the next line.
# Ref: https://unix.stackexchange.com/questions/29608/why-is-it-better-to-use-usr-bin-env-name-instead-of-path-to-name-as-my/238470#238470

[[ -v debug ]] && set -x

help () {
  while IFS= read -r line; do
		printf "  %s\n" "$line"
	done <<-EOF

  Change Shebang Script

	Usage:
    ${0##*/} [ interpreter ] [ file1 | file2 | file3 | ... ]
    ${0##*/} [-r|--raw] [ interpreter ] [ file1 | file2 | file3 | ... ]
    ${0##*/} [-h|--help]

	Options:
    -h | --help                   Print this message
    -r | --raw                    Pass next string as literal value for shebang.
                                  For values with spaces e.g. "/usr/bin/env bash" the value should be quoted

EOF
}

POSITIONAL_ARGS=()
interpreter=""
shebang=""

# Args parsing
# Ref: https://stackoverflow.com/a/14203146
while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--raw)
      interpreter="$2"
      shift # past argument
      shift # past value
      ;;
    -h|-help|--help|help)
      help
      exit 0
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# If set, value was passed with -r/--raw
if [ -n "$interpreter" ]; then
  # We don't care if value is executable or valid in the path as it may contain spaces
  shebang="#!$interpreter"
else
  # If not set, take the first argument
  interpreter="$1"
  shift

  if [ -z "$(type -P $interpreter)" ] ; then
    echo "Error: '$interpreter' is not executable." >&2
    exit 1
  fi

  if [ ! -d "$interpreter" ] && [ -x "$interpreter" ] ; then
    shebang='#!'"$(realpath -e $interpreter)" || exit 1
  else
    shebang='#!'"$(type -P $interpreter)"
  fi
fi


for f in "$@" ; do
  printf "%s\n" 1 i "$shebang" . w | ed "$f"
done

