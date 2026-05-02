---
name: prove-it
description: Use this skill to prove an interactive UI works the way a human would experience it. Trigger PROACTIVELY whenever you believe you are done with a significant chunk of UI/UX work (new screen, non-trivial flow change, redesign, user-visible bug fix) and tests pass — passing tests prove code correctness, not human experience. Also trigger when the user explicitly asks "prove to me that this is working", "show me it works", "demo this end to end", "verify the UX", or similar. Skip for backend-only changes, trivial tweaks (single copy/color change), or quick in-development sanity checks. The skill drives the app at human pace in a real environment (browser, terminal, OS), captures screenshots and videos of realistic interactions including 1–2 human-style mistakes per scenario, and produces a self-contained static evidence site the user opens in a browser. If capture fails (blank screenshots, broken video, app crashes mid-flow), that IS the signal — loop back and fix the real human-facing issue, do not paper over it.
---

# prove-it

You have been invoked to **prove that an interactive application works** — the way a careful human reviewer would prove it: by actually using the app at a human pace, in a real environment, and producing visual evidence the user can scrub through afterward.

This skill is **not** a substitute for unit or integration tests — those prove code correctness. This skill proves **product correctness**: the thing a human uses behaves the way a human expects.

## When to use

### Proactively, when you think you are "done"

Use this skill **whenever you believe you have finished a significant chunk of UI / UX work** — a new screen, a non-trivial flow change, a redesign, a bug fix that touches the user's experience — and your tests pass.

Tests passing means the **code** does what you wrote. It does not mean a **human** will have the experience you (or the user) expect. Unit tests, component tests, and end-to-end suites (Playwright, Puppeteer, Videotape for BubbleTea, etc.) run at machine speed in sandboxed environments. They do not tell the story.

Before declaring a UI / UX task done, frame it like this to yourself:

> "I ran all the tests and they pass. Now let me prove that a human will have the experience the user expects."

Then run this skill.

### When the user explicitly asks

Also use it when the user says any of:

- "prove to me that this is working"
- "show me it works"
- "demo this end to end"
- "verify the UX"
- "give me evidence the feature works"
- "I want to see it actually run"

### When NOT to use

- Backend-only changes with no user-visible UI affected — run tests instead.
- Quick sanity checks during active development — the user can see their own screen.
- Large unchanged areas of an app — only prove what was changed or what the user asked about.
- Trivial UI tweaks (a copy change, a color adjustment) where a single screenshot in the conversation is enough.

## What you produce

When you finish, the user can open a single HTML file in a browser and see:

- A timeline of scenarios.
- For each scenario: a short narrative, key screenshots, and a short video.
- An overall pass / needs-attention / fail summary.
- A timestamp and the environment used (browser version, OS, app version when known).

The output lives at `<project>/prove-it/current/index.html`, with the previous two runs in `<project>/prove-it/archive/<timestamp>/`.

## Workflow

### 1. Gather context

Read the conversation. You may already know the app type, how to launch it, and what to verify.

Then check for an existing `prove-it/HUMAN_EVIDENCE.md` in the project. **Read it first if it exists** — it contains durable answers from prior runs (test credentials, demo data, what NOT to touch).

If you cannot answer the following from context + HUMAN_EVIDENCE.md, ask the user **once, in a single batched question**, then save the answers to `prove-it/HUMAN_EVIDENCE.md` so future runs do not re-ask:

- How do I launch the app? (command, port, URL, or app path)
- Are there test credentials I should use? (never store real production secrets)
- Which 2–5 user journeys are most important to prove?
- Is there demo / seed data I should rely on?
- Anything I must NOT touch? (destructive actions, real billing, real outbound email, real-user data)

Keep `HUMAN_EVIDENCE.md` short — bullet form, no narration. Redact secrets. The file is durable across runs and may be committed to source control, so do not put live credentials in it; reference how to obtain them instead ("see 1Password vault X" or "see .env.test").

### 2. Plan scenarios

Pick 2–5 scenarios that map to real user journeys. For each scenario, write a one-line narrative *before* you run it (e.g., "New user signs up, gets confirmation email, lands on empty dashboard"). These narratives go into the evidence site.

A scenario should:

- Cover a complete user-visible outcome, not a single click.
- Be repeatable (no irreversible side effects unless explicitly approved by the user).
- Take 30–90 seconds of wall-clock time at human pace.

State the scenarios to the user before recording them, in case they want to redirect.

### 3. Run each scenario at human pace

This is the part most agents get wrong. The proof is only convincing if the footage *looks* like a human used the app. Robot-speed automation — instant fills, teleporting clicks, sub-100 ms actions — undermines the evidence even when it works.

**Pace targets:**

- 300–800 ms between discrete actions.
- 1–2 second pause after any nontrivial state change (page load, modal open, async update) before acting again — this is "reading time".
- Typing at ~80–180 ms per character, not all at once. Use whatever per-keystroke delay your driver supports (Playwright `page.keyboard.type(text, {delay: 120})`, computer-use `type` with realistic chunking).

**Realism:**

- Move the mouse to the target before clicking; do not teleport.
- Hover briefly over destructive buttons before deciding.
- Scroll if content is below the fold rather than jumping to it.
- Resize/move the window to a natural size before recording — not full screen, not 800x600.

**Quirky human mistakes — sparingly. Hard cap: 1–2 small recoveries per scenario.**

Pick at most one or two from this list, never more:

- Type one wrong character, backspace, type the correct one.
- Click an adjacent wrong field, realize, click the right one.
- Submit a form with an obviously empty required field, see the error, fix it.
- Use the wrong nav link first, hit back.
- Hover over the wrong menu item, then move to the right one.

Avoid:

- Mistakes in destructive flows. Do not "accidentally" hit Delete.
- Mistakes that surface bugs you were not asked to test — they confuse the evidence.
- More than one mistake per minute of footage. Stacking mistakes makes the app look broken.
- Mistakes in payment, auth, or anything with real-world side effects.

### 4. Capture the right evidence

Pick capture tooling by environment.

#### Web apps

Prefer **Playwright** with video recording when you can install it:

```js
const browser = await chromium.launch({ slowMo: 250 });
const context = await browser.newContext({
  viewport: { width: 1280, height: 720 },
  recordVideo: { dir: 'prove-it/current/assets/<scenario>/', size: { width: 1280, height: 720 } },
});
const page = await context.newPage();
// ...interact, with page.waitForTimeout(...) between steps...
await page.screenshot({ path: 'prove-it/current/assets/<scenario>/01-landing.png' });
await context.close(); // flushes video
await browser.close();
```

If Playwright is not available, fall back to:

- **Chrome MCP** (`mcp__claude-in-chrome__*`) for DOM-aware interactions + `screenshot` / `preview_screenshot` calls at each step. This gives you stills but **not** continuous video. Note that limitation in the scenario narrative.
- **Computer-use MCP** + `screencapture -V` (see Desktop below). Slower, more fragile, but works as a last resort.

#### Desktop apps (macOS)

- Video: `screencapture -V <duration_seconds> -v <out.mov>` records the screen for a fixed duration. Use a fresh terminal to start it just before driving the app.
- Region screenshots: `screencapture -R x,y,w,h <out.png>`.
- Window screenshot by ID: `screencapture -l <window-id> <out.png>` (resolve window id with `osascript` if needed).
- Drive the app via the `computer-use` MCP. **Always `request_access` for the specific app first.** Some apps are tier-restricted (browsers, terminals, IDEs); use the appropriate higher-level MCP instead in those cases.

#### TUIs / terminals

- `asciinema rec <out.cast>` produces a replayable terminal recording. Embed via a vendored `asciinema-player` (no CDN) in the static site, or convert to a video with `agg out.cast out.gif` if you want a single inline asset.
- For a final screenshot, capture the terminal window region with `screencapture`.
- Bash tool typing happens instantly — for human-pace TUI demos, you must launch a real terminal app and drive it via `computer-use`, accepting the tier-"click" restriction (you can click but not type, so you may need to script keystrokes via `osascript -e 'tell app "System Events" to keystroke ...'` from a separate Bash shell).

#### Universal capture rules

- Cap each video at **90 seconds**. Long videos are unwatched.
- Cap resolution at **1280x720** (or the app's natural window size at 1x). Do not record retina at 2x — files balloon 4x with no benefit on the static site.
- Take **4–8 still screenshots per scenario** at key moments. Stills load instantly; videos are for the curious viewer.
- Filename screenshots in order: `01-landing.png`, `02-signup-form-filled.png`, `03-confirmation.png`. The build script orders by name.

### 5. Write the metadata

For each scenario, write a `metadata.json` entry. The build script (see `scripts/build_site.py`) renders the site from this. Schema:

```json
{
  "run_id": "2026-05-02-1432",
  "app": { "name": "showme", "version": "0.4.1", "url_or_command": "http://localhost:3000" },
  "environment": { "os": "macOS 15.4", "browser": "Chromium 130 (Playwright)" },
  "scenarios": [
    {
      "slug": "signup-happy-path",
      "title": "New user signs up and lands on dashboard",
      "narrative": "Brand new user fills the signup form, confirms via email link, lands on empty dashboard.",
      "status": "pass",            // pass | needs-attention | fail
      "duration_seconds": 47,
      "video": "assets/signup-happy-path/video.webm",
      "screenshots": [
        { "file": "assets/signup-happy-path/01-landing.png", "caption": "Landing page" },
        { "file": "assets/signup-happy-path/02-form.png", "caption": "Signup form filled" }
      ],
      "notes": "Briefly typed wrong email, corrected. No real email sent — used MailHog test inbox."
    }
  ]
}
```

`status` values:

- `pass` — scenario completed, app behaved as expected.
- `needs-attention` — completed, but you noticed something the user should look at (slow load, confusing copy, minor visual glitch).
- `fail` — scenario could not be completed or app misbehaved.

### 6. Build the static site

Run `scripts/build_site.py <project>/prove-it/current/`. It reads `metadata.json` from that directory and writes a self-contained `index.html` + `style.css`.

The site MUST work when opened directly via `file://` — no web server, no CDN, no build step at view time. Verify by opening `current/index.html` in the user's browser before reporting done.

### 7. Rotate the archive

**Before** writing the new `current/`, run `scripts/rotate.sh <project>/prove-it 2`. It:

- Moves `current/` to `archive/<YYYY-MM-DD-HHMM>/` if it exists.
- Trims `archive/` to the newest 2 entries.

Do not write your own `rm -rf` rotation in the moment. Use the script.

### 8. Report to the user

In your final message:

- One sentence: what you proved.
- Path to the evidence: `prove-it/current/index.html`.
- Any scenario that failed or needed attention, called out explicitly.
- Anything you could not prove and why (e.g., "did not test payment flow because no test card is configured in HUMAN_EVIDENCE.md").

Do not paste large logs. The site is the artifact.

## When capture fails, that IS the signal

If you cannot produce the evidence — the page is blank, the screenshot is empty, the video shows the app crashing, the form will not submit, the modal never opens, the terminal output is gibberish — **that is the most important finding of the run.** It is not a nuisance to work around.

Do **not**:

- Skip the scenario and move on.
- Substitute a screenshot from a previous run, a mockup, or the design file.
- Hand-edit `metadata.json` to claim the scenario passed.
- Quietly drop the broken scenario from the report.
- "Make do" with partial evidence and call it pass.

Do:

- Stop the run.
- Treat the capture failure as a real bug discovered at human-experience time.
- Loop back to the underlying work. The tests passed but the human cannot use the app — the tests were lying or insufficient. Fix the real issue.
- When the fix lands, re-run the skill from scratch.
- If you genuinely cannot fix it (out of scope, blocked, missing info), record the scenario as `fail` with whatever partial evidence you got (the broken screenshot, the empty video, the error message), explain in `notes` what went wrong, and surface this prominently to the user. Do not bury it.

The whole point of this skill is to surface problems **a human would notice** that **machine tests miss**. A capture failure is exactly that signal arriving. Honor it.

## Disk hygiene — non-negotiable

Videos consume disk fast. The rotation rule (current + 2 archives) is firm.

- Total `prove-it/` per project: soft cap **500 MB**. If a run would exceed it, drop video resolution, duration, or scenario count before adding more.
- Add `prove-it/current/` and `prove-it/archive/` to `.gitignore`. **Never** commit them.
- `prove-it/HUMAN_EVIDENCE.md` is the **exception** — it is durable, useful, and may be committed (with secrets redacted). Add it to git deliberately.

If you find pre-existing `prove-it/` directories that look stale (e.g., months old, hundreds of MB), surface this to the user before deleting — it may belong to other tooling.

## Anti-patterns

- **Headless puppeteering at robot speed with no video.** The user cannot tell whether the app rendered correctly. The whole point is human-believable evidence.
- **"I ran the tests and they passed."** Tests are not the evidence the user asked for. Run the app.
- **One 12-minute video per scenario.** If a scenario takes 12 minutes, it is the wrong scenario. Break it up.
- **A fancy SPA evidence site with a build step.** The site must open directly from disk in any browser, no install.
- **Stacking 5 deliberate mistakes per scenario.** The user will think the app is broken.
- **Asking the user 8 questions up front.** Batch them. Lean on context first. Save answers in HUMAN_EVIDENCE.md.
- **Reusing screenshots from a prior run.** Always re-capture. The point is *this* run is real.
- **Making real-world side effects** (sending real email, charging real cards, posting to real Slack, deleting real records) without explicit per-scenario user approval. When in doubt, stop and ask.
- **Working around a capture failure** by skipping the scenario, hand-editing metadata, or substituting old / mocked assets. A capture failure is the loudest signal this skill produces. Stop, fix the underlying issue, re-run.

## File layout reference

In the prove-it repo (this skill):

```
prove-it/
├── README.md
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── prove-it/
        ├── SKILL.md                 # this file
        ├── scripts/
        │   ├── rotate.sh
        │   └── build_site.py
        └── templates/
            ├── HUMAN_EVIDENCE.template.md
            ├── metadata.example.json
            └── site/
                ├── index.html
                └── style.css
```

In the **target** project (where you are proving things):

```
<project>/
└── prove-it/
    ├── HUMAN_EVIDENCE.md            # durable, may be committed
    ├── current/                     # latest run, gitignored
    │   ├── index.html
    │   ├── style.css
    │   ├── metadata.json
    │   └── assets/<scenario>/
    │       ├── video.webm
    │       └── *.png
    └── archive/                     # last 2 runs, gitignored
        ├── 2026-04-30-1015/
        └── 2026-04-28-0902/
```
