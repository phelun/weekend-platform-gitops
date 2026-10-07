#!/usr/bin/env bash
set -euo pipefail

pid_file="/tmp/weekend-production-tunnel.pid"
log_file="/tmp/weekend-production-tunnel.log"
local_port="${PRODUCTION_INGRESS_PORT:-8081}"

find_kubectl() {
  if [[ -n "${KUBECTL_BIN:-}" ]]; then
    printf '%s\n' "$KUBECTL_BIN"
  elif command -v kubectl >/dev/null 2>&1; then
    command -v kubectl
  elif [[ -x /Users/fmbah/.local/share/containers/podman-desktop/extensions-storage/podman-desktop.kubectl-cli/bin/kubectl ]]; then
    printf '%s\n' /Users/fmbah/.local/share/containers/podman-desktop/extensions-storage/podman-desktop.kubectl-cli/bin/kubectl
  else
    echo "kubectl not found; set KUBECTL_BIN" >&2
    exit 1
  fi
}

start() {
  if [[ -f "$pid_file" ]] && kill -0 "$(<"$pid_file")" 2>/dev/null; then
    echo "Production ingress tunnel already running on port $local_port"
    return
  fi

  kubectl_bin="$(find_kubectl)"
  nohup "$kubectl_bin" --context kind-weekend-production \
    port-forward -n ingress-nginx service/ingress-nginx-controller \
    "$local_port:80" >"$log_file" 2>&1 &
  pid="$!"
  printf '%s\n' "$pid" >"$pid_file"
  sleep 2

  if ! kill -0 "$pid" 2>/dev/null; then
    cat "$log_file" >&2
    rm -f "$pid_file"
    exit 1
  fi

  echo "Production App01: http://app01.prod.weekend.com:$local_port"
}

stop() {
  if [[ -f "$pid_file" ]]; then
    kill "$(<"$pid_file")" 2>/dev/null || true
    rm -f "$pid_file"
  fi
}

case "${1:-}" in
  start) start ;;
  stop|kill) stop ;;
  restart) stop; start ;;
  status) [[ -f "$pid_file" ]] && kill -0 "$(<"$pid_file")" ;;
  logs) tail -f "$log_file" ;;
  *) echo "Usage: $0 {start|stop|restart|status|logs}" >&2; exit 2 ;;
esac
