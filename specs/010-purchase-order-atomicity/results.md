# Results: атомарные заказы поставщикам

**Baseline**: `953e402` · **Version**: 130.52 · **Date**: 2026-10-01

## Изменение

- Создание заказа формирует снимки `products` и `purchaseOrders`, сохраняет их одним journal и
  очищает форму только после commit.
- Административное удаление формирует снимки `purchaseOrders` и `receivings`, сохраняет удалённый
  статус и аудиторскую строку одной операцией.
- Повторное действие блокируется общей защитой критической операции.
- Ключи, JSON-структуры, расчёт закупочного количества и UI не изменены.

## Автоматизированные проверки

- Node suite: PASS, 191/191.
- Новые create/delete success, failure and recovery tests: PASS, 6/6.
- Inline JavaScript и storage adapter parse: PASS.
- Native bridge JavaScript `node --check`: PASS.
- Debug Simulator build без signing: `BUILD SUCCEEDED`.
- `project.pbxproj` и версия 130.52 не изменены.

Ручные сценарии заказов и приёмки остаются в общем
[iPad checklist](../003-ipad-production-audit/ipad-checklist.md#5-склад-товары-и-документы--p0p1)
и выполняются в финальном прогоне.
