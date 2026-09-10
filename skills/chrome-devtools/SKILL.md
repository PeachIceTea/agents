---
name: chrome-devtools
description: Use when the user asks to automate, inspect, screenshot, or debug
  a web page in Chrome, or mentions the chrome-devtools CLI / chrome-devtools-mcp.
  Connects the CLI to the user's running Flatpak Chrome.
---

# Chrome DevTools CLI

The `chrome-devtools` CLI (from `chrome-devtools-mcp`, installed globally) drives
a real Chrome. On this machine the target is the user's Flatpak Chrome,
connected over its remote debugging websocket.

## Connect

1. The user must enable remote debugging in Chrome: open
   `chrome://inspect/#remote-debugging` and check the toggle.
2. Run `./scripts/cdm-connect.sh` (relative to this markdown). It handles the
   endpoint resolution for you — **don't build the websocket URL by hand**.
3. Verify with `chrome-devtools list_pages` — it should show the user's actual
   open tabs. If it errors with a missing `DevToolsActivePort`, go back to
   step 1.

## Using the CLI

Page-scoped tools take the page number as first argument:

```sh
chrome-devtools list_pages
chrome-devtools new_page "https://example.com" [--background] [--isolatedContext name]
chrome-devtools close_page 1
chrome-devtools navigate_page 1 --url "https://example.com"
chrome-devtools take_screenshot 1 --filePath out.png
chrome-devtools evaluate_script "() => document.title" --pageId 1
chrome-devtools click 1 <element-uid>
```

Tab management: `new_page <url>` opens a tab (add `--background` to open without
focusing it); `close_page <pageId>` closes one — but never the last open page.
`close_page` takes the index from `list_pages`, which shifts after opening or
closing tabs, so re-list before closing if you do several tab operations.

`--output-format=json` for programmatic parsing. Full tool list:
`chrome-devtools --help`.

Prefer `take_snapshot 1` over `take_screenshot` when you just need to see or
interact with the page: the snapshot returns the accessibility tree with
`element-uid`s you can pass to `click`, `fill`, etc., and it's much cheaper
for the model to read than an image. Reach for `take_screenshot` only when the
user actually wants an image, or when the snapshot doesn't reveal something
visual (layout, styling, rendering artifacts).

## Shutdown

Shutdown the MCP daemon only on user request. If the user requests: use
`chrome-devtools stop` will stop the MCP daemon. Chrome keeps running normally.

## Notes

- The websocket UUID changes on every Chrome restart — the connect script
  re-reads it, so just re-run it. Never reuse a stale endpoint.
- Don't try `--autoConnect`, `--browserUrl`, or `--userDataDir` against the
  Flatpak Chrome; they don't work here. If the script fails for a new reason,
  read its error message before debugging further.
- Without a Flatpak connection (headless/blank-profile work), the fallback is
  `chrome-devtools start -e /usr/bin/chromium-browser`.
