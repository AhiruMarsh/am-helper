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

function main() {
  # Check changes
  git fetch --quiet origin main
  if git diff --quiet HEAD..origin/main; then
    info "No Updates."
  else
    # Sync git remote branch
    info "Updating..."
    git pull origin main || abort "Failed to update."

    # Run ansible
    info "Running ansible playbook..."
    ansible-playbook ansible/main.yml -i localhost, --connection=local --become --diff || abort "Failed to run ansible playbook."

    info "OK"
  fi
}

main "$@"
