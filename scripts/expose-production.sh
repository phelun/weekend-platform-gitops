#!/usr/bin/env bash
set -euo pipefail

local_port="${PRODUCTION_INGRESS_PORT:-8081}"

cat <<EOF
Production ingress is mapped directly by Kind; no tunnel is required.

App01: http://app01.prod.weekend.com:${local_port}

Test without changing /etc/hosts:
  curl --resolve app01.prod.weekend.com:${local_port}:127.0.0.1 \\
    http://app01.prod.weekend.com:${local_port}/
EOF
