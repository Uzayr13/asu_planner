---
name: venue-visualizer
description: Venue Visualizer
---

# Venue Visualizer

**Purpose**: Show what a brand looks like *activated inside a real venue* — three 16:9 shots, each with a smooth crossfade toggle between the empty venue and the brand-activated version. Final output is a self-contained interactive HTML page (PublishWebpage).

---

## Inputs needed from the user

| Input | Notes |
|---|---|
| 3–5 venue photos | Real photography of the venue — interior, courtyard, entrance, etc. Wider / landscape preferred but any format works; the crop step normalizes to 16:9 |
| Brand logo / asset | The actual logo file. Feeding the real asset to GPT Image 2 as an `inputImages` reference is the critical step for logo fidelity |
| Brand name | String used in the page title, toggle button, and activation prompt |
| Brand accent colors | 1–3 hex values. Defaults: `#b9ee46` (lime), `#bcaaff` (lavender), `#8fd2ff` (sky) |
| Shot labels | 3 short names, e.g. "Arrival Lobby", "The Courtyard", "The Entrance" |
| Short captions | One line per shot describing what the activation is, e.g. "Becomes the brand booth" |

---

## Workflow (step by step)

### Step 1 — Prepare blank-slate before-plates

Crop each venue photo to exact **16:9 at 1536×864** using the provided crop script.
This ensures before/after images are pixel-matched, making the crossfade seamless.

```bash
bash skills/venue-visualizer/crop_venue_shots.sh venue1.jpg venue2.jpg venue3.jpg -o workspace/
```

The ffmpeg filter used:
```
crop=iw:trunc(iw*9/16/2)*2,scale=1536:864
```

**Host each cropped blank** with `SaveFile` + `PublishFilePublicly` so GPT Image 2 can receive them as `inputImages` URLs. Thread-scoped `/api/files/...` URLs work as `inputImages` even without publishing, but publish them now anyway — you'll need the public URLs for the HTML.

---

### Step 2 — Host the brand asset

Save and publish the user's logo/brand file with `SaveFile` + `PublishFilePublicly`. You'll pass this as the second `inputImages` entry on every generation.

---

### Step 3 — Generate activated versions (GPT Image 2)

Generate one activated image per venue shot. Use this prompt template:

```
IMAGE 1 is a real photo of [VENUE NAME] — preserve its architecture, [describe key features: wood/greenery/columns/etc], camera angle and lighting EXACTLY.
IMAGE 2 is the [BRAND NAME] event branding — reproduce the [describe wordmark] "[BRAND NAME]" wordmark EXACTLY. [No other text, no dates.]

Keep the room EXACTLY as in IMAGE 1 — identical architecture, walls, floor, plants, camera angle and lighting. Do NOT move or change the space. ONLY add a tasteful [BRAND NAME] brand-activation [SURFACE TYPE: booth / lounge / registration desk] into the existing scene:
- A large "[BRAND NAME]" [wordmark description] sign mounted prominently and centered
- [2–3 specific activation elements: demo screens / counter / lounge seating / photo backdrop]
- Soft [accent colors] pastel accent lighting that ties to the brand

Warm, premium, photorealistic, full color, widescreen. [No crowds / A few casual attendees]. The only text anywhere is the "[BRAND NAME]" wordmark — crisp and legible.
```

**Key parameters:**
- `model: "openai/gpt-image-2"` — always use GPT Image 2 for logo-faithful typography
- `aspectRatio: "16:9"` — must match the blank plates
- `quality: "high"`
- `inputImages: [blank_plate_url, brand_logo_url]` — two images, always in this order

**Critical learnings:**
- "Keep the room EXACTLY as in IMAGE 1" is the most important line — without it the model reimagines the space
- Always pass the real brand asset as `inputImages[1]`; text description alone causes logo drift
- "No fine print, no dates, only the [BRAND NAME] wordmark" prevents hallucinated event details
- "No crowds" keeps the toggle readable
- Never ask for colors in a logo that should be monochrome — say "strictly monochrome black, NO red/yellow/blue" explicitly

---

### Step 4 — QA each before/after pair

```bash
for n in 1 2 3; do
  ffmpeg -y -i blank${n}.png -i act${n}.png \
    -filter_complex "[0]scale=760:-1[a];[1]scale=760:-1[b];[a][b]vstack" pair${n}.png 2>/dev/null
done
ffmpeg -y -i pair1.png -i pair2.png -i pair3.png \
  -filter_complex "[0]scale=-1:760[a];[1]scale=-1:760[b];[2]scale=-1:760[c];[a][b][c]hstack=3" qa_grid.png 2>/dev/null
```

Use `Read` to visually inspect. Accept if: room architecture is identical, wordmark is legible and faithful, no unintended text. If a panel fails, regenerate with "Do NOT add, remove, or modify ANY architectural element."

---

### Step 5 — Publish all 6 images

`PublishFilePublicly` for each blank + activated image. The iframe served by PublishWebpage is sandboxed — thread-scoped `/api/files/...` URLs will be blocked. All `<img src>` values in the HTML **must** be `pub.hyperagent.com` URLs.

---

### Step 6 — Generate the HTML

```bash
python3 skills/venue-visualizer/generate_visualizer.py \
  --blank   BLANK1_URL BLANK2_URL BLANK3_URL \
  --act     ACT1_URL   ACT2_URL   ACT3_URL   \
  --brand   "AIRSPACE" \
  --venue   "1 Hotel West Hollywood" \
  --labels  "Arrival Lobby" "The Courtyard" "The Entrance" \
  --captions \
    "Becomes the brand booth — hero signage, demo screens, welcome counter." \
    "Becomes the Build Bar — overhead signage, communal counter, lounge." \
    "Becomes registration — branded wall, desk, photo moment." \
  --accent1 "#b9ee46" --accent2 "#bcaaff" --accent3 "#8fd2ff" \
  --font    "Pixelify Sans" \
  --output  workspace/visualizer.html
```

---

### Step 7 — Publish the page

```python
PublishWebpage(filePath="workspace/visualizer.html", title="BRAND — Venue Visualizer")
```

---

## Supported variations

| Variation | How |
|---|---|
| Portrait triptych | Use `aspectRatio: "3:4"` in generation; crop with `crop=trunc(ih*3/4/2)*2:ih` |
| Dark-mode page | Change `--paper` to `#0a0a0c` and `--ink` to `#f3f2ee` in the generated HTML |
| More / fewer shots | The script generates one `<div class="shot">` per pair passed |
| Sponsor logo in header | Embed a `<img>` beneath `<h1>` using the published logo URL |

---

## Activation surface prompts (ready to use)

**Exhibition booth:**
> "A sleek brand-activation booth — a large [BRAND] sign on the wall, two demo screens on slim stands showing clean grid interfaces, a low welcome counter, soft [ACCENT] pastel accents. No crowds."

**Build Bar / communal lounge:**
> "A [BRAND] Build Bar — a large [BRAND] sign overhead, communal counter with bar stools, warm pendant lights, lounge chairs and plants, soft [ACCENT] accents. A few effortlessly cool attendees in elevated casual (linen, denim) collaborate at the counter."

**Registration + photo-op:**
> "A [BRAND] registration moment — a large [BRAND] backdrop wall to one side, a sleek check-in desk, badge/lanyard stand. No hanging ceiling banners. The central entrance is completely unobstructed."

**Keynote stage:**
> "A [BRAND]-presented keynote — large LED backdrop displaying the [BRAND] logo and '[EVENT]' in the existing stage architecture. Keep all stage lighting, the podium, and audience seating. A speaker stands at the podium."

---

## Common failure modes & fixes

| Failure | Fix |
|---|---|
| Room architecture changes | Add "Do NOT add, remove, or modify ANY architectural element — every wall, floor, column, window, plant and fixture must be unchanged" |
| Logo has wrong colors | Add "Strictly [COLOR], absolutely NO [OTHER COLORS]" + pass real logo as `inputImages[1]` |
| Fine print / dates appear | Add "The ONLY text anywhere is the [BRAND] wordmark. No dates, no city names, no taglines." |
| Doorway blocked by booth | Add "Keep the central entrance completely unobstructed. Place all activation elements flanking the sides only." |
| People look corporate | Add "NO business suits. Elevated casual only — linen, quality denim, knitwear." |