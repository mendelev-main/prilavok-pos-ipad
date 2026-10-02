# Implementation Plan

1. Расширить существующий объект `layout` двумя картами boolean, сохранив `categoryOnline` как совместимый фасад.
2. Добавить два переключателя в список и редактор категорий.
3. Обновить backup import/export и все записи layout.
4. Передать оба признака категории в текущем payload ручной синхронизации.
5. Добавить backend migration, безопасный fallback и раздельную фильтрацию `/api/menu`.
6. Проверить legacy layout, независимость каналов, миграцию, regression suites и сборку.
