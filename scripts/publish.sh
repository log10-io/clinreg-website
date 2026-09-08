#!/usr/bin/env bash
#
# Publish a generated leaderboard to https://clinreg.log10.io
#
# Copies the generated HTML (and optional CSV) into site/, commits, and pushes.
# The push triggers .github/workflows/deploy.yml, which deploys site/ to Pages.
#
#   ./scripts/publish.sh output.html
#   ./scripts/publish.sh output.html data.csv
#   ./scripts/publish.sh --snapshot output.html data.csv
#
set -euo pipefail

SITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/site"
SNAPSHOT=false
PUSH=true
MESSAGE=""
ARGS=()

usage() {
  sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  cat <<'USAGE'
Options:
  --snapshot     Also archive under site/runs/<UTC date>/ so this board stays
                 linkable after the next publish overwrites the front page.
  --no-push      Stage and commit only; leaves the push to you.
  -m MESSAGE     Commit message. Defaults to a timestamped one.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --snapshot) SNAPSHOT=true; shift ;;
    --no-push)  PUSH=false; shift ;;
    -m)         MESSAGE="${2:-}"; shift 2 ;;
    -h|--help)  usage; exit 0 ;;
    -*)         echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)          ARGS+=("$1"); shift ;;
  esac
done

if [[ ${#ARGS[@]} -lt 1 || ${#ARGS[@]} -gt 2 ]]; then
  usage >&2
  exit 2
fi

HTML="${ARGS[0]}"
CSV="${ARGS[1]:-}"

[[ -f "$HTML" ]] || { echo "no such file: $HTML" >&2; exit 1; }
[[ -z "$CSV" || -f "$CSV" ]] || { echo "no such file: $CSV" >&2; exit 1; }

cp "$HTML" "$SITE_DIR/index.html"
echo "staged $HTML -> site/index.html"

if [[ -n "$CSV" ]]; then
  cp "$CSV" "$SITE_DIR/data.csv"
  echo "staged $CSV -> site/data.csv"
fi

if [[ "$SNAPSHOT" == true ]]; then
  RUN_DIR="$SITE_DIR/runs/$(date -u +%Y-%m-%d)"
  mkdir -p "$RUN_DIR"
  cp "$HTML" "$RUN_DIR/index.html"
  [[ -n "$CSV" ]] && cp "$CSV" "$RUN_DIR/data.csv"
  echo "archived   -> ${RUN_DIR#"$SITE_DIR/"}/"
fi

cd "$SITE_DIR/.."
git add site

if git diff --cached --quiet -- site; then
  echo "site/ is unchanged; nothing to publish."
  exit 0
fi

git commit -m "${MESSAGE:-Publish leaderboard $(date -u +%Y-%m-%dT%H:%M:%SZ)}" -- site

if [[ "$PUSH" == true ]]; then
  git push
  echo
  echo "pushed. deploy: https://github.com/log10-io/clinreg-website/actions"
  echo "live in ~1 min at https://clinreg.log10.io"
else
  echo
  echo "committed but not pushed (--no-push). run 'git push' to deploy."
fi
