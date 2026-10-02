# Research: модуль категорий товаров

## Решение 1: закончить границу перед shared deletion

**Decision**: Перенести функции от `openCategoriesModal()` до `deleteCategory()`, оставив
`requestDelete()` и `confirmDelete()` в основном runtime.

**Rationale**: Shared confirmation также удаляет товары и зависит от receipt/recipe protection.

**Alternatives considered**: Перенести shared deletion — расширяет срез до product lifecycle; оставить
`deleteCategory()` — разделяет category API без выгоды.

## Решение 2: сохранить legacy multi-write sequence

**Decision**: Не заменять текущие `saveKey` вызовы journal в этом этапе.

**Rationale**: Цель этапа — архитектурный перенос без изменения поведения или recovery semantics.
Атомарность заслуживает отдельной спецификации и failure tests.

## Решение 3: добавить прямые domain tests

**Decision**: Помимо load-order test проверить create/rename references, Unicode symbol и guarded delete.

**Rationale**: До этапа категории покрывались только косвенно тестами каталога, навигации и удаления.
