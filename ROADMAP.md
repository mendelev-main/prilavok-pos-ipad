# M POS Roadmap

Этот файл задаёт порядок крупных направлений. Он не содержит детальных требований и task-status: перед началом каждого среза создаётся отдельный `specs/NNN-name/`.

**Статусы**: planned · in-progress · done

| ID | Направление | Цель и граница | Зависит от | Статус | Sub-spec |
|---|---|---|---|---|---|
| R1 | Production acceptance 130.52 | Пройти полный code-аудит и физическую матрицу iPad, LAN-печать, WEB/Telegram, PDF/XLSX, backup и loyalty; закрыть подтверждённые риски отдельными fixes | — | in-progress | [003 audit](specs/003-ipad-production-audit/spec.md) · [004 parked](specs/004-parked-order-atomicity/spec.md) · [005 shifts](specs/005-shift-storage-safety/spec.md) · [006 inventory](specs/006-inventory-atomicity/spec.md) · [007 startup](specs/007-storage-shape-recovery/spec.md) · [008 loyalty timeout](specs/008-loyalty-request-timeout/spec.md) · [009 printer lifecycle](specs/009-network-printer-lifecycle/spec.md) · [010 purchase orders](specs/010-purchase-order-atomicity/spec.md) |
| R2 | Единая техническая версия | Убрать ручное дублирование Debug/Release/UI и оставить один build-time source | R1 | planned | — |
| R3 | Local-first фото товара | Сохранять карточку и фото локально; upload делать отдельной явной сетевой операцией | R1 | automated acceptance complete; device deferred | [011 photos](specs/011-local-first-product-photos/spec.md) |
| R4 | Граница входящих WEB-заказов | Изолировать EventSource/ACK от manual POS→backend sync и закрепить границу тестами | R1 | planned | — |
| R5 | Единый scene lifecycle | Создавать окно и POS-контроллер ровно в одном месте | R1 | automated acceptance complete; device deferred | [012 lifecycle](specs/012-single-scene-lifecycle/spec.md) |
| R6 | Immutable stock ledger | Хранить новые складские движения как неизменяемые события, не выдумывая историю для старых данных | R1 | planned | — |
| R7 | Регрессия native bridge и печати | Покрыть payload/routing/copies/comments/reprint автотестами; raster и LAN остаются physical checks | R1 | planned | — |
| R8 | Постепенная модульная миграция | Выносить из `pos.html` по одному домену без изменения storage, UI и lifecycle | R1, R7 | planned | — |
| R9 | Аудит кода и схемы БД | Удалять только доказанно неиспользуемое; каждую миграцию выполнять отдельно с rollback-планом | R1 | planned | — |
| R10 | Локальный OCR приёмки | Apple Vision OCR → parser → catalog matching → редактируемый draft; без сети и без автопроводки | R1, R6 | planned | — |
| R11 | Documentation workflow | Перейти на Constitution → Roadmap → feature specs без MASTER/DELTA | — | done | [002-speckit-workflow](specs/002-speckit-workflow/spec.md) |

## Правила обновления

1. Статус или порядок срезов меняется здесь.
2. Требования, edge cases, acceptance и задачи хранятся только в sub-spec.
3. Новый sub-spec ссылается на ID roadmap; roadmap после этого получает обратную ссылку.
4. Завершённый feature не удаляется: его каталог остаётся flow-forward историей.
