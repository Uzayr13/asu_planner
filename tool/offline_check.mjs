#!/usr/bin/env node
/**
 * Prove the web build works with no server at all.
 *
 * This is the acceptance test for the offline service worker. It is the only
 * check that matters for that claim: Flutter 3.47's own build ships a service
 * worker whose activate handler unregisters itself, so "it loaded online" proves
 * nothing about offline.
 *
 * Usage (from the repo root):
 *   sh tool/build_web.sh /
 *   python3 -m http.server 8080 --directory build/web &
 *   node tool/offline_check.mjs
 *
 * It warms the cache through the real app, kills the server mid-run, then
 * reloads. PASS means the app rendered from the service worker cache alone.
 */
import { chromium } from 'playwright-core';
import { execSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const BASE = process.argv[2] ?? 'http://127.0.0.1:8080/';
const OUT = join(dirname(fileURLToPath(import.meta.url)), '..', 'shots');

function chromiumPath() {
  if (process.env.CHROMIUM_PATH) return process.env.CHROMIUM_PATH;
  return join(
    process.env.HOME,
    'Library/Caches/ms-playwright/chromium-1243/chrome-mac-arm64/',
    'Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing',
  );
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function main() {
  const browser = await chromium.launch({
    executablePath: chromiumPath(),
    headless: true,
  });
  // One context throughout: a fresh context has no service worker and no
  // cache, so warming and testing must share a session.
  const ctx = await browser.newContext({
    viewport: { width: 375, height: 667, deviceScaleFactor: 2 },
  });
  const page = await ctx.newPage();

  console.log('1) warming the cache while the server is up...');
  await page.goto(BASE, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(7000);
  // Second load so the worker controls this page.
  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(5000);
  const controller = await page.evaluate(
    () => navigator.serviceWorker.controller?.scriptURL?.replace(location.origin, '') ?? null,
  );
  console.log('   controller =', controller);
  if (!controller || !controller.endsWith('sw.js')) {
    console.log('FAIL: the controlling worker is not our sw.js');
    await browser.close();
    process.exit(1);
  }

  console.log('2) killing the web server...');
  try {
    execSync('pkill -f "http.server 8080"');
  } catch (_) {
    /* nothing to kill */
  }
  await sleep(1500);

  console.log('3) reloading with no server...');
  await page
    .reload({ waitUntil: 'domcontentloaded' })
    .catch((e) => console.log('   reload:', e.message));
  await page.waitForTimeout(8000);
  await page.screenshot({ path: join(OUT, 'offline-no-server.png') });

  const state = await page.evaluate(() => ({
    flutterView: !!document.querySelector('flutter-view'),
    title: document.title,
    controlled: !!navigator.serviceWorker.controller,
  }));
  console.log('   RESULT:', JSON.stringify(state));
  await browser.close();

  if (state.flutterView && state.controlled) {
    console.log('PASS: the app rendered with no server.');
  } else {
    console.log('FAIL: nothing rendered offline.');
    process.exit(1);
  }
}

main().catch((e) => {
  console.error('OFFLINE_CHECK_FAILED:', e.message);
  process.exit(1);
});
