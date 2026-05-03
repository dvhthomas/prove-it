---
name: prove-it
description: Use this skill to prove an interactive UI works the way a human would experience it — exploratory verification, not scripted testing. Trigger PROACTIVELY whenever you have just finished a significant chunk of UI/UX work (new screen, non-trivial flow change, redesign, user-visible bug fix) and tests pass — passing tests prove code correctness, not human experience. Also trigger on explicit asks like "prove to me that this is working", "show me it works", "demo this end to end", "verify the UX". Skip for backend-only changes, trivial copy/color tweaks, or in-development sanity checks. The skill forces you to drive the app at human pace in a real, visible environment (browser window, real terminal, launched app — never headless), capture video and screenshots of realistic interactions including 1–2 small human-style mistakes per scenario, and produce a self-contained static evidence site (the "Prove It" viewer) the human opens in a browser. Every scenario, video, and screenshot has a stable permalink so the human can paste a link back with "I expected X here, this shows Y". When something doesn't pass — capture failure or in-flow misbehavior — record faithful evidence and ASK the human whether to loop back and fix, or stop with a summary. Do not assume.
---

# prove-it

You have been invoked to **prove that an interactive application works** by *feeling your way through it as a human would.*

Drive the app at a human pace in a real, visible environment. Make the small mistakes a real person makes. Capture what you see. Show the human evidence they can scrub through and trust.

## prove-it vs scripted tests

Scripted tests (Playwright suites, Puppeteer specs, BubbleTea Videotape recordings) prove **invariants**: did selector X reach state Y. They run at machine speed, in headless or virtualized environments, and produce pass/fail signals.

prove-it proves **experience**: what a curious human would conclude after using the app for a couple of minutes. Same underlying tools (you may even use Playwright as the driver) — totally different use mode. You are not writing assertions. You are *exploring*. You form judgments while interacting and write them into the evidence as `expected` vs `observed`.

If a scripted test could prove what the user is asking, run the test. If they want to know "does this *feel* right when a person uses it?" — that is this skill.

## When to use

Proactively, whenever you have just finished a significant chunk of UI/UX work and tests pass. Frame it: *"I ran all the tests and they pass. Now let me prove a human will have the experience the user expects."*

Also when the user says: "prove to me that this is working", "show me it works", "demo this end to end", "verify the UX".

Skip for backend-only changes, trivial UI tweaks (a copy edit, a color change), or quick in-dev sanity checks.

## The contract — read this carefully

Three things you must do, no exceptions:

1. **Use a real, human-visible environment.** A real browser window the human could see (not headless). A real terminal the human could open. A real launched desktop app. If you find yourself reaching for a virtualized DOM, a sandbox, or a "fake browser", stop — that is not what this skill is for.

2. **Move at human pace.** 300–800ms between discrete actions. 1–2s reading pause after any nontrivial state change (page load, modal, toast, async update). Type at ~80–180ms per character. Move the mouse, do not teleport. Hover before deciding on destructive buttons. Scroll if content is below the fold.

3. **Show your work to the human.** Produce the Prove It viewer and verify it opens. The human reviews video and stills to confirm you actually behaved like a human. If the videos look robotic, you failed the contract — even if the app worked.

## Quirky human mistakes — sparingly

Hard cap: **1–2 small recoveries per scenario.** Pick from: typo + backspace, wrong adjacent field click + retry, submit-without-required-field + see-error + fix, wrong nav link + back. Avoid mistakes in destructive flows, mistakes that surface unrelated bugs, mistakes in payment/auth, and stacking mistakes. More than that and the app looks broken.

## Workflow

### 1. Gather context

Read the conversation. Check `<project>/prove-it/HUMAN_EVIDENCE.md` if it exists — it has durable answers from prior runs.

Then ask only what you actually need. Do NOT collect everything up front "just in case".

**Truly required to start a run** (block on these — ask if missing):

- How do I launch the app? (command, port, URL, or app path)
- At least one user journey to prove. *One* is enough — you can always do more.

**On user journeys: always confirm with the user, even if you can guess.** The user is the authority on what's worth proving. Recent context may suggest an obvious journey (the feature just shipped, the bug just fixed), but state your guess and get a thumbs-up before recording — do NOT silently start exploring on your own theory. A run on the wrong journey wastes time and burns disk.

**Propose 3–5 concrete options, don't open-endedly ask.** Phrase each option as a real user moment, not a feature name. The user can pick one (or redirect) in seconds:

> *"Which user journey should I prove? Pick whichever you actually care about — one is enough.*
> - *A. "I'm writing markdown and want a link" — open a doc, type prose, hit Cmd-K, see the link snippet appear and tab through placeholders.*
> - *B. "I forgot the shortcut and use the slash menu" — type `/`, see menu, pick `/image`, watch it expand.*
> - *C. "Toolbar follows me as I switch block types" — click a text block, click a calc block, back and forth.*
> - *D. Something else."*

Concrete > abstract. "I'm writing markdown and want a link" beats "test the link insert feature".

**Required only when the journey demands it** (ask only if the planned scenario actually hits this):

- Test credentials — only if the scenario needs login. Reference where to find them, never paste secrets.
- Demo / seed data — only if the scenario needs pre-existing state.
- "Don't touch" list — only if the scenario gets near destructive flows or real-world side effects.

**Don't ask** (derive or ignore):

- App version, OS, browser version — capture these from the environment yourself.
- Project structure or how the code is organized — read the code.
- Multiple journeys when one will get the run started — you can ask for more after you have something running.
- Anything you can already see in `HUMAN_EVIDENCE.md`.

If the launch command and one journey are clear from context, **start the run**. Save anything new the user tells you to `HUMAN_EVIDENCE.md` so the next run doesn't re-ask.

### 2. Preflight — verify tools in one batch, before recording

A permission prompt or "command not found" *mid-recording* corrupts the take. Up front:

- Verify the capture tools you'll use exist (e.g. `npx playwright --version`, `asciinema --version`, `which screencapture`).
- On macOS, test screen recording with `screencapture -V 1 -v /tmp/test.mov` — if the file is a solid black/grey rectangle, Screen Recording permission is missing for the terminal/IDE running you.
- For `computer-use`, call `request_access` for the target app now.
- If you'll need Bash commands not yet allowlisted (`screencapture`, `asciinema`, `npx playwright`, `osascript`), ask the user to add them to `.claude/settings.json` in one batched message. The `update-config` skill can apply this.

**Ask before installing.** If a needed tool is missing, do NOT install it silently. Many capture deps are heavy (Playwright browsers are 200–400 MB; asciinema-player vendoring; ffmpeg). State what's missing and the install size, and ask the user to confirm — or offer a smaller fallback (Chrome MCP instead of Playwright, stills-only instead of video). Especially do not auto-install when the user might prefer a different driver.

If anything's missing, stop and ask. Don't start a partial run, and don't make multi-hundred-MB decisions on the user's behalf.

### 2.5 Launch the app under test

The app must be running and reachable before you start scenarios. Most "the run hung" failures happen here.

**Web app dev servers** (`npm run dev`, `pnpm dev`, `task dev`, vite, next dev, etc.):

- Dev servers stay in foreground by design. Start them with the Bash tool's `run_in_background: true` flag. **Never run them in foreground** — the Bash call will hang waiting for the server to exit, which it never will. **Never use `&` inline** — that backgrounds the shell child but the call still hangs on stdout/stderr.
- After starting, wait for the server to be ready before any driving. Two ways:
  - **Preferred: `Monitor` tool on the background Bash shell.** Tail the dev server's stdout for the "ready" signal it prints (e.g. `Local:` from vite, `compiled successfully` from webpack). This catches readiness the moment it's announced and gives you log visibility for free.
  - **Fallback: poll a health endpoint** in a separate foreground Bash call:

    ```bash
    until curl -sf http://localhost:3000/ > /dev/null 2>&1; do sleep 1; done
    echo READY
    ```

  Be patient. Some dev servers (heavy bundlers, type-checkers, code generators on first run) take 30s–2min to come up. **Slow starts and hangs look identical from outside** — only the logs distinguish them. Watch the bg process logs (Monitor or `BashOutput`) before assuming hang. Stop and surface only on a real error in the log (`EADDRINUSE`, syntax error, missing dep), not on slowness.

**Desktop apps:** Launch the binary, then verify the window is visible via a `computer-use` screenshot before driving. `request_access` for that app first.

**TUIs:** Open a real terminal app via `computer-use`, navigate to the project, run the command. The terminal stays in foreground inside its own app — that's correct.

When in doubt, the rule is: **don't start scenarios on an unreachable app**. A failed health check is not a nuisance; it's a signal something's wrong with the launch path.

### 3. Plan scenarios

Pick **1–5 scenarios** mapping to real user journeys. **Depth beats breadth** — one rich journey that exposes a real product question (typing through a feature the way a curious user would) is better than five shallow click-throughs. State the plan to the user in case they want to redirect.

A scenario should: cover a complete user-visible outcome (not a single click), be repeatable (no irreversible side effects without approval), and take 30–90s at human pace. For each, write a one-line narrative *before* you run it.

### 4. Capture evidence

Pick whatever drives the app, but you choose the *mode*:

- **Web apps — preferred: drive the human's real Chrome via Chrome MCP** (`mcp__claude-in-chrome__*`). This is the *least magical* mode — the human watches their actual everyday browser do the work, can see it happen, can intervene. Capture stills with the MCP's screenshot tool; capture video by recording the visible browser window with `screencapture -V <duration> -v <out.mov>` (macOS) in a separate Bash call. The flakiness tradeoff (DOM-timing, contenteditable surprises) is worth the honesty.
- **Web apps — fallback: Playwright with `headless: false` + visible window + `slowMo` + `recordVideo`.** Only if Chrome MCP isn't connected. Note in the scenario `notes` that you used a Playwright-spawned Chromium, not the human's browser. **Never headless under any circumstance** — that violates contract item 1 outright.
- **Desktop apps (macOS):** `screencapture -V` for video, drive via `computer-use` MCP after `request_access`.
- **TUIs:** `asciinema rec` for the session. Drive a real terminal app.

The preference order for web apps is **honesty before reliability**. A flaky run on the user's real browser is better evidence than a clean run on a sandboxed simulacrum.

Universal rules: **90 seconds max per video. 1280x720 max resolution.** 4–8 still screenshots at key moments. Number them in order (`01-…`, `02-…`).

### 5. Write metadata — action, expected, observed, hypothesis

prove-it is a structured experiment from the human's chair. Each scenario has four signals the viewer renders as numbered steps in this order. **Keep them clean — do not let them bleed into each other.**

1. **Action** (`narrative`) — what you set out to do, in user-journey terms. "From the empty dashboard, opens the New Project modal, names it, picks a template."
2. **Expected** (`expected`) — what you expected to see as a human. The bar you're measuring against.
3. **Observed** (`observed`) — *purely what a human saw on screen.* User-visible signals only. "The chip shifted right ~10px when I switched modes." "I hovered confused for ~600ms after the toast appeared." If it required reading source, opening devtools, or inferring from logs, **it does not belong here.**
4. **Hypothesis** (`hypothesis`, required for `needs-attention` and `fail`) — your causal explanation for what you observed, framed as speculation. May reference code surface ("DescriptorRenderer in the cm6-mirror widget likely doesn't mirror CalcLine.svelte's preview output"), devtools signals ("the POST returned 500 in the network tab"), or whatever you inferred. **Lead with the noun phrase of the suspected cause** so the human can scan it. The viewer renders this prominently with a status-colored heading, and the TUI uses it to phrase the per-finding fix options.

If `observed` reads like a code review or a stack trace, you've crossed the lane line — move that text to `hypothesis` and rewrite `observed` from your eyes.

Schema:

```json
{
  "run_id": "2026-05-02-1432",
  "app": { "name": "acme-app", "version": "0.4.1", "url_or_command": "http://localhost:3000" },
  "environment": { "os": "macOS 15.4", "browser": "Chromium 130 (Playwright)" },
  "scenarios": [
    {
      "slug": "signup-happy-path",
      "title": "New user signs up and lands on dashboard",
      "narrative": "Brand new user fills the form, confirms email, lands on empty dashboard.",
      "status": "pass",
      "expected": "After confirming email, lands on empty dashboard with 'Create your first project' CTA.",
      "observed": "Matches expected.",
      "duration_seconds": 47,
      "video": "assets/signup-happy-path/video.webm",
      "screenshots": [
        { "file": "assets/signup-happy-path/01-landing.png", "caption": "Landing page" }
      ],
      "notes": "Mistyped email once, corrected. MailHog test inbox."
    },
    {
      "slug": "create-first-project",
      "title": "User creates their first project",
      "narrative": "From the empty dashboard, opens New Project modal, names it, picks a template.",
      "status": "needs-attention",
      "expected": "After clicking Create, the modal closes immediately and the project view loads.",
      "observed": "Modal lingered ~600ms after the success toast appeared. I hovered the cursor as if confused before it closed.",
      "hypothesis": "Modal close-on-success isn't tied to the toast event — likely a stale setTimeout or a missing dispatch in the modal's submit handler. Look at NewProjectModal.tsx's onSubmit.",
      "duration_seconds": 38,
      "video": "assets/create-first-project/video.webm",
      "screenshots": [],
      "notes": ""
    }
  ]
}
```

`status`: `pass` | `needs-attention` | `fail`. The viewer renders these as RAG balls with a one-line key.

**The test for which status to assign: did the human complete the journey?**

- `pass` → 🟢 *seems to work* — the human reached the goal and what they saw matched the expected experience.
- `needs-attention` → 🟡 *learning* — the human **reached the goal**, but something was off worth telling someone about: friction, surprise, slow render, awkward copy, an animation that lingers, a recoverable error message they had to react to. They got there. Worth a second look, not blocking.
- `fail` → 🔴 *problem* — the human **didn't reach the goal**: a click did nothing, the wrong page loaded, the app crashed, an unrecoverable error appeared, a silent failure produced the wrong outcome, or the capture itself broke (blank video, missing screenshot — the run is suspect).

Sharper edge cases:
- **Recoverable error** the user fixed and continued past → learning.
- **Silent failure** with a "success" appearance → problem (the appearance lied).
- **Visibly broken UI but the user got the result** → learning.
- **Looks fine but the result is wrong** → problem.
- **App crash mid-scenario** → problem.
- **Capture failure** (broken video, missing screenshot, app crash before recording) → problem; mark `observed` as "couldn't capture: <what happened>" and continue.

For non-pass scenarios, fill `expected`, `observed`, and `hypothesis`.

**`app.name` — what to put here.** Use the most identifiable name for the project being proved. Derivation order:

1. The project's own declaration: `package.json` `name`, `pyproject.toml` `[project] name`, `Cargo.toml` `[package] name`, `go.mod` module path's last segment, etc.
2. The git remote name: `basename -s .git $(git remote get-url origin)` if there's a remote.
3. The git repo's top-level directory name: `basename $(git rev-parse --show-toplevel)`.
4. The current working directory's basename.
5. Whatever the human calls it in `HUMAN_EVIDENCE.md`.

Don't ship the literal string `acme-app` (it's the placeholder example) unless that's actually what the project is called.

### 6. Build the site

The skill ships `templates/site/viewer.html` — a single self-contained HTML file with inline CSS and a tiny inline JS renderer. **No build step. No Python. No Node. No CDN.**

There are **two artifact files** per run, holding the same metadata in two places:

- `current/metadata.json` — canonical, machine-readable. **The agent reads this when the human pastes a permalink back.** Always write/update this first.
- `current/index.html` — the human-facing viewer, with a copy of `metadata.json` injected into its inline `<script type="application/json" id="metadata">` block.

Build steps:

1. Write `<project>/prove-it/current/metadata.json` with the full metadata object.
2. `cp <skill-path>/templates/site/viewer.html <project>/prove-it/current/index.html`.
3. Edit the placeholder JSON block in `index.html` to be a verbatim copy of `metadata.json`. *Both files must stay in sync — when iterating, edit both.*
4. Open `current/index.html` to verify it renders.

The viewer is branded **Prove It** in the UI — when reporting to the user, calling it "the Prove It site" matches what they see. It renders the run as a single overview table (status ball + title, with a Hypothesis sub-row for non-pass scenarios), then stacks scenario detail cards (with numbered steps + video + screenshots) below. Permalinks use a stable scheme — see "Resolving paste-back URLs" below.

### 7. Rotate the archive — fresh runs only

**On a fresh run from scratch**, run `scripts/rotate.sh <project>/prove-it 2` *before* writing the new `current/`. It moves `current/` to `archive/<timestamp>/` and trims the archive to the newest 2 entries. Use the script — do not hand-roll `rm -rf`.

**On iterative refinement** (see "Iterating within a run" below), do **not** rotate. Edit `current/` in place. Rotating between every refinement would fill the 2-archive cap with intermediate states and bury anything useful.

### 8. Report to the user

Final message — keep it tight, the site is the artifact, do not paste large logs:

- One sentence: what you proved.
- For each non-pass scenario, one line: `[status] title — hypothesis: <hypothesis lead>`.
- Anything you couldn't prove and why.
- The paste-back affordance: right-click `#` next to any item, or use the **Copy link** button on the finding card.
- **End with the URL on its own line, ready to click** (see "Always share the URL").

**If anything didn't pass: immediately follow with `AskUserQuestion` listing one option per finding plus the meta-options.** Don't ask the binary loop-back-vs-summary question — that wastes a turn. Each option is named after the hypothesis lead so the human picks the *fix*, not the *finding*. Always include the meta-options last.

```
Question: "What do you want me to address?"
Options (one per non-pass finding, then always these two at the end):
  - Fix: <hypothesis lead from finding 1>
       e.g. "Fix DescriptorRenderer decoration parity in cm6-mirror widget"
  - Fix: <hypothesis lead from finding 2>
  - Investigate further first — I'll add instrumentation or capture more scenarios before guessing
  - Summary only — I'll stop here so you can decide
```

If only one finding, still use the structured question — the per-finding option (named after the hypothesis) is more actionable than "loop back".

## Always share the URL

**Every message that changes `current/`** — first run, refinement, fix, anything — ends with the URL on its own line, ready to click:

```
file:///<absolute-path>/prove-it/current/index.html
```

Or anchored at a specific finding:

```
file:///<absolute-path>/prove-it/current/index.html#fresh-doc-mixed-content
```

Sharing the URL once at run-start and expecting the human to remember it or scroll back is a failure. Re-share every iteration. The URL is the artifact's address; without it the artifact may as well not exist.

## Resolving paste-back URLs

The human's primary paste-back is a permalink + a quick "expected X, this shows Y" note. Your job is to map the permalink back to the original experimental record without making them re-explain the context.

**Permalink scheme (stable):**

```
file:///<project>/prove-it/current/index.html#<slug>             → scenario as a whole
file:///<project>/prove-it/current/index.html#<slug>--video      → that scenario's video
file:///<project>/prove-it/current/index.html#<slug>--shot-NN    → screenshot N (1-indexed, zero-padded)
```

**Lookup flow when a permalink is pasted:**

1. From the URL, derive the project root: everything up to and including `prove-it/current/`.
2. `Read current/metadata.json` (canonical source — do **not** parse `index.html`).
3. Find the scenario whose `slug` matches the part after `#` (strip `--video` / `--shot-NN` first).
4. From that scenario object you now have `narrative`, `expected`, `observed`, `hypothesis`, `notes`, plus the asset paths.
5. If the anchor included `--shot-NN`, look up `scenario.screenshots[N-1]` for the asset path and caption. If `--video`, use `scenario.video`. Read the asset file directly when you need to look at it.
6. Combine the human's "expected X, this shows Y" note with the original `expected`/`observed`/`hypothesis` to decide what to do — usually a sharper hypothesis or a fix.

The metadata.json sidecar is the contract that makes the paste-back loop closed: the human's URL points at a stable record you can always look up, with the experimental context you originally captured intact.

## Iterating within a run

After a first pass, the human often wants to add, refine, or remove scenarios. Treat these as **in-place edits to `current/`, not new runs**:

- **Add**: capture new assets under `current/assets/<new-slug>/`, append the scenario to `current/metadata.json`, then mirror the change into the inline metadata block in `current/index.html`.
- **Refine**: replace assets for that slug, update its entry in `metadata.json` and re-mirror into `index.html`.
- **Remove**: `rm -rf current/assets/<slug>/`, drop the entry from `metadata.json` and from the inline block in `index.html`.

Always update `metadata.json` first; the inline block in `index.html` is a mirror of it. If they ever drift, regenerate `index.html` from `metadata.json` — `metadata.json` wins.

Do **not** rotate the archive between iterations — that fills the 2-archive cap with intermediate states fast. Rotate only on a fresh run-from-scratch.

Re-share the URL at the end of every iteration message.

## Structured questions — use AskUserQuestion

Several decision points are multiple-choice, not open-ended. Use the `AskUserQuestion` tool for these — it gives the human a clean structured pick instead of a paragraph of prose to parse:

- **Which journey to prove** — propose 3–5 concrete options as separate choices, each phrased as a user moment ("I'm writing markdown and want a link", not "test the link feature").
- **Which driver** — Chrome MCP (default, drives your real browser) vs. Playwright (sandboxed Chromium fallback). Skip if `HUMAN_EVIDENCE.md` already records a preference.
- **What to address when findings exist** — one option per non-pass finding (named after its hypothesis lead, e.g. "Fix DescriptorRenderer decoration parity"), plus "Investigate further first" and "Summary only" as the last two options. See section 8.
- **Add / refine / remove a scenario** after the human reviews a run.

Reserve free-text prompts for when the answer truly is open (e.g. "what's the launch command?"). When the choice space is bounded, structure it.

## When something doesn't pass, ASK the human

Capture failure (blank screenshot, broken video, app crash), in-flow misbehavior, or anything surprising — record the partial evidence faithfully, mark the scenario `fail` or `needs-attention`, fill in `expected`, `observed`, **and `hypothesis`**, and **stop.** Then fire the per-finding `AskUserQuestion` from section 8 and wait.

Do not skip, substitute, hand-edit metadata, or "fix it real quick" before reporting. The capture failure is the signal — surfacing it is the job. The hypothesis is *your* contribution — name the suspected cause so the human's pick is informed.

## Disk hygiene

- Soft cap: 500 MB total per project's `prove-it/`. If a run would exceed it, drop video duration, resolution, or scenario count.
- Gitignore `prove-it/current/` and `prove-it/archive/`. Never commit them.
- `prove-it/HUMAN_EVIDENCE.md` is the exception — it is durable and may be committed (with secrets redacted).
- Rotation cap (current + 2 archives) is firm. The script enforces it.

## Anti-patterns

- **Headless. Robot speed. No video.** Violates the contract. The user can't tell what a human would see.
- **Writing assertions instead of exploring.** prove-it is feel-it-out, not scripted.
- **Asking everything up front.** Block only on launch command + one journey. Ask for more only when the scenario demands it.
- **Stacking 5 mistakes per scenario.** Hard cap is 1–2.
- **Working around a capture failure** by skipping, hand-editing, or substituting old assets — and especially **deciding for the human** to "loop back and fix" without asking.
- **Real-world side effects** (real email, real charges, real Slack) without explicit per-scenario approval.
- **Replacing the shipped viewer** with a build-step SPA. It's one HTML file for a reason.

## File layout

In this skill (also `~/.claude/skills/prove-it/` once installed via `git clone`):

```
prove-it/
├── README.md
├── SKILL.md
├── .claude-plugin/plugin.json       # optional plugin manifest
├── scripts/rotate.sh
└── templates/
    ├── HUMAN_EVIDENCE.template.md
    ├── metadata.example.json
    └── site/viewer.html             # self-contained: inline CSS + inline JS renderer
```

In the target project:

```
<project>/prove-it/
├── HUMAN_EVIDENCE.md                 # durable, may be committed
├── current/                          # latest run, gitignored
│   ├── metadata.json                 # canonical record — what the agent reads on paste-back
│   ├── index.html                    # viewer.html with metadata.json mirrored into the inline block
│   └── assets/<scenario-slug>/{video,*.png}
└── archive/                          # last 2 runs, gitignored
    ├── 2026-04-30-1015/
    └── 2026-04-28-0902/
```
