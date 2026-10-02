# Research: модуль складской аналитики

## Решение 1: единая граница расчёта, страницы и export preparation

**Decision**: Перенести блок от `warehouseRange` до `exportWarehousePDF` целиком.

**Rationale**: Эти функции используют одну read-only модель отчёта и один UI. Общая аналитика до
блока и loyalty analytics после него являются отдельными доменами.

**Alternatives considered**: Разделить calculation и UI сейчас отклонено, поскольку создало бы две
новые границы за один этап и потребовало дополнительного публичного API.

## Решение 2: Telegram transport остаётся с Telegram

**Decision**: `maybeSendMonthlyWarehouseReport` остаётся в `pos.html`, используя публичные
`warehouseReport` и `warehouseExportPayload`.

**Rationale**: Формирование данных принадлежит отчёту; расписание, настройки и отправка принадлежат
Telegram-интеграции. Существующая зависимость сохраняется без переноса второго домена.

## Решение 3: native renderer не меняется

**Decision**: Сохранить actions `shareWarehouseReport` и `shareWarehouseExcel` и прежний payload.

**Rationale**: Swift PDF/XLSX generators уже проверены и не требуют изменений для перемещения JS.

## Решение 4: read-only контракт проверяется production-тестами

**Decision**: Fixture исполняет `warehouse-reporting.js`; существующие тесты продолжают сравнивать
расчёты и подтверждать отсутствие storage writes.

**Rationale**: Это предотвращает расхождение отдельного модуля с тестовой копией алгоритма.

## Решение 5: сохранить классический script API

**Decision**: Подключить компонент до `loadAll()` без переименования функций.

**Rationale**: Настройки, Telegram и inline UI используют глобальные вызовы. Их изменение относится к
будущей миграции UI-границ.
