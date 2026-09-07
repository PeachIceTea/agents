---
name: publish-html
description: Use when the user asks to publish, share, host, or get a link for
  an HTML file, page, or report.
---

# Publish HTML to grace

Publish an HTML artifact and return its public URL.

## How to publish

1. Decide what to publish:
   - A single HTML file → pass the file path.
   - A page with assets (CSS/JS/images) → pass the **directory** containing
     them. The script packages it as a tar.gz automatically. Put the entry
     page at `index.html` inside the directory so the link opens directly.
2. Run `grace-upload /path/to/artifact`. The script is in the `./scripts/`
   directory relative to this markdown.

3. The last line of output is the public URL. **Lead your response with that
   URL.**

## Notes

- Keep artifacts self-contained: inline CSS/JS or include them in the
  directory, and reference assets with relative paths (no `../` and no absolute
  paths).
- If the upload fails, surface the error message verbatim (it usually says
  why: bad token, unsupported file type, size limit, unsafe path).
