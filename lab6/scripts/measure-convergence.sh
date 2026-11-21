#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

START_TIME=$(date +%s)

echo "Starting Ansible convergence measurement..."
echo "Start: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"

cd ansible

ansible-playbook site.yml

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "--------------------------------"
echo "Ansible convergence completed"
echo "Duration: ${DURATION} seconds"
echo "--------------------------------"
