# Implementation Plan: модуль представления текущего заказа

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Перенести contiguous block от `renderCartPanel` до настроек заказа в classic feature script.
Оставить добавление товаров, остатки, парковку, оплату, чек и печать inline.

## Technical Context

**Language/Version**: Swift 5, HTML/CSS, JavaScript ES2020
**Dependencies**: existing cart/session/loyalty/modal helpers
**Storage**: unchanged `currentOrderSession` facade
**Testing**: Node.js 22 `node:test`; Xcode simulator build
**Target**: iPadOS 16+
**Constraints**: exact data/UI/behavior compatibility

## Constitution Check

- Sale and payment critical paths remain untouched.
- Existing local session persistence is retained.
- No network or sync trigger is added.
- One narrow component is moved byte-for-byte.
