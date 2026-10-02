# Implementation Plan: проверка лояльности перед split-оплатой

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Route new split-payment creation through the existing loyalty validation boundary, make offline
continuation explicit and testable, and prevent duplicate validation requests.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView
**Storage**: unchanged; durable draft from spec 029 remains authoritative after first paid part
**Network**: existing bounded loyalty request only
**Testing**: Node.js 22 `node:test`; Xcode Simulator build
**Constraints**: no new endpoint, timer, sync, key, version or project-file change

## Constitution Check

- Network failure still permits a local sale without the unconfirmed gift.
- Validation occurs before money acceptance and does not mutate durable drafts.
- No automatic synchronization is introduced.

