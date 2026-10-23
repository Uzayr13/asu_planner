'use strict';

// Offline-first service worker for Yawmi.
//
// Flutter 3.47's own build emits a service worker whose activate handler
// unregisters itself (see flutter_tools/lib/src/web/file_generators/js/
// flutter_service_worker.js) — it is a stub with no fetch handler, so the app
// was neither installable nor usable offline. This replaces it.
//
// It is registered from web/flutter_bootstrap.js, NOT through Flutter's
// loader: that path is deprecated (flutter/flutter#156910) and, when given
// serviceWorkerSettings at all, it registers its own stub over the top of
// whatever is already there.
//
// Cache identity tracks the build. version.json is emitted by every
// `flutter build web`, so a deploy produces a new cache name and the old
// caches are deleted on activate — returning users never sit on stale code.

const CACHE_PREFIX = 'asu-planner-';

// The app shell. Everything else (assets/, canvaskit/) is cached on first use
// by the fetch handler below, so install is not held up by the ~1.5MB wasm.
const SHELL = [
  './',
  './index.html',
  './main.dart.js',
  './flutter.js',
  './flutter_bootstrap.js',
  './manifest.json',
  './favicon.png',
  './version.json',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './icons/Icon-maskable-192.png',
  './icons/Icon-maskable-512.png',
];

/** Cache name derived from the build's own version.json.
 *
 * Computed at most once per worker instance and remembered in a promise.
 * When the network is gone the version fetch fails, and the naive fallback
 * ('dev') produces a DIFFERENT hash — i.e. a different, empty cache — so the
 * app would find nothing to serve and go blank offline. Instead we fall back
 * to whichever cache already exists, which is the build we installed with.
 */
let cacheNamePromise = null;

function hash16(text) {
  let h = 2166136261;
  for (let i = 0; i < text.length; i++) {
    h ^= text.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return (h >>> 0).toString(16);
}

async function cacheName() {
  if (cacheNamePromise) return cacheNamePromise;
  cacheNamePromise = (async () => {
    try {
      const res = await fetch('./version.json', { cache: 'no-store' });
      if (res.ok) return CACHE_PREFIX + hash16(await res.text());
    } catch (_) {
      /* fall through */
    }
    const names = await caches.keys();
    const existing = names.find((n) => n.startsWith(CACHE_PREFIX));
    return existing || CACHE_PREFIX + 'dev';
  })();
  return cacheNamePromise;
}

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const name = await cacheName();
      const cache = await caches.open(name);
      // Fetch individually rather than addAll: one missing file must not fail
      // the whole install.
      await Promise.all(
        SHELL.map(async (url) => {
          try {
            const res = await fetch(new Request(url, { cache: 'reload' }));
            if (res.ok) await cache.put(url, res);
          } catch (_) {
            /* keep going */
          }
        }),
      );
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keep = await cacheName();
      const names = await caches.keys();
      await Promise.all(
        names
          .filter((n) => n.startsWith(CACHE_PREFIX) && n !== keep)
          .map((n) => caches.delete(n)),
      );
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  // Only same-origin GET. Cross-origin (nothing today) and non-GET pass through.
  if (req.method !== 'GET') return;
  if (new URL(req.url).origin !== self.location.origin) return;

  event.respondWith(
    (async () => {
      const cache = await caches.open(await cacheName());
      const hit = await cache.match(req) || await cache.match(req.url.replace(/\/?$/, '/'));
      if (hit) return hit;
      try {
        const res = await fetch(req);
        // Only cache complete, successful responses.
        if (res && res.status === 200 && res.type === 'basic') {
          cache.put(req, res.clone());
        }
        return res;
      } catch (err) {
        // Offline and not cached. For a navigation, fall back to the shell so
        // the app boots from cache rather than showing a browser error.
        if (req.mode === 'navigate') {
          const shell =
            (await cache.match('./index.html')) || (await cache.match('./'));
          if (shell) return shell;
        }
        throw err;
      }
    })(),
  );
});
