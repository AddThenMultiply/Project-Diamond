# Tools

Small scripts that keep the single-file pages consistent and prove they work. No build step: every page stays self-contained; these only regenerate shared fragments and run checks.

| Script | What it does | Run |
|---|---|---|
| `nav.py` | Regenerates the header nav and the footer (links, Privacy, legal line) on every public page from one list. Run it after adding a page or changing the nav. | `python3 tools/nav.py` |
| `check.py` | Link check (including links built in scripts), single `BOOKING_URL` per page, UK spelling scan, storage mentions. | `python3 tools/check.py` |
| `report-test.js` | Runs every scoring harness (`runTests()`) in headless Chromium, then drives each assessment end to end: answers, score, band, written report, copy summary, print stylesheet, booking parameters. Screenshots and a PDF land in `tools/out/`. | `PW=$(npm root -g)/playwright node tools/report-test.js` |
| `qa-test.js` | Pre-launch pass: mobile at 360px and 375px, keyboard, validation messages, recovery when the database is unreachable, redirects, booking hand-off, consent and privacy presence. Results in `tools/out/qa-results.json`. | `PW=$(npm root -g)/playwright node tools/qa-test.js` |
| `keyboard-gate-test.js` | Keyboard-only completion of the four gated instruments, timing the report after Enter. | `PW=$(npm root -g)/playwright node tools/keyboard-gate-test.js` |

Playwright is expected as a global install with Chromium available; set `PW` to its module path. Nothing here runs in the browser of a visitor and nothing is deployed.
