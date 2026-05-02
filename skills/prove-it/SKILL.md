---
name: prove-it
description: Use this skill to prove an interactive UI works the way a human would experience it. Trigger PROACTIVELY whenever you believe you are done with a significant chunk of UI/UX work (new screen, non-trivial flow change, redesign, user-visible bug fix) and tests pass — passing tests prove code correctness, not human experience. Also trigger when the user explicitly asks "prove to me that this is working", "show me it works", "demo this end to end", "verify the UX", or similar. Skip for backend-only changes, trivial tweaks (single copy/color change), or quick in-development sanity checks. The skill drives the app at human pace in a real environment (browser, terminal, OS), captures screenshots and videos of realistic interactions including 1–2 human-style mistakes per scenario, and produces a self-contained static evidence site the user opens in a browser. The site has stable permalinks on every scenario, video, and screenshot so the human can paste a link back with "I expected X here". When anything doesn't pass — including capture failures (blank screenshots, broken video, app crash mid-flow) — surface the findings to the human and ASK whether they want you to loop back and fix the underlying issue or just take a summary; do not assume.
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

## Prerequisites and permissions — verify upfront, in one batch

A permission prompt or "command not found" *mid-recording* pauses the run and may corrupt the take. Confirm everything you need before driving the app.

### Tools by app type

**Web apps — preferred path: Playwright**
- `node` / `pnpm` / `npm` installed.
- Playwright installed in the project: `pnpm add -D playwright` (or pip equivalent for Python projects).
- Browsers downloaded: `npx playwright install chromium`.
- Verify: `npx playwright --version`.

**Web apps — fallback: Chrome MCP**
- The `mcp__claude-in-chrome__*` tools are connected.
- Verify: call `mcp__claude-in-chrome__list_connected_browsers`. If it returns no browsers, ask the user to install / connect the Chrome extension before continuing — do not silently fall through to a slower tier.
- Note: Chrome MCP gives you stills but not continuous video.

**Desktop apps (macOS)**
- `screencapture` is built-in.
- The terminal or IDE running Claude Code needs **Screen Recording** permission: System Settings → Privacy & Security → Screen Recording. Verify with a 1-second test: `screencapture -V 1 -v /tmp/prove-it-test.mov` and confirm the file is non-empty and not a solid black / grey rectangle.
- The `computer-use` MCP must `request_access` for the target app **before any click**. Some apps are tier-restricted (browsers → "read", terminals/IDEs → "click"); use the appropriate higher-level MCP (claude-in-chrome, Bash) for those instead.

**TUIs / terminals**
- `asciinema` installed: `brew install asciinema`. Verify: `asciinema --version`.
- Optional: `agg` to convert `.cast` to GIF for inline embedding. `brew install agg`.
- For driving a real terminal at human pace via `computer-use`, the terminal app needs access. Note the tier-"click" restriction: you can click but not type, so keystrokes flow via `osascript -e 'tell application "System Events" to keystroke ...'` from a separate Bash shell.

### Pre-allowlist Bash commands in settings

A permission prompt during a recording is disruptive. Ask the user to add the entries your run needs to `.claude/settings.json` (or project `settings.local.json`) **before** starting:

```json
{
  "permissions": {
    "allow": [
      "Bash(screencapture:*)",
      "Bash(asciinema:*)",
      "Bash(agg:*)",
      "Bash(npx playwright:*)",
      "Bash(node:*)",
      "Bash(osascript:*)"
    ]
  }
}
```

Trim the list to what you actually need. The `update-config` skill can apply this — suggest it to the user.

### The preflight contract

Before recording anything, run this preflight **once, batched**:

1. List the tools and MCPs your planned scenarios need.
2. Verify each one: version check, MCP connection check, screen-recording permission check (the 1-second test capture above).
3. List the Bash commands you expect to invoke and check they are allowlisted.
4. If anything is missing or unverified, stop and ask the user in **one** message what to install, what permissions to grant, and what to add to settings.json. Do not start a partial run.
5. Once everything checks out, proceed to scenarios.

If you discover mid-run that a tool is missing, that is a preflight bug — strengthen the preflight next time. Do not silently fall through to a degraded capture mode and call it done.

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
- Filename screenshots in order: `01-landing.png`, `02-signup-form-filled.png`, `03-confirmation.png`. The viewer renders them in the order you list them in metadata.

### 5. Write the metadata

For each scenario, build a metadata object. The viewer reads this directly from an inline `<script type="application/json" id="metadata">` block (see step 6). Schema:

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
      "status": "pass",
      "expected": "After confirming the email, the user lands on an empty dashboard with a 'Create your first project' CTA.",
      "observed": "Matches expected.",
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

Field guidance:

- `expected` and `observed` — when both are present, the viewer renders them side-by-side. Always fill both for `needs-attention` and `fail` scenarios. For clean `pass` scenarios you can omit them or write a one-liner like `"Matches expected."`.
- `narrative` — one sentence describing the user journey, written before the run.
- `notes` — anything specific about the run (mistakes you made on purpose, test data used, environmental quirks). Goes in a callout under the scenario.
- `video` and `screenshots` — relative paths from the run directory (`current/`).

### 6. Build the static site

The skill ships a self-contained HTML viewer at `templates/site/viewer.html` — one file with inline CSS and a tiny inline JS renderer. It reads its data from a `<script type="application/json" id="metadata">…</script>` block inside itself. **No server, no build step, no Python, no Node, no CDN.**

The viewer is branded **Proof** in the UI (the page title, the nav logo, and the document title). The skill is still called `prove-it` but when you reference the artifact to the user, calling it "the Proof site" or "the Proof page" matches what they see on screen.

The viewer renders scenarios as **tabs** — each scenario is its own tab/page within the viewer, not a long scroll. The first tab is active by default; permalinks (e.g. `#signup-happy-path`, `#signup-happy-path--video`, `#signup-happy-path--shot-02`) automatically activate the right tab and scroll to the inner anchor when the human pastes a link back. A "Things that need your attention" findings block above the tabs and a "What do you want me to do next?" prompt below them are cross-cutting — they don't live inside a single tab.

To build a run's site:

1. Copy the viewer to the run directory:
   ```bash
   cp <skill-path>/templates/site/viewer.html <project>/prove-it/current/index.html
   ```
2. Replace the placeholder JSON inside `<script type="application/json" id="metadata">…</script>` with your run's real metadata (use the Edit tool — the placeholder block is the only thing you change).
3. Confirm assets are in place: `<project>/prove-it/current/assets/<scenario-slug>/...`.
4. Open `current/index.html` in the user's browser to verify it renders. Confirm the scenario count is right, the overall status pill matches, and at least one video plays.

The viewer renders permalinks (`#<slug>`, `#<slug>--video`, `#<slug>--shot-NN`) on every scenario, video, and screenshot automatically. The human will use these to paste-back precise feedback.

You may also keep `metadata.json` as a separate file alongside `index.html` for tooling — but the viewer reads only the inline block, so the inline copy is the source of truth.

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
- If anything didn't pass cleanly, note that the viewer's "What do you want me to do next?" block at the bottom asks them to choose: **loop back** (you fix the underlying issues and re-run from scratch) or **summary only** (you stop and let them decide). Wait for their answer.
- Tell them about the paste-back affordance: they can right-click the `#` next to any scenario, video, or screenshot and copy the link, then paste it into the conversation with what they expected ("this video should have shown X, instead I see Y"). You'll act on that pinpoint feedback.

Do not paste large logs. The site is the artifact.

## When something doesn't pass, ASK the human

Whenever a scenario does not pass cleanly — including capture failures (blank screenshots, broken video, app crash mid-flow), in-flow misbehavior (wrong copy, broken button, weird state), or anything that surprises you — record the partial evidence faithfully, then **ASK the human what to do next.** Do not unilaterally loop back into a fix attempt, and do not paper over the issue.

Do **not**:

- Skip the scenario and move on as if it passed.
- Substitute a screenshot from a previous run, a mockup, or the design file.
- Hand-edit metadata to claim the scenario passed.
- Quietly drop a broken scenario from the report.
- Decide on your own to "fix it real quick" before reporting back.

Do:

- Stop the run.
- Record the scenario in metadata with status `fail` (capture failure or app misbehavior) or `needs-attention` (worked but felt wrong), with whatever evidence you actually got.
- Fill in the `expected` and `observed` fields so the viewer renders "what should have happened" vs "what did happen" side by side.
- The viewer's bottom "What do you want me to do next?" block presents the human with two options: **loop back** (you fix the underlying issues and re-run from scratch) or **summary only** (you stop). Wait for their choice — do not assume.
- The viewer's permalinks let the human respond precisely — they can paste a link to a specific video or screenshot back to you with "I expected X here, this shows Y". Be ready to act on that pinpoint feedback.

The whole point of this skill is to surface problems a human would notice that machine tests miss. When that signal arrives, honor it: faithful evidence, clear ask, then wait.

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
- **A fancy SPA evidence site with a build step.** The shipped viewer is a single HTML file with inline CSS + a tiny inline renderer. Don't replace it with React, a static-site generator, or anything that requires a build chain — the user must be able to open the file directly via `file://`.
- **Skipping the preflight check.** A "command not found" or permission prompt mid-recording wastes the take. Verify tools, MCPs, screen-recording permission, and Bash allowlist entries upfront, in one batched message to the user.
- **Stacking 5 deliberate mistakes per scenario.** The user will think the app is broken.
- **Asking the user 8 questions up front.** Batch them. Lean on context first. Save answers in HUMAN_EVIDENCE.md.
- **Reusing screenshots from a prior run.** Always re-capture. The point is *this* run is real.
- **Making real-world side effects** (sending real email, charging real cards, posting to real Slack, deleting real records) without explicit per-scenario user approval. When in doubt, stop and ask.
- **Working around a capture failure** by skipping the scenario, hand-editing metadata, or substituting old / mocked assets. A capture failure is the loudest signal this skill produces — record it faithfully and ask the human what to do.
- **Deciding for the human when something fails.** Don't unilaterally loop back into a fix attempt. The viewer asks the human "loop back or summary only?" — wait for their answer.

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
        │   └── rotate.sh
        └── templates/
            ├── HUMAN_EVIDENCE.template.md
            ├── metadata.example.json
            └── site/
                └── viewer.html      # self-contained: inline CSS + inline JS renderer
```

In the **target** project (where you are proving things):

```
<project>/
└── prove-it/
    ├── HUMAN_EVIDENCE.md            # durable, may be committed
    ├── current/                     # latest run, gitignored
    │   ├── index.html               # copy of viewer.html with metadata injected
    │   └── assets/<scenario>/
    │       ├── video.webm
    │       └── *.png
    └── archive/                     # last 2 runs, gitignored
        ├── 2026-04-30-1015/
        └── 2026-04-28-0902/
```
