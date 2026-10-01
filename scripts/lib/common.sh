#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${RAP_REPO_ROOT:-$(cd -- "$SCRIPT_DIR/../.." && pwd)}"
export REPO_ROOT

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

git_at() {
  if [[ -n "${RAP_GIT_DIR:-}" ]]; then
    git --git-dir="$RAP_GIT_DIR" --work-tree="$REPO_ROOT" "$@"
  else
    git -C "$REPO_ROOT" "$@"
  fi
}

require_git_repo() {
  git_at rev-parse --git-dir >/dev/null 2>&1 \
    || die "${REPO_ROOT} is not a Git worktree"
}

phase_manifest() {
  local phase="$1"
  printf '%s/.agent/execution/phase-%s.yaml\n' "$REPO_ROOT" "$phase"
}

yaml_scalar() {
  local manifest="$1"
  local section="$2"
  local key="$3"

  awk -v wanted_section="$section" -v wanted_key="$key" '
    function clean(value) {
      sub(/[[:space:]]+#.*/, "", value)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (value ~ /^".*"$/) {
        sub(/^"/, "", value)
        sub(/"$/, "", value)
      }
      if (value ~ /^\047.*\047$/) {
        sub(/^\047/, "", value)
        sub(/\047$/, "", value)
      }
      return value
    }

    BEGIN { in_section = (wanted_section == "") }

    {
      if (wanted_section != "" && $0 ~ ("^" wanted_section ":[[:space:]]*$")) {
        in_section = 1
        next
      }

      if (wanted_section != "" && $0 ~ "^[^[:space:]]") {
        in_section = 0
      }

      if (in_section && wanted_section == "" && $0 ~ ("^" wanted_key ":[[:space:]]*")) {
        sub(("^" wanted_key ":[[:space:]]*"), "", $0)
        print clean($0)
        exit
      }

      if (in_section && wanted_section != "" && $0 ~ ("^[[:space:]]+" wanted_key ":[[:space:]]*")) {
        sub(("^[[:space:]]+" wanted_key ":[[:space:]]*"), "", $0)
        print clean($0)
        exit
      }
    }
  ' "$manifest"
}

normalize_remote() {
  local value="${1%.git}"
  value="${value#ssh://}"
  value="${value#https://}"
  value="${value#http://}"
  value="${value#git@}"
  value="${value#github.com:}"
  value="${value#github.com/}"
  printf '%s\n' "$value"
}

require_safe_component() {
  local label="$1"
  local value="$2"
  [[ "$value" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] \
    || die "$label must contain only letters, numbers, '.', '_' or '-': $value"
  [[ "$value" != ".." && "$value" != "." ]] \
    || die "$label cannot be '.' or '..'"
}

manifest_value_required() {
  local label="$1"
  local value="$2"
  [[ -n "$value" ]] || die "execution manifest is missing ${label}"
  [[ "$value" != *"<"* && "$value" != *">"* && "$value" != "NN" ]] \
    || die "execution manifest contains a template placeholder for ${label}"
}
