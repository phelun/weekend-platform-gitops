#!/usr/bin/env bash
set -euo pipefail

pid_file="/tmp/weekend-tunnel.pid"
log_file="/tmp/weekend-tunnel.log"
kubectl_bin="${KUBECTL_BIN:-kubectl}"

start() {
  if [[ -f "$pid_file" ]] && sudo kill -0 "$(<"$pid_file")" 2>/dev/null; then
    echo "Tunnel already running"
    return
  fi

  sudo -v
  nohup sudo -E "$kubectl_bin" port-forward -n ingress-nginx \
    service/ingress-nginx-controller 80:80 >"$log_file" 2>&1 &
  echo "$!" >"$pid_file"
  echo "App01:  http://app01.weekend.com"
  echo "Grafana: http://mon.weekend.com"
}

stop() {
  if [[ -f "$pid_file" ]]; then
    sudo kill "$(<"$pid_file")" 2>/dev/null || true
    rm -f "$pid_file"
  fi
}

case "${1:-}" in
  start) start ;;
  stop|kill) stop ;;
  restart) stop; start ;;
  status) [[ -f "$pid_file" ]] && sudo kill -0 "$(<"$pid_file")" ;;
  logs) tail -f "$log_file" ;;
  *) echo "Usage: $0 {start|stop|restart|status|logs}" >&2; exit 2 ;;
esac
