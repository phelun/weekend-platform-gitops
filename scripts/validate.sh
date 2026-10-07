#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if grep -R --exclude='secret.example.yaml' --exclude='validate.sh' -nE 'weekend-secret-123|stringData:' "$repo_root"; then
  echo "plaintext secret material detected" >&2
  exit 1
fi

kustomize build "$repo_root/infrastructure" >/dev/null
kustomize build "$repo_root/applications" >/dev/null
kustomize build "$repo_root/clusters/weekend-lab" >/dev/null

if command -v yamllint >/dev/null 2>&1; then
  yamllint -d '{extends: default, rules: {line-length: disable, document-start: disable}}' "$repo_root"
fi

echo "GitOps manifests validated"
