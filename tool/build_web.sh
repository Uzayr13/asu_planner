#!/bin/zsh
# Canonical release build for the web target.
#
# Run from the repo root:  zsh tool/build_web.sh
#
# The --no-web-resources-cdn flag is load-bearing, not cosmetic. By default
# Flutter fetches CanvasKit (the web renderer) from www.gstatic.com at runtime.
# Where that host is unreachable the app renders nothing at all — a blank page,
# not a degraded one. With the flag the renderer is served from the build
# output and the app makes zero external requests.
#
# Verified by blocking every non-local request in a headless browser: with the
# flag the app renders and touches no external host; without it the page is
# blank when gstatic is blocked.
set -e

cd "$(dirname "$0")/.."

if [ -n "$JAVA_HOME" ] || java -version >/dev/null 2>&1; then
  :
else
  echo "warning: no usable java on PATH; set JAVA_HOME to an arm64 JDK 17+" >&2
fi

BASE_HREF="${1:-/asu_planner/}"

flutter build web --release --no-web-resources-cdn --base-href "$BASE_HREF"

echo
echo "Built build/web — self-contained, zero external requests."
echo "Serve it with:  python3 -m http.server 8080 --directory build/web"
