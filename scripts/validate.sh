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
kustomize build "$repo_root/environments/production/infrastructure" >/dev/null
kustomize build "$repo_root/environments/production/applications" >/dev/null
kustomize build "$repo_root/clusters/weekend-production" >/dev/null

production_render="$(kustomize build "$repo_root/environments/production/applications")"
for namespace in app01-weekend-com app02-weekend-com app03-weekend-com; do
  if ! grep -q "namespace: $namespace" <<<"$production_render"; then
    echo "production resources missing namespace $namespace" >&2
    exit 1
  fi
done

if command -v yamllint >/dev/null 2>&1; then
  yamllint \
    -d '{extends: default, rules: {line-length: disable, document-start: disable}}' \
    "$repo_root/applications" \
    "$repo_root/infrastructure" \
    "$repo_root/environments/production" \
    "$repo_root/clusters/weekend-lab/kustomization.yaml" \
    "$repo_root/clusters/weekend-lab/applications.yaml" \
    "$repo_root/clusters/weekend-lab/infrastructure.yaml" \
    "$repo_root/clusters/weekend-production/kustomization.yaml" \
    "$repo_root/clusters/weekend-production/applications.yaml" \
    "$repo_root/clusters/weekend-production/infrastructure.yaml"
fi

echo "GitOps manifests validated"
