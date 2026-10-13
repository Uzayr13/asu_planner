---
name: fashion-editorial
description: Fashion Editorial
---

# Fashion Editorial — Complete Pipeline

Built and validated against the Maggy London Formal Collection (69 products → 20 curated looks → 7 editorial chapters → magazine-grade lookbook with lifestyle/editorial tab toggle + studio-vs-editorial comparison format).

---

## OVERVIEW

The pipeline has 8 phases:

1. **Catalog extraction** — scrape product shots from e-commerce
2. **Curation** — select looks, group into chapters
3. **QA** — contact sheet to verify source frames
4. **Setting design** — choose distinct settings per chapter
5. **Image generation** — garment-faithful scene replacement
6. **Publishing** — make all images public for iframe embedding
7. **Page build** — lookbook / comparison / toggle format
8. **Delivery** — publish webpage

---

## PHASE 1 — CATALOG EXTRACTION

### Shopify (fastest)
Use the public `products.json` endpoint — no API key required:

```
GET https://{store}/collections/{handle}/products.json?limit=250&page=1
```

Paginate until the `products` array is empty. Per product extract:
- `title`, `handle`, `product_type`, `tags[]`
- `variants[0].price`
- `options[]` → find the "Color" / "Colour" option for `values[]`
- `images[]` → `images[0].src` is the hero shot (primary model photo)

Run `scrape_catalog.py` to do this automatically:
```
python scrape_catalog.py maggylondon.com formal
```
Outputs `catalog.json` + `src/00.jpg … src/NN.jpg` (hero frames).

### Other sources
For non-Shopify brands, use the Browser tools to navigate and `BrowserExtract` structured product data, then download images with `urllib`.

---

## PHASE 2 — CURATION

**Goal:** select 15–25 looks that form a coherent editorial world.

1. **Filter by relevance** — drop off-season or off-theme items (e.g. for a summer-wedding story: remove velvet, plaid, metallic knitwear)
2. **Group into 3–7 chapters** with distinct visual/temporal identity (e.g. Ceremony → Cocktail → Evening)
3. **Handle coordinated sets** — identify blouse+skirt pairs that belong together; they'll share a single generated image (pass both source shots as `inputImages`)
4. **One primary frame per look** — use `images[0].src` unless it's a flat-lay (check with QA contact sheet)

Build a `looks.json`:
```json
[{
  "id": "L01",
  "chapter": "ceremony",
  "label": "Constance — Summer Garden Gown",
  "srcs": ["https://cdn.shopify.com/..."],   // 1 per piece in the set
  "items": [{"name": "...", "price": "178.00", "url": "..."}]
}]
```

---

## PHASE 3 — QA CONTACT SHEET

Before generating, verify all source frames are on-model shots (not flat-lays or product detail shots):

```
python qa_contact_sheet.py src/ --cols 6 --cell 220
```

Opens `contact.png` — inspect every thumbnail. Any flat-lay or non-model shot → swap to a different frame from `catalog.json`'s `imgs[]` array.

---

## PHASE 4 — SETTING DESIGN

Design a distinct setting per chapter. The contrast between chapters IS the editorial arc.

### Lifestyle settings (warm, romantic, "real wedding/event" feel)
| Setting | Light quality | Best for |
|---|---|---|
| Sun-dappled private garden | Late-morning dappled | Ceremony, florals |
| Golden-hour stone villa terrace | Warm raking low sun | Cocktail |
| Blue-hour string-light garden | Warm ambient dusk | Evening, sequins |
| Victorian glass conservatory | Diffused soft daylight | Embroidery, lace |
| Clifftop Mediterranean terrace | Bright sea light | Separates, jumpsuits |
| Stone courtyard, bougainvillea | Warm dusk | Navy, deep tones |

### Editorial settings (Vogue / Harper's Bazaar aesthetic — graphic, architectural, dramatic)
| Setting | Light quality | Best for |
|---|---|---|
| Grand marble colonnade | Overcast flat / directional | Any garment — dramatic scale |
| Formal yew-hedge topiary corridor | Diffused cool daylight | Pastels, structured silhouettes |
| Vineyard rows, graphic leading lines | Hard raking afternoon | Florals, deeper colours |
| Volcanic sea rock | Bright harsh sea light | Jewel tones, sequins |
| Vast empty ballroom | Chandelier + sconce | Lace, embroidery, floor-length |
| Single overhead spotlight, darkness | One hard point light | Mermaid, column, black gowns |
| Reflecting pool, geometric hedges | Overcast silver | Florals, embroidery |
| Ancient stone courtyard, columns | Hard-edged column shadows | Navy, structured tops |

**Rule:** alternate warm and cool settings across chapters. Let light quality shift chapter to chapter (morning → afternoon → evening → darkness for evening gowns).

---

## PHASE 5 — IMAGE GENERATION (the critical phase)

### Model: `gemini-3-pro-image` (Nano Banana Pro)
- Aspect ratio: `4:5` (portrait, best for full-length garments)
- Resolution: `2K`
- `inputImages`: array of studio source URLs (1 for single-piece, 2–4 for coordinated sets)

### The Garment-Preservation Prompt Formula

This is the most important pattern. Three-part structure:

**Part A — Register declaration**
```
Full-length [lifestyle / high-fashion editorial, Vogue / Harper's Bazaar aesthetic]
fashion photograph for a [occasion] lookbook.
```

**Part B — Setting description** (be specific and architectural — vague settings = generic output)
```
Place her [in/on/beside] [SPECIFIC setting — name materials, light source, architectural elements,
colours, weather/atmosphere]. [Model pose instruction].
```
- LIFESTYLE: `"Natural elegant candid pose"`
- EDITORIAL: `"Model commanding the frame"`, `"strong editorial pose"`, `"powerful editorial stance"`

**Part C — Garment fidelity instruction (CRITICAL — never omit)**
```
CRITICAL — reproduce the [garment item(s)] EXACTLY as in the source[s]:
[list key identifiers: color, fabric, embroidery pattern, neckline, sleeves, length, silhouette].
Keep the model's appearance. Do not redesign; only change environment and lighting.
```

**Part D — Photographic grade**
- LIFESTYLE: `Shallow depth of field, soft medium-format film look, fine grain, warm luminous romantic airy color grade. Photorealistic. No text, no logos.`
- EDITORIAL: `Sharp editorial fashion photography. [Cinematic silver-cool / warm-gold and deep-shadow / warm-amber-on-deep-shadow] color grade. Photorealistic. No text, no logos.`

### Complete lifestyle example (single piece):
```
Full-length editorial fashion photograph for a luxury summer-wedding lookbook.
Take the woman and the exact bouquet-embroidered midi sheath dress from the provided
studio photo and place her in a sun-dappled private summer-wedding garden — clipped
boxwood hedges, climbing white roses and pale hydrangea, soft late-morning summer light
through tall trees, lush lawn, weathered limestone villa softly behind. Natural elegant
candid pose. CRITICAL — reproduce the dress EXACTLY as in the source: identical
blue-and-yellow bouquet floral embroidery, color, fabric, neckline, sleeves, midi length
and sheath silhouette; keep the model's appearance. Do not redesign; only change
environment and lighting. Shallow depth of field, soft medium-format film look, fine grain,
warm luminous romantic airy color grade. Photorealistic. No text, no logos.
```

### Complete editorial example (two-piece set):
```
Full-length high-fashion editorial fashion photograph, Vogue / Harper's Bazaar aesthetic.
The woman wears the coordinated outfit from the TWO provided studio photos together —
the navy 3D textured floral-embroidered puff-sleeve top with its matching navy A-line skirt.
Place her in a dramatic vineyard with low hard afternoon light raking across the vines,
graphic deep shadows between the rows striping the landscape, a Tuscan stone farmhouse
wall as a stark backdrop, strong editorial composition. Model commanding the frame.
CRITICAL — reproduce BOTH pieces EXACTLY as in the sources: identical navy color, raised
3D floral embroidery texture, fabric, neckline, puff sleeves, skirt length and A-line
silhouette; keep the model's appearance. Do not redesign; only change setting and lighting.
Sharp editorial fashion photography. Cinematic warm-gold and deep-shadow color grade.
Photorealistic. No text, no logos.
```

### Batching
- Generate up to 5–6 images per message (they run in parallel)
- For a 20-look project: batch in 4 rounds of 5 each
- Run QA montage after each batch before proceeding

### Post-generation QA
Download all generated images and build a comparison montage:
```python
from PIL import Image
# Side-by-side: source frame (left) + generated (right) per look
# Look for: garment color shift, silhouette change, embroidery pattern loss
# Red flags: model redesigned, fabric texture lost, color significantly drifted
```

---

## PHASE 6 — PUBLISHING IMAGES

**CRITICAL:** All generated images MUST be published via `PublishFilePublicly` before embedding in a `PublishWebpage` deliverable. Thread-scoped `/api/files/usergenerated/...` URLs won't render in the published sandboxed iframe.

```
PublishFilePublicly({ fileId: shortId }) → { shareUrl: "https://pub.hyperagent.com/..." }
```

Save all `shareUrl` values into a `urls.json` map keyed by look ID.

**Exception:** Shopify CDN URLs (`cdn.shopify.com`) are public and load fine in the iframe — you can use them directly for studio/original shots without publishing through the platform.

---

## PHASE 7 — PAGE BUILD

### Option A: Curated Lookbook (primary format)

Use the **Müller-Brockmann Grid Systems** skill for the grid scaffold. Core parameters:
- `--cols 12 --baseline 8 --gutter 24 --margin 64 --maxw 1360`

**Type system:**
- Display: `Fraunces` (italic, weight 400–600) — couture editorial register
- Body: `Inter` (weight 300–400) — clean and readable
- Apparatus: `Space Mono` — folios, captions, prices, labels

**Palette:**
- Paper: `#FCFBF9`
- Ink: `#16130F`
- Muted: `#6c655c`
- Accent: `#9E2B3F` (dark rose — NOT blue, NOT purple)
- Rule/line: `#e4ddd2`

**NEVER:** warm cream + terracotta + serif (reads as "the Claude look"); blue or purple gradients.

**Hero cover:**
- Full-bleed, `100svh`, parallax (`translateY(scroll * 0.26px) scale(1.06)`)
- Font: Fraunces weight 600 (NOT Bodoni Moda — hairlines wash out over photography)
- Text shadow: `0 2px 32px rgba(0,0,0,.62), 0 1px 3px rgba(0,0,0,.5)`
- Scrim: `linear-gradient(180deg, rgba(18,14,10,.44), transparent 32%, transparent 46%, rgba(18,14,10,.74))`

**Spread structure (per chapter):**
```
Band 1: numeral (large Fraunces/Bodoni) + chapter head (title, time/setting label, blurb)
Band 2: LEDE — hero look (7-col image + 4-col caption beside), alternating mirror per chapter
Band 3: DUO — two looks side by side (6+6 cols)
Band 4 (if needed): SOLO — single look centered (max-width 560px)
```

**Per-look caption anatomy:**
- Look number: Space Mono, 11px, `letter-spacing: .24em`, accent color
- Editorial note: Fraunces italic, 17–20px
- Product names + prices: Space Mono, 12–13px, flex row with price right-aligned
- Shop link: Space Mono caps, border-bottom in accent color

**Grid overlay:** include the toggle (G key) during development; comment it out (not delete) before final publish.

**Scroll reveal:** `IntersectionObserver`, threshold 0.1, `opacity + translateY(26px)` transition.

### Option B: Studio vs Editorial Comparison

Full-viewport split per look, scroll-snapped. Best for demonstrating AI image fidelity.

```css
.pair { width:100%; height:100svh; display:flex; scroll-snap-align:start; padding-top:44px; }
.studio { width:50%; background:#fff; display:flex; align-items:center; justify-content:center; border-right:1px solid rgba(0,0,0,.1); }
.studio img { max-height:100%; max-width:100%; object-fit:contain; }
.editorial { width:50%; position:relative; overflow:hidden; }
.editorial img { width:100%; height:100%; object-fit:cover; object-position:center top; }
```

Editorial right-side caption: Fraunces italic name (large), Space Mono setting label, 1-line editorial copy. White text with `text-shadow: 0 2px 24px rgba(0,0,0,.55)`. Bottom-anchored inside a gradient scrim (`transparent → rgba(0,0,0,.58)`).

Intro card: dark `#0f0f0f` background, full-viewport, "Same Dress. Different World." in Fraunces.

6 looks is the right depth for this format — choose the ones with the strongest visual contrast between studio and editorial.

### Option C: Lifestyle / Editorial Tab Toggle

Build the lookbook (Option A) first, then add the toggle:
1. Give every `<img>` two attributes: `data-lifestyle="{url}"` and `data-editorial="{url}"`
2. Fixed pill at `bottom: 32px` — "Wedding Day / Editorial" or "Lifestyle / Editorial"
3. JS swaps all images simultaneously on click with a 180ms opacity crossfade
4. Preload all editorial URLs on page load so the switch is instant

```js
document.querySelectorAll('img[data-lifestyle]').forEach(img => {
  img.classList.add('swapping');
  setTimeout(() => {
    img.src = view === 'editorial' ? img.dataset.editorial : img.dataset.lifestyle;
    img.onload = () => img.classList.remove('swapping');
  }, 180);
});
```

---

## PHASE 8 — PUBLISH

```
PublishWebpage({ filePath: "lookbook.html", title: "Brand — The [Occasion] Edit" })
```

Returns `[[ARTIFACT_xxx]]` placeholder — include in response.

To update in place (iterate without creating new artifacts):
```
PublishWebpage({ filePath: "lookbook.html", artifactId: "existing-id", title: "..." })
```

---

## KEY GOTCHAS (hard-won)

1. **Thread-scoped image URLs fail in published iframes.** Always run `PublishFilePublicly` before embedding. Public CDNs (Shopify, etc.) are fine.

2. **Two-piece sets need BOTH studio shots as `inputImages`.** Pass them as an array — the model will combine them into one coherent outfit shot. Single-image prompts for coordinated sets result in garment invention.

3. **Frame [0] is usually the hero, but always QA.** Some brands put detail shots first. Run the contact sheet before generating.

4. **The garment fidelity clause is the most critical prompt element.** Listing specific identifiers (color name, pattern name, neckline type, sleeve shape, fabric) is far more effective than generic "reproduce exactly." The more specific, the more faithful.

5. **Lifestyle ≠ Editorial register — they use different prompt language:**
   - Lifestyle: "candid", "natural", "romantic airy", "dappled", "breezy"
   - Editorial: "commanding the frame", "hard directional", "chiaroscuro", "architectural shadows", "Vogue / Harper's Bazaar aesthetic"

6. **Hero font over photography: use Fraunces 600, not Bodoni Moda.** Bodoni's hairline strokes wash out on bright backgrounds (conservatories, gardens). Fraunces at weight 600 reads clearly over any photograph.

7. **Vary chapter settings genuinely** — same warm-garden light on every chapter reads as one-location photography. Aim for: 2–3 outdoor light qualities (morning/afternoon/dusk) + 1–2 interior environments (conservatory/ballroom) + 1 dramatic night/spotlight setting.

8. **The G-key grid overlay is a dev tool, not a deliverable.** Always comment it out (not delete) before final publish — both the button HTML and the keydown listener.

9. **Scroll-snap `mandatory` on the comparison format.** `proximity` causes inconsistent snapping on fast scroll. `mandatory` ensures one clean pair per viewport.

10. **Batch image generation in groups of 5–6.** Larger batches may hit timeouts. Run QA after each batch rather than all at once.

---

## REFERENCE IMPLEMENTATION

Maggy London Formal Collection (this thread):
- 69 products scraped → 20 looks curated → 7 chapters (Conservatory, Garden, Vineyard, Coastal, Courtyard, Ballroom, Under the Stars)
- Two image aesthetics generated: lifestyle (warm/candid) and editorial (Vogue-style)
- Three deliverables: (1) magazine lookbook with grid, (2) lifestyle/editorial tab toggle, (3) studio-vs-editorial comparison split
- Grid verified at 0.13px column adherence across 1440/1180/900px viewports