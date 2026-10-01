# Implementation Plan: единый workflow GitHub Spec Kit

**Branch**: `main` | **Date**: 2026-10-01 | **Spec**: [spec.md](spec.md)

## Summary

Оставить Spec Kit единым lifecycle и убрать MASTER/DELTA/LOYALTY как параллельную систему. Актуальную архитектуру сжать в reference doc, открытые направления — в roadmap, детали каждого изменения — в `specs/`.

## Technical Context

**Language/Version**: Markdown; existing Spec Kit 1.0.12.dev0  
**Primary Dependencies**: GitHub Spec Kit Codex integration  
**Storage**: Git repository  
**Testing**: link scan, `rg`, `git diff --check`, `specify integration status`  
**Target Platform**: repository documentation  
**Project Type**: existing iPad POS + backend reference  
**Constraints**: documentation-only; no runtime, Xcode, DB, local-storage or version changes

## Constitution Check

- Offline-first and POS source-of-truth rules remain in constitution and architecture reference.
- No runtime or data-format changes.
- Historical evidence remains in Git and dated audit artifacts.
- Work remains on `main` per the user's established workflow.

## Project Structure

```text
.specify/memory/constitution.md
ROADMAP.md
docs/
├── README.md
├── ARCHITECTURE.md
└── archive/
specs/
├── 001-production-audit/
└── 002-speckit-workflow/
```

## Migration Rules

1. Не переносить в roadmap длинные acceptance-списки.
2. Не переписывать датированные baseline как будто они относились к текущему HEAD.
3. Не хранить текущий task-status в architecture doc.
4. Новую работу начинать с отдельного `specs/NNN-name/`.
