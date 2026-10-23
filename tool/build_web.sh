#!/bin/sh
# Canonical release build for the web target.
#
# Run from the repo root:  sh tool/build_web.sh
#
# POSIX sh on purpose — GitHub's ubuntu runners have no zsh.
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

# Trim what no browser can fetch. CanvasKit ships several renderer variants
# and which one is used depends on the browser — Safari takes canvaskit/,
# Chrome takes chromium/ or webparagraph/ — so those must stay or the app
# breaks for half the audience. skwasm and wimp are reachable only from a
# --wasm build and we compile dart2js; *.js.symbols are devtools-only.
# Roughly halves the deploy (43MB -> 23MB) without touching what a phone
# actually downloads.
find build/web -name '*.js.symbols' -delete
rm -f build/web/canvaskit/skwasm*.js build/web/canvaskit/skwasm*.wasm
rm -f build/web/canvaskit/wimp*.js build/web/canvaskit/wimp*.wasm

echo
echo "Built build/web — self-contained, zero external requests."
du -sh build/web
echo "Serve it with:  python3 -m http.server 8080 --directory build/web"
