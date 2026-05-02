---
name: prove-it
description: Use this skill to prove an interactive UI works the way a human would experience it — exploratory verification, not scripted testing. Trigger PROACTIVELY whenever you have just finished a significant chunk of UI/UX work (new screen, non-trivial flow change, redesign, user-visible bug fix) and tests pass — passing tests prove code correctness, not human experience. Also trigger on explicit asks like "prove to me that this is working", "show me it works", "demo this end to end", "verify the UX". Skip for backend-only changes, trivial copy/color tweaks, or in-development sanity checks. The skill forces you to drive the app at human pace in a real, visible environment (browser window, real terminal, launched app — never headless), capture video and screenshots of realistic interactions including 1–2 small human-style mistakes per scenario, and produce a self-contained static evidence site (the "Proof" viewer) the human opens in a browser. Every scenario, video, and screenshot has a stable permalink so the human can paste a link back with "I expected X here, this shows Y". When something doesn't pass — capture failure or in-flow misbehavior — record faithful evidence and ASK the human whether to loop back and fix, or stop with a summary. Do not assume.
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

3. **Show your work to the human.** Produce the Proof viewer and verify it opens. The human reviews video and stills to confirm you actually behaved like a human. If the videos look robotic, you failed the contract — even if the app worked.

## Quirky human mistakes — sparingly

Hard cap: **1–2 small recoveries per scenario.** Pick from: typo + backspace, wrong adjacent field click + retry, submit-without-required-field + see-error + fix, wrong nav link + back. Avoid mistakes in destructive flows, mistakes that surface unrelated bugs, mistakes in payment/auth, and stacking mistakes. More than that and the app looks broken.

## Workflow

### 1. Gather context

Read the conversation. Check `<project>/prove-it/HUMAN_EVIDENCE.md` if it exists — it has durable answers from prior runs.

Then ask only what you actually need. Do NOT collect everything up front "just in case".

**Truly required to start a run** (block on these — ask if missing):

- How do I launch the app? (command, port, URL, or app path)
- At least one user journey to prove. *One* is enough — you can always do more.

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

If anything's missing, stop and ask. Don't start a partial run.

### 3. Plan scenarios

Pick 2–5 scenarios mapping to real user journeys. For each, write a one-line narrative *before* you run it. State the plan to the user in case they want to redirect.

A scenario should: cover a complete user-visible outcome (not a single click), be repeatable (no irreversible side effects without approval), and take 30–90s at human pace.

### 4. Capture evidence

Pick whatever drives the app, but you choose the *mode*:

- **Web apps:** Playwright with `slowMo` + `recordVideo` + visible browser is the cleanest. The Chrome MCP gives stills but no continuous video — note that limitation in scenario notes if you fall back to it. Never headless.
- **Desktop apps (macOS):** `screencapture -V` for video, drive via `computer-use` MCP after `request_access`.
- **TUIs:** `asciinema rec` for the session. Drive a real terminal app.

Universal rules: **90 seconds max per video. 1280x720 max resolution.** 4–8 still screenshots at key moments. Number them in order (`01-…`, `02-…`).

### 5. Write metadata

Build a metadata object the viewer will render. Schema:

```json
{
  "run_id": "2026-05-02-1432",
  "app": { "name": "showme", "version": "0.4.1", "url_or_command": "http://localhost:3000" },
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
    }
  ]
}
```

`status`: `pass` | `needs-attention` | `fail`. Always fill `expected` and `observed` for non-pass scenarios. The viewer renders them side-by-side.

### 6. Build the site

The skill ships `templates/site/viewer.html` — a single self-contained HTML file with inline CSS and a tiny inline JS renderer. **No build step. No Python. No Node. No CDN.**

1. `cp <skill-path>/templates/site/viewer.html <project>/prove-it/current/index.html`
2. Replace the placeholder JSON inside `<script type="application/json" id="metadata">…</script>` with your real metadata (use the Edit tool — that block is the only thing you change).
3. Open `current/index.html` to verify it renders.

The viewer is branded **Proof** in the UI — when reporting to the user, calling it "the Proof site" matches what they see. It renders a Table of Contents at the top (one row per scenario, with status pill + title + duration), then stacks scenarios as cards. Permalinks (`#slug`, `#slug--video`, `#slug--shot-NN`) jump to the right anchor with smooth scrolling and a brief highlight.

### 7. Rotate the archive

**Before** writing the new `current/`, run `scripts/rotate.sh <project>/prove-it 2`. It moves `current/` to `archive/<timestamp>/` and trims the archive to the newest 2 entries. Use the script — do not hand-roll `rm -rf`.

### 8. Report to the user

Final message:

- One sentence: what you proved.
- Path: `prove-it/current/index.html`.
- Any non-pass scenarios, called out explicitly.
- Anything you couldn't prove and why.
- If anything didn't pass: the viewer's bottom block asks them to choose **loop back** (you fix and re-run) or **summary only** (you stop). Wait for their answer.
- The paste-back affordance: right-click `#` next to any item, copy link, paste with "expected X, this shows Y". You'll act on pinpoint feedback.

Don't paste large logs. The site is the artifact.

## When something doesn't pass, ASK the human

Capture failure (blank screenshot, broken video, app crash), in-flow misbehavior, or anything surprising — record the partial evidence faithfully, mark the scenario `fail` or `needs-attention`, fill in `expected` and `observed`, and **stop.** The viewer's bottom block asks the human to choose loop-back or summary. Wait for their answer.

Do not skip, substitute, hand-edit metadata, or "fix it real quick" before reporting. The capture failure is the signal — surfacing it is the job.

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

In this skill:

```
prove-it/
├── README.md
├── .claude-plugin/plugin.json
└── skills/prove-it/
    ├── SKILL.md
    ├── scripts/rotate.sh
    └── templates/
        ├── HUMAN_EVIDENCE.template.md
        ├── metadata.example.json
        └── site/viewer.html         # self-contained: inline CSS + inline JS renderer
```

In the target project:

```
<project>/prove-it/
├── HUMAN_EVIDENCE.md                 # durable, may be committed
├── current/                          # latest run, gitignored
│   ├── index.html                    # viewer.html with metadata injected
│   └── assets/<scenario-slug>/{video,*.png}
└── archive/                          # last 2 runs, gitignored
    ├── 2026-04-30-1015/
    └── 2026-04-28-0902/
```
