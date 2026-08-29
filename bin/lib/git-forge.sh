#!/usr/bin/env bash

# Shared forge metadata and URL helpers for the Bash Git utilities.

GIT_FORGE_BUILTIN_RESOLVERS=(
  'github.com|github|https://github.com'
  'gitlab.com|gitlab|https://gitlab.com'
  'codeberg.org|forgejo|https://codeberg.org'
  'gitea.com|gitea|https://gitea.com'
  'bitbucket.org|bitbucket-cloud|https://bitbucket.org'
)

GIT_FORGE_MATCHED_TYPE=''
GIT_FORGE_MATCHED_ORIGIN=''

git_forge_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

_git_forge_find_in_rules() {
  local candidate="${1,,}" array_name="$2"
  local entry pattern forge origin
  local -n resolver_rules="$array_name"

  for entry in "${resolver_rules[@]}"; do
    IFS='|' read -r pattern forge origin <<< "$entry"
    pattern=$(git_forge_trim "$pattern")
    forge=$(git_forge_trim "$forge")
    origin=$(git_forge_trim "${origin:-}")
    # shellcheck disable=SC2254
    case "$candidate" in
      ${pattern,,})
        GIT_FORGE_MATCHED_TYPE="${forge,,}"
        GIT_FORGE_MATCHED_ORIGIN="${origin%/}"
        return 0
        ;;
    esac
  done
  return 1
}

# Match a hostname against optional custom rule arrays followed by the built-in
# public forge rules. Results are returned in GIT_FORGE_MATCHED_*.
git_forge_find_resolver() {
  local candidate="$1" array_name
  shift
  GIT_FORGE_MATCHED_TYPE=''
  GIT_FORGE_MATCHED_ORIGIN=''

  for array_name in "$@"; do
    _git_forge_find_in_rules "$candidate" "$array_name" && return 0
  done
  _git_forge_find_in_rules "$candidate" GIT_FORGE_BUILTIN_RESOLVERS
}

# Match a hostname, forge name, or configured web origin. Intended for CLI
# options such as --forge, where all three spellings are useful.
git_forge_find_named_resolver() {
  local candidate="${1,,}" entry pattern forge origin
  GIT_FORGE_MATCHED_TYPE=''
  GIT_FORGE_MATCHED_ORIGIN=''

  for entry in "${GIT_FORGE_BUILTIN_RESOLVERS[@]}"; do
    IFS='|' read -r pattern forge origin <<< "$entry"
    pattern=$(git_forge_trim "$pattern")
    forge=$(git_forge_trim "$forge")
    origin=$(git_forge_trim "${origin:-}")
    if [[ $candidate == "${pattern,,}" || $candidate == "${forge,,}" || $candidate == "${origin,,}" ]]; then
      GIT_FORGE_MATCHED_TYPE="${forge,,}"
      GIT_FORGE_MATCHED_ORIGIN="${origin%/}"
      return 0
    fi
  done
  return 1
}

# Match only the named rule array. This is useful when callers need to test
# custom rules separately before applying built-in fallbacks.
git_forge_find_resolver_in() {
  GIT_FORGE_MATCHED_TYPE=''
  GIT_FORGE_MATCHED_ORIGIN=''
  _git_forge_find_in_rules "$1" "$2"
}

# Percent-encode one URL component. LC_ALL=C keeps the loop byte-oriented so
# UTF-8 values are encoded correctly.
git_forge_urlencode_component() {
  local LC_ALL=C value="$1" encoded='' character hex
  local -i index
  for ((index = 0; index < ${#value}; index++)); do
    character="${value:index:1}"
    case "$character" in
      [a-zA-Z0-9.~_-]) encoded+="$character" ;;
      *)
        printf -v hex '%%%02X' "'$character"
        encoded+="$hex"
        ;;
    esac
  done
  printf '%s' "$encoded"
}

# Encode path components while preserving slash separators.
git_forge_urlencode_path() {
  local path="$1" segment result='' separator=''
  local -a segments=()
  local IFS='/'
  read -r -a segments <<< "$path"
  for segment in "${segments[@]}"; do
    result+="$separator$(git_forge_urlencode_component "$segment")"
    separator='/'
  done
  printf '%s' "$result"
}

# Decode percent escapes from a URL path without treating '+' as a space.
git_forge_urldecode_path() {
  local LC_ALL=C value="$1" decoded='' character byte
  local -i index=0 length=${#value}
  while ((index < length)); do
    character="${value:index:1}"
    if [[ $character == '%' ]] && ((index + 2 < length)); then
      byte="${value:index+1:2}"
      if [[ $byte =~ ^[0-9A-Fa-f]{2}$ ]]; then
        printf -v character '%b' "\\x$byte"
        decoded+="$character"
        index=$((index + 3))
        continue
      fi
    fi
    decoded+="$character"
    index=$((index + 1))
  done
  printf '%s' "$decoded"
}

# Build a canonical public raw-file URL. The ref is carried in a query string
# for GitLab and Forgejo/Gitea so refs containing slashes stay unambiguous.
git_forge_raw_file_url() {
  local forge="$1" origin="${2%/}" repository_path="$3" ref="$4" file_path="$5"
  local encoded_repository encoded_ref encoded_file owner repository

  encoded_ref=$(git_forge_urlencode_component "$ref")
  case "$forge" in
    github)
      printf 'https://raw.githubusercontent.com/%s/%s/%s' \
        "$(git_forge_urlencode_path "$repository_path")" \
        "$(git_forge_urlencode_path "$ref")" \
        "$(git_forge_urlencode_path "$file_path")"
      ;;
    gitlab)
      encoded_repository=$(git_forge_urlencode_component "$repository_path")
      encoded_file=$(git_forge_urlencode_component "$file_path")
      printf '%s/api/v4/projects/%s/repository/files/%s/raw?ref=%s' \
        "$origin" "$encoded_repository" "$encoded_file" "$encoded_ref"
      ;;
    forgejo|gitea)
      owner="${repository_path%%/*}"
      repository="${repository_path#*/}"
      [[ -n $owner && -n $repository && $repository != */* ]] || return 2
      printf '%s/api/v1/repos/%s/%s/raw/%s?ref=%s' \
        "$origin" \
        "$(git_forge_urlencode_component "$owner")" \
        "$(git_forge_urlencode_component "$repository")" \
        "$(git_forge_urlencode_path "$file_path")" \
        "$encoded_ref"
      ;;
    *) return 2 ;;
  esac
}
