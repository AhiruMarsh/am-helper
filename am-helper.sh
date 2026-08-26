#!/bin/bash
# am-helper.sh: If update am-helper, run ansible to localhost.
set -euo pipefail

function info() {
  echo "am-helper: $*"
}

function abort() {
  echo "[FATAL] am-helper: $*" 1>&2
  exit 1
}

# Parse command-line arguments and set the following global variables:
#   force_update  - "true" to always reset/run ansible, skipping the diff check
#   target_branch - remote branch to compare against and reset to (default: main)
function parse_args() {
  force_update=false
  target_branch="main"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force)
        force_update=true
        shift
        ;;
      --target)
        # --target requires a following branch name argument.
        [[ $# -ge 2 ]] || abort "--target requires a value."
        target_branch="$2"
        shift 2
        ;;
      *)
        abort "Unknown argument: $1"
        ;;
    esac
  done
}

function main() {
  parse_args "$@"

  # Check changes
  git fetch --quiet origin "${target_branch}" || abort "Failed to fetch from ${target_branch}. This may be a temporary GitHub outage, please retry later."
  # With --force, always update regardless of whether origin has diverged.
  if [[ "${force_update}" != true ]] && git diff --quiet "HEAD..origin/${target_branch}"; then
    info "No Updates."
  else
    # Sync git remote branch
    info "Updating..."
    git reset --hard "origin/${target_branch}" || abort "Failed to update."

    # Run ansible
    info "Running ansible playbook..."
    ansible-playbook ansible/main.yml -i localhost, --connection=local --become --diff || abort "Failed to run ansible playbook."

    info "OK"
  fi
}

main "$@"
