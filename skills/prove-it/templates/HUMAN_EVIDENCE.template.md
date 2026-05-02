# HUMAN_EVIDENCE.md

Durable context for the `prove-it` skill. Edit freely. Keep it short — bullets, not paragraphs.

This file is **safe to commit** to source control. Never put live secrets here; reference where to find them.

## App

- Name:
- Type: <!-- web | desktop | tui -->
- Repo / source path:
- Version or branch usually proven:

## Launch

<!-- One block per environment. Whichever the agent should use by default goes first. -->

```
# example: web app
pnpm dev
# serves on http://localhost:3000
```

## Test credentials

<!-- Reference how to obtain them; do NOT paste real secrets. -->

- Test user: `tester@example.com` / password in 1Password vault "Engineering Test Accounts"
- Admin user:

## Demo / seed data

- How to seed:
- What's expected to be in the seeded state:

## Important user journeys

<!-- The 2–5 things that, if working, mean the app is working. -->

1.
2.
3.

## Capture preferences

<!-- Default: drive the user's real Chrome via Chrome MCP (least magical). Override here only if needed. -->

- Driver: <!-- e.g. "Chrome MCP preferred (default)" or "Playwright OK" or "Playwright required because <reason>" -->
- Viewport: <!-- e.g. 1280x720; that's the default -->
- Video: <!-- yes | stills only -->
- Other:

## Do NOT touch

<!-- Anything destructive, anything with real-world side effects. -->

- Real outbound email — use MailHog at http://localhost:8025
- Payments — use Stripe test mode only
-

## Known quirks the agent should not flag as bugs

-

## Notes

-
