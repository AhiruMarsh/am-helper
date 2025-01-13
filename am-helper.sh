#!/bin/bash
# am-helper.sh: If update am-helper, run ansible to localhost.
set -e

function info() {
  echo "am-helper: $@"
}

function abort() {
  echo "[FATAL] am-helper: $@" 1>&2
  exit 1
}

# Check changes
git fetch origin main
if git diff --quiet HEAD..origin/main; then
    info "No Updates."
else
    # Sync git remote branch
    info "Update..."
    git pull origin main || abort "Failed to update."

    # Run ansible
    info "Run ansible..."
    cd ansible && ansible-playbook main.yml || abort "Failed to run ansible."

    info "OK"
fi

exit 0
