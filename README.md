# prove-it

A Claude Code skill that proves an interactive UI works by **driving it at a human pace** through a real environment — a real browser, a real terminal, a real launchable app — and producing a self-contained static evidence site the human reviewer can open and scrub through.

> "I ran all the tests. Now let me prove a human will have the experience you expect."

## Why

Unit tests, component tests, and end-to-end suites (Playwright, Puppeteer, Videotape for BubbleTea, etc.) prove **code correctness**. They run at machine speed, in sandboxed environments, and produce pass/fail signals.

They do not tell the story of a **human** using the app. The agent that just shipped a feature has the best context to demonstrate it, but only if it does so the way a careful human would: at human pace, in a real environment, with the occasional small mistake and recovery, capturing visual evidence the user can believe.

That is what this skill is for.

## When the skill triggers

The skill is invoked when:

- The user explicitly says "prove to me that this is working", "show me it works", "demo this end to end", "verify the UX", or similar.
- The agent has just finished a significant chunk of UI / UX work and tests pass — at that point the agent should proactively offer or run this skill before declaring the task done.

It does **not** replace tests. It runs after them, on the same change.

## What it produces

A directory at `<project>/prove-it/current/` with a self-contained `index.html`. Open it in any browser via `file://`. It contains:

- A timeline of 2–5 user-journey scenarios.
- For each scenario: a short narrative, key screenshots, and a short video.
- Pass / needs-attention / fail status per scenario and overall.
- Environment metadata (OS, browser, app version).

The previous two runs are kept under `<project>/prove-it/archive/<timestamp>/`. Anything older is pruned automatically. `prove-it/current/` and `prove-it/archive/` are gitignored; only `HUMAN_EVIDENCE.md` is durable across runs.

## Install

### As a Claude Code plugin

Clone or symlink this repo into your Claude Code plugins directory, or reference it in your plugin marketplace configuration. The skill exposes itself as `prove-it`.

### Standalone

Copy `skills/prove-it/` into your project's `.claude/skills/` directory. The skill will be available in that project.

## Files

```
prove-it/
├── README.md                          # this file
├── .claude-plugin/plugin.json         # plugin manifest
└── skills/prove-it/
    ├── SKILL.md                       # the skill itself — what the agent reads
    ├── scripts/
    │   └── rotate.sh                  # archive rotation (current + 2)
    └── templates/
        ├── HUMAN_EVIDENCE.template.md # starter for per-project context
        ├── metadata.example.json      # schema reference
        └── site/
            └── viewer.html            # self-contained viewer: inline CSS + tiny inline JS renderer
```

### How the site is built

There is no build step. The agent:

1. Copies `templates/site/viewer.html` to `<project>/prove-it/current/index.html`.
2. Replaces the placeholder JSON inside the `<script type="application/json" id="metadata">…</script>` block with the run's real metadata.

That's it. No Python, no Node, no static-site generator. The viewer reads its data from the inline `<script>` block and renders client-side. Open it via `file://` in any browser.

## License

MIT
