# Runtime boundary: warehouse reporting

## Provided global API

- `warehouseRange(from, to)` и `warehousePreset(preset)`
- `warehouseReport(from, to, now)`
- `warehouseNumber(value)`, `warehouseQuantityTotals(report, key)`, `warehouseNotes(report)`
- `warehouseSimpleSection(report)`, `warehouseExportPayload(report, documentsOnly)`
- `openWarehousePage()`, `closeWarehousePage()`, `applyWarehouseDates()`
- `renderWarehouseTable(section)`, `renderWarehousePage()`, `openWarehouseReportModal()`
- `warehouseSelectedPayload(report, selected)`
- `generateWarehouseReport()`, `exportWarehousePDF(documentsOnly)`

## Consumed runtime API

Компонент читает `state.products`, `state.receivings`, `state.orders`, `state.company`, currency и
использует существующие product/unit/date/money, admin, DOM, modal, flash и native bridge helpers.

`pos.html` загружает компонент после объявления зависимостей и до `loadAll()`.

## Native export contract

- PDF action: `shareWarehouseReport`.
- Excel action: `shareWarehouseExcel`.
- Payload сохраняет `title`, `period`, `generatedAt`, `company`, `notes`, `sections`.
- Excel rows retain numeric values for numeric cells.

## Read-only and failure contract

- Расчёт и подготовка payload не выполняют storage writes.
- Некорректный период, формат или пустой набор секций блокируют export.
- Отсутствующий native bridge показывает прежнее сообщение и не изменяет данные.
- Telegram может вызывать публичный calculation/payload API без изменения transport-логики.
