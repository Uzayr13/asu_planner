{{flutter_js}}
{{flutter_build_config}}

// Custom bootstrap. Two deliberate departures from the generated file:
//
// 1. `_flutter.loader.load()` is called WITHOUT `serviceWorkerSettings`.
//    Flutter's own service worker path is deprecated (flutter/flutter#156910),
//    and given those settings it registers a stub whose activate handler
//    unregisters itself — which would remove ours. With the option omitted
//    entirely, loadServiceWorker returns early and never touches the
//    registration.
//
// 2. We register web/sw.js ourselves. That worker has a real fetch handler,
//    which is what makes this installable and usable offline.

_flutter.loader.load();

if ('serviceWorker' in navigator) {
  // Registered after load rather than at parse time so it cannot compete with
  // the engine for bandwidth during boot.
  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('sw.js')
      .then((reg) => {
        // Surface a silent failure loudly in the console: an app that claims
        // offline support without it is worse than one that never promised it.
        if (!navigator.serviceWorker.controller) {
          console.debug('Service worker registered; takes control on next load.');
        }
        return reg;
      })
      .catch((err) => console.warn('Service worker registration failed:', err));
  });
}
