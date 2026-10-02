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
- Storage keys, product JSON, `prilavok_`, кассовый UI, печать и project file не изменены. В оплаченный
  чек совместимо добавляются только уже известные поля происхождения WEB-заказа.
- Backend сохраняет физический snapshot и открытые WEB-резервы раздельно. Публичное количество
  учитывает резервы, а финальное создание подтверждённого заказа и резерв выполняются одной транзакцией.
- Сайт блокирует неизвестный/нулевой остаток, ограничивает `+` и повторно читает меню при открытии
  корзины и непосредственно перед checkout. Backend остаётся окончательным арбитром при гонке.
- Оплата WEB-заказа закрывает соответствующий резерв вместе со следующим snapshot. После restart
  settlement восстанавливается из существующей истории локальных оплаченных чеков.

## Verification

- iPad Node suite: **296/296 PASS**.
- Backend Node/PGlite suite: **56/56 PASS**.
- JavaScript syntax: PASS.
- Новые regressions: module boundary, commit ordering, nonblocking payment, post-commit triggers,
  no timer/lifecycle/network trigger, newest-snapshot coalescing, settlement after restart, menu/cart
  limits and atomic reservation/settlement: PASS.
- Исторические audit diagnostics: все 9 дефектов имеют `reproduced: false`; диагностический script
  возвращает exit 1 именно при исправленных findings по своей существующей sentinel-логике.
- Debug iOS Simulator build without signing: **BUILD SUCCEEDED**; остались прежние 2 project warnings.
- Source/bundle SHA-256 `availability.js` совпадает:
  `56b0fd808e921c3c4752c5b800dcd0f2761a825573fdce74905c9820024525b1`.
- `MARKETING_VERSION`: 130.52.
- `project.pbxproj`: без изменений.
- Production Supabase migration `event_driven_availability` применена; один активный POS подтверждён,
  RLS включён на всех трёх новых таблицах. Security advisor выдаёт только ожидаемый informational
  `RLS enabled, no policy`: таблицы закрыты для `anon`/`authenticated`, service role работает с bypass.
- Физическая проверка реальной оплаты, первого snapshot и обновления WEB-остатка остаётся итоговым
  live acceptance после выкладки backend и установки свежего iPad build.
