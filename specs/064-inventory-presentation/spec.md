# Feature Specification: Inventory presentation

**Roadmap**: R12

**Baseline**: M POS 130.54

**Date**: 2026-10-02

## Goal

Стандартизировать настройки и рабочий экран инвентаризации без изменения атомарной коррекции остатков, черновика и истории.

## Requirements

1. `inventory.js` не содержит inline style attributes или `style.display` mutations.
2. Поиск товаров скрывает несовпадающие строки через `hidden` и не меняет выбор.
3. Настройки графика, товары и история используют именованные presentation classes.
4. Рабочие строки, ввод остатка, зафиксированное состояние и действия адаптируются к доступной ширине.
5. Недостача, излишек и отсутствие расхождения используют семантические classes и design tokens.
6. Сводка и отмена инвентаризации используют общие modal patterns.
7. Storage keys, JSON, calculations, critical journal, availability publication and permissions не меняются.
8. Полная автоматизированная матрица и simulator build проходят.

## Success criteria

- В `inventory.js` остаётся 0 inline style attributes.
- Настройки, рабочий экран и сводка читаемы в обеих темах.
- Существующие inventory failure/recovery, backup and stock tests проходят.

## Out of scope

- Изменение графика и правил доступа.
- Изменение расчёта расхождения или убытка.
- Изменение формата локальных данных.
