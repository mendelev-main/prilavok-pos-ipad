# Results: событийная публикация остатков

## Outcome

- Удалён десятиминутный availability scheduler и его launch/foreground/visibility behavior.
- Прежний snapshot builder и `POST /api/availability/snapshot` выделены в
  `PrilavokPOS/Web/js/features/availability.js` без изменения endpoint, headers или payload.
- После устойчивого local commit оплатa, возврат, приёмка, фиксация/завершение инвентаризации и
  сохранение товара запускают `void publishAvailability()` и не ожидают сеть.
- Одновременные изменения coalesce: после активного запроса модуль повторно читает persisted
  `products` и отправляет самый новый snapshot.
- Ошибка сети не создаёт timer/reconnect retry. Следующая попытка появляется при новом складском
  изменении или успешной ручной синхронизации меню.
- Storage keys, product JSON, `prilavok_`, UI, чеки, печать и project file не изменены.
- Backend validation описана как обязательный внешний контракт. Backend repository в workspace
  отсутствует, поэтому этот этап проверяет и меняет только iPad publisher.

## Verification

- Full Node suite: **294/294 PASS**.
- JavaScript syntax: PASS.
- Новые regressions: module boundary, commit ordering, nonblocking payment, post-commit triggers,
  no timer/lifecycle/network trigger, newest-snapshot coalescing: PASS.
- Исторические audit diagnostics: все 9 дефектов имеют `reproduced: false`; диагностический script
  возвращает exit 1 именно при исправленных findings по своей существующей sentinel-логике.
- Debug iOS Simulator build without signing: **BUILD SUCCEEDED**; остались прежние 2 project warnings.
- Source/bundle SHA-256 `availability.js` совпадает:
  `29a5655659f77621c172ad47c3f544cea84f76b93a902cda3adba1fdb21bf822`.
- `MARKETING_VERSION`: 130.52.
- `project.pbxproj`: без изменений.
- Физическая проверка реальной оплаты и обновления WEB-остатка отложена до итогового acceptance.
