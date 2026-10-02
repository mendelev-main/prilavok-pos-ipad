# Results: модуль каталога товаров

**Baseline**: `c0b2a46` · **Version**: 130.52 · **Date**: 2026-10-02

## Реализованный срез

- CSV parsing/planning/confirmation, поиск, сортировка, таблица и live filtering перенесены из
  `pos.html` в `Web/js/features/product-catalog.js`.
- Категории, product editor, recipes, deletion, рабочая зона и касса остались за границей этапа.
- Публичный глобальный API и загрузка до `loadAll()` сохранены.
- `pos.html` уменьшен с 5970 до 5774 строк; второй домен в этап не включён.

## Совместимость

- Production-блок перенесён побайтно, без изменения UI и поведения.
- Используются прежние key `products`, prefix `prilavok_`, поля и defaults; миграции нет.
- Импорт остаётся additive и публикует state только после успешной локальной записи.
- Поиск и сортировка не изменяют persisted-массив; сеть не добавлена.
- Версия остаётся 130.52; `project.pbxproj` не изменялся.

## Автоматизированные проверки

- Production-код перенесён байт-в-байт: PASS.
- JavaScript syntax и runtime load-order/public API: PASS.
- Product catalog scenarios: PASS, 13/13, включая 12 прежних regression-тестов.
- Полный Node suite: PASS, 218/218.
- Debug Simulator build without signing: `BUILD SUCCEEDED`.
- Собранный `.app` содержит `Web/js/features/product-catalog.js` с идентичным SHA-256.

Физическая проверка CSV picker/preview/confirm, поиска, сортировки и открытия карточки остаётся в
общем финальном ручном прогоне.
