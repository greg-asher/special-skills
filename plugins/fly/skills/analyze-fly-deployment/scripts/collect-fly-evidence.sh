#!/usr/bin/env bash

set -o pipefail

usage() {
  printf '%s\n' \
    'Collect read-only Fly.io evidence for explicit apps or an organization.' \
    '' \
    'Usage:' \
    '  collect-fly-evidence.sh --output DIR [--org ORG] [--app APP ...] [--dry-run]' \
    '' \
    'Options:' \
    '  --output DIR       Required evidence directory.' \
    '  --org ORG          Explicit Fly organization. With no --app, discover all org apps.' \
    '  --app APP          Explicit app; repeat for multiple apps.' \
    '  --no-managed       Skip MPG, Redis, and Tigris organization inventory.' \
    '  --dry-run          Write and print the command plan without calling Fly.' \
    '  -h, --help         Show this help.' \
    '' \
    'Safety:' \
    '  Commands are read-only, but collected configuration may contain internal metadata.' \
    '  Protect the evidence directory and sanitize any report derived from it.' \
    '' \
    'Environment:' \
    '  FLY_BIN            Fly CLI executable (default: fly).'
}

fly_bin="${FLY_BIN:-fly}"
output_dir=''
org=''
dry_run=0
include_managed=1
apps=()

while (($#)); do
  case "$1" in
    --output)
      [[ $# -ge 2 ]] || { printf 'Missing value for --output\n' >&2; exit 2; }
      output_dir="$2"
      shift 2
      ;;
    --org)
      [[ $# -ge 2 ]] || { printf 'Missing value for --org\n' >&2; exit 2; }
      org="$2"
      shift 2
      ;;
    --app)
      [[ $# -ge 2 ]] || { printf 'Missing value for --app\n' >&2; exit 2; }
      apps+=("$2")
      shift 2
      ;;
    --no-managed)
      include_managed=0
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "$output_dir" ]] || { printf 'Required: --output DIR\n' >&2; exit 2; }
if [[ -z "$org" && ${#apps[@]} -eq 0 ]]; then
  printf 'Specify at least one --app or an explicit --org. Ambient app inference is disabled.\n' >&2
  exit 2
fi

valid_name() {
  [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9-]*$ ]]
}

if [[ -n "$org" ]] && ! valid_name "$org"; then
  printf 'Unsafe organization name: %s\n' "$org" >&2
  exit 2
fi
for app in "${apps[@]}"; do
  if ! valid_name "$app"; then
    printf 'Unsafe app name: %s\n' "$app" >&2
    exit 2
  fi
done

mkdir -p "$output_dir/root" "$output_dir/apps" "$output_dir/managed"
plan_file="$output_dir/command-plan.txt"
: > "$plan_file"

quote_command() {
  printf '%q ' "$@"
  printf '\n'
}

capture() {
  local target="$1"
  shift
  local parent
  parent="${target%/*}"
  mkdir -p "$parent"
  quote_command "$@" >> "$plan_file"
  quote_command "$@" > "${target}.command"

  if ((dry_run)); then
    quote_command "$@"
    printf 'dry-run\n' > "${target}.status"
    : > "${target}.stdout"
    : > "${target}.stderr"
    return 0
  fi

  "$@" > "${target}.stdout" 2> "${target}.stderr"
  local status=$?
  printf '%s\n' "$status" > "${target}.status"
  return 0
}

{
  printf 'collected_at_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'organization=%s\n' "$org"
  printf 'dry_run=%s\n' "$dry_run"
  printf 'fly_bin=%s\n' "$fly_bin"
} > "$output_dir/collection-metadata.txt"

capture "$output_dir/root/version" "$fly_bin" version
capture "$output_dir/root/whoami" "$fly_bin" auth whoami

if [[ -n "$org" ]]; then
  capture "$output_dir/root/apps-json" "$fly_bin" apps list --org "$org" --json
  capture "$output_dir/root/apps-quiet" "$fly_bin" apps list --org "$org" --quiet

  if [[ ${#apps[@]} -eq 0 && $dry_run -eq 0 ]]; then
    quiet_status="$(<"$output_dir/root/apps-quiet.status")"
    if [[ "$quiet_status" != '0' ]]; then
      printf 'Could not discover apps for organization %s; inspect root/apps-quiet.stderr.\n' "$org" >&2
      exit 3
    fi
    while IFS= read -r app; do
      [[ -n "$app" ]] || continue
      if valid_name "$app"; then
        apps+=("$app")
      else
        printf 'Skipping unsafe discovered app name: %s\n' "$app" >&2
      fi
    done < "$output_dir/root/apps-quiet.stdout"
  fi
fi

if ((dry_run)) && [[ ${#apps[@]} -eq 0 ]]; then
  printf '# Organization app commands will be expanded after read-only app discovery.\n' >> "$plan_file"
fi

for app in "${apps[@]}"; do
  app_dir="$output_dir/apps/$app"
  mkdir -p "$app_dir"
  capture "$app_dir/status-json" "$fly_bin" status --app "$app" --json
  capture "$app_dir/machines-json" "$fly_bin" machine list --app "$app" --json
  capture "$app_dir/volumes-json" "$fly_bin" volumes list --app "$app" --all --json
  capture "$app_dir/releases-json" "$fly_bin" releases --app "$app" --image --json
  capture "$app_dir/ips" "$fly_bin" ips list --app "$app"
  capture "$app_dir/certificates" "$fly_bin" certs list --app "$app"
  capture "$app_dir/checks" "$fly_bin" checks list --app "$app"
  capture "$app_dir/scale" "$fly_bin" scale show --app "$app"
  capture "$app_dir/config" "$fly_bin" config show --app "$app"
done

if [[ -n "$org" && $include_managed -eq 1 ]]; then
  capture "$output_dir/managed/mpg-json" "$fly_bin" mpg list --org "$org" --json
  capture "$output_dir/managed/redis" "$fly_bin" redis list --org "$org"
  capture "$output_dir/managed/tigris" "$fly_bin" storage list --org "$org"
fi

printf 'Evidence directory: %s\n' "$output_dir"
printf 'Command plan: %s\n' "$plan_file"
if ((dry_run)); then
  printf 'Dry run only; no Fly API queries were executed.\n'
fi
