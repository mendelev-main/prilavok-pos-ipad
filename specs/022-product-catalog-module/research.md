# Research: модуль каталога товаров

## Решение 1: каталог заканчивается перед управлением категориями

**Decision**: Перенести import, search, sort, table render и live filtering от
`cleanImportedProductName()` до `clearProductsSearch()`.

**Rationale**: Это один экранный контур. Category CRUD меняет layout и navigation и должен остаться
отдельным будущим срезом.

**Alternatives considered**: Включить категории — расширяет storage boundary; включить product editor —
слишком большой этап с фото, recipes, units и deletion.

## Решение 2: сохранить прямой storage adapter import

**Decision**: Оставить `PrilavokCore.Storage.set('products', next)` без изменения.

**Rationale**: Текущая последовательность гарантирует локальную запись до публикации state и уже
проверена failure tests.

**Alternatives considered**: Перейти на facade или journal — отдельное изменение поведения и safety design.

## Решение 3: использовать существующую regression suite

**Decision**: Исполнять `product-catalog.js` в общей VM fixture, сохранить 12 существующих catalog
тестов и добавить public API/load-order contract.

**Rationale**: Покрытие уже проверяет parser edge cases, compatibility defaults, storage failure,
concurrency, Unicode search и presentation-only sorting.
