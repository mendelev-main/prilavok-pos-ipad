# Prilavok POS Architecture Direction

## Goal

Transform the current project into a stable offline-first POS architecture while preserving existing functionality.

## Current architecture

Swift iPad application hosts the POS interface through WebView.

## Target architecture

```
Swift iPad App
      |
      |
Web UI
      |
Business modules
      |
Local storage (source of truth)
      |
Sync layer
      |
Backend / Web
```

## Refactoring principles

- No large rewrites.
- Move functionality gradually.
- Test after every structural change.
- Keep iPad installation and operation stable.

## Data rules

Local POS storage is authoritative.

Internet availability is optional. The POS must be able to:

- sell products;
- store receipts;
- manage shifts;
- print receipts;
- continue operation offline.

Synchronization should propagate POS changes outward without replacing local truth.
