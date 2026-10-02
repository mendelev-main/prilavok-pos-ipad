# Feature Specification: Design system automated closure

**Roadmap**: R12

**Baseline**: M POS 130.54

**Date**: 2026-10-02

## Goal

Завершить автоматизированную часть унификации интерфейса: удалить последние статические runtime styles и закрепить исчерпывающий контракт для значений, которые обязаны вычисляться из данных или жеста.

## Requirements

1. Toast и невидимый clipboard fallback используют именованные CSS classes.
2. Живой поиск плиток использует `hidden`, а не прямую запись `style.display`.
3. Ровно семь оставшихся inline style attributes перечислены автоматическим тестом.
4. Inline values разрешены только для ширины графика, координат/поворота стола, цвета категории и позиции плитки.
5. Runtime mutations разрешены только для свайпа корзины, drag-and-drop плиток и перемещения стола.
6. Storage, JSON, POS calculations, network behavior and UI flows не меняются.
7. Полная regression matrix и simulator build проходят.

## Success criteria

- Production не содержит `style.cssText` и статических `.style.position`, `.style.opacity`, `.style.display`.
- Любой новый inline attribute ломает design regression test до явного документирования.
- R12 получает статус automated acceptance complete; physical iPad остаётся отдельной финальной проверкой.

## Out of scope

- Замена data-driven geometry на набор заранее известных CSS classes.
- Изменение drag, swipe, hall map или analytics behavior.
- Физическая проверка iPad в рамках этого этапа.
