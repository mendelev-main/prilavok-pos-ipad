# Матрица покрытия аудита M POS 130.52

| Область | Что проверено | Доказательство | Результат |
|---|---|---|---|
| Xcode/package | target resources, build phases, Info.plist, version stamp | simulator build и built bundle | PASS с 2 предупреждениями проекта |
| Startup/storage | adapter, prefix, loadAll, journal recovery, shape validation | code review + diagnostics | A003-F04 |
| Текущий заказ | session save/restore, park/resume, WEB context | tests + injected write failure | A003-F01 |
| Оплата | cash/card/split, double action, receipt, stock snapshot | Node tests | PASS |
| Рецептуры/остатки | nested components, modifiers, shortage, units, rounding | Node tests | PASS |
| Возвраты | receipt state, stock restore, cash movement, loyalty reversal | Node tests | PASS |
| Смены/касса | open, movement, close, reports, invalid amount | review + diagnostics | A003-F02, F05 |
| Товары | editor lifecycle/dirty state, local-first persistence/photo runtime, units, recipes, modifiers, safe catalog/configuration IDs, cost protection, imports, dependencies | tests + review | PASS after specs 042–045; A003-F07/F24/F25 fixed |
| Закупки | supplier order creation/deletion, storage-first, presentation result, safe legacy IDs, history | review + tests | PASS after specs 010/038; A003-F11, F19/F20 fixed |
| Приёмка | draft open/save/retry, UI/editor/history, validation, weighted cost, global critical guard, commit/recovery, safe legacy quantity | Node tests | PASS after specs 036–039; A003-F17/F18/F21 fixed |
| Инвентаризация | draft, fix, complete, history/config writes | injected write failure | A003-F03 |
| Backup | schema validation, versions 1–12, malformed optional sections, journal recovery, legacy data, printer settings | Node tests | PASS after spec 040; A003-F22 fixed |
| Сотрудники | create/edit/delete, self-delete, admin delete, storage failure, rights | tests + review | PASS after spec 034; A003-F10 for credential model; A003-F15 fixed |
| Поставщики | create/edit/delete, product links, storage failure, historical snapshots | tests + review | PASS after spec 035; A003-F16 fixed |
| Навигация POS | category/folder layout, drag/drop, legacy normalization | Node tests | PASS |
| WEB-заказы | SSE normalization, local-first accept, ACK/retry, ETA | Node tests + review | PASS; A003-F14 legacy edge |
| Лояльность | search, rewards, offline sale, ordered retry/reversal, safe backend IDs/names, module boundary | tests + review | PASS after specs 008/041; A003-F06/F23 fixed |
| Availability/outbox | 10-minute schedule, timeout, revision, persisted source | Node tests | PASS |
| Network boundaries | fetch timeouts, retry, background/foreground | static review | A003-F06, F07, F14 |
| LAN-печать | bridge payload, NWConnection lifecycle, parallel state | Swift review | A003-F08; device test required |
| Native lifecycle | AppDelegate/SceneDelegate, handlers, callbacks | Swift review + analyzer | A003-F09, F12 |
| PDF/XLSX | generators, pagination, report payload, temp files | code review + tests | static PASS; visual device test required |
| Telegram | settings, open/close delivery order, URLSession timeout | code review | shift false-success covered by F02 |
| JS syntax | inline scripts, adapter, printer and notification bridge | Node parse/check | PASS |
| Swift static analysis | application, print manager, reports | `xcodebuild analyze` | PASS |

`PASS` здесь означает отсутствие найденного дефекта в проверенном объёме. Физические сценарии из
[ipad-checklist.md](ipad-checklist.md) остаются обязательными перед production acceptance.
