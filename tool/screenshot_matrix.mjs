#!/usr/bin/env node
/**
 * Screenshot the planner at every breakpoint band.
 *
 * The UI renders to canvas, so there is no DOM text to assert on — this drives
 * by coordinate and looks at pixels. Run it against a web-server device:
 *
 *   flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1
 *   PLAYWRIGHT_BROWSERS_PATH="$HOME/Library/Caches/ms-playwright" \
 *     node tool/screenshot_matrix.mjs http://127.0.0.1:8080
 *
 * Output lands in shots/. Every PNG must be looked at: a blank frame or the
 * yellow/black overflow stripes is a failure this script cannot detect.
 */
import { chromium } from 'playwright-core';
import { mkdir } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const BASE = process.argv[2] ?? 'http://127.0.0.1:8080';
const OUT = join(dirname(fileURLToPath(import.meta.url)), '..', 'shots');

/** name -> [width, height, what it proves] */
const VIEWPORTS = {
  'se-portrait': [320, 568],
  'se-landscape': [568, 320],
  'ip8-portrait': [375, 667],
  'ip8-landscape': [667, 375],
  'ip14-portrait': [390, 844],
  'ip14-landscape': [844, 390],
  'ipad-portrait': [768, 1024],
  'ipad-landscape': [1024, 768],
  desktop: [1280, 800],
  ultrawide: [2560, 1080],
};

/** Bottom bar order in main.dart `_items`. */
const VIEWS = ['year', 'month', 'week', 'day', 'notes', 'words'];

function chromiumPath() {
  if (process.env.CHROMIUM_PATH) return process.env.CHROMIUM_PATH;
  return join(
    process.env.HOME,
    'Library/Caches/ms-playwright/chromium-1243/chrome-mac-arm64/',
    'Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing',
  );
}

async function shoot(page, name) {
  await page.screenshot({ path: join(OUT, `${name}.png`) });
  console.log(`  ${name}.png`);
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const browser = await chromium.launch({
    executablePath: chromiumPath(),
    headless: true,
  });
  // One context for the whole run: google_fonts results stay cached across
  // viewports instead of re-downloading per page.
  const context = await browser.newContext({
    viewport: { width: 375, height: 667, deviceScaleFactor: 2 },
  });

  // Warm-up: the first load compiles DDC modules and fetches fonts, and a
  // screenshot taken during that window is blank. Do it once, throw it away.
  {
    const warm = await context.newPage();
    await warm.goto(BASE, { waitUntil: 'domcontentloaded' });
    await warm.evaluate(() => document.fonts.ready).catch(() => {});
    await warm.waitForTimeout(7000);
    await warm.close();
    console.log('(warmed up)');
  }

  for (const [name, [width, height]] of Object.entries(VIEWPORTS)) {
    console.log(`${name} ${width}x${height}`);
    const page = await context.newPage();
    await page.setViewportSize({ width, height });

    await page.goto(BASE, { waitUntil: 'domcontentloaded' });
    // google_fonts fetches at runtime; Arabic renders as tofu until it lands,
    // which takes several seconds cold. Wait for the font set, then settle.
    await page.evaluate(() => document.fonts.ready).catch(() => {});
    await page.waitForTimeout(4000);
    await shoot(page, `${name}-cover`);

    // Cover is a full-screen tap target; centre always opens it.
    await page.mouse.click(width / 2, height / 2);
    await page.waitForTimeout(800);

    // Bottom bar: 6 equal slots, tap the middle of each.
    for (let i = 0; i < VIEWS.length; i++) {
      const x = (width * (i + 0.5)) / VIEWS.length;
      await page.mouse.click(x, height - 32);
      await page.waitForTimeout(600);
      await shoot(page, `${name}-${VIEWS[i]}`);
    }

    await page.close();
  }

  await browser.close();
  console.log(`\nWrote screenshots to ${OUT}`);
}

main().catch((e) => {
  console.error('SCREENSHOT_MATRIX_FAILED:', e.message);
  process.exit(1);
});
