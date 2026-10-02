# Results: модуль отложенных заказов

**Baseline**: `ab65e86` · **Version**: 130.52 · **Date**: 2026-10-02

## Реализованный срез

- Kitchen delta helpers, park prompt/commit, parked list, resume and delete перенесены в
  `Web/js/features/parked-orders.js`.
- Payment, receipt finalization, stock mutation, returns and loyalty publication остались в
  `pos.html`.
- `pos.html` уменьшен с 5038 до 4920 строк.

## Исправленный риск потери данных

- Старый `deleteParked` менял `state.parked` до вызова подавляющего ошибки `saveKey`.
- Теперь deletion использует `commitCriticalStorage('delete-parked', {parked})`.
- In-memory state и modal обновляются только после завершённой локальной транзакции.
- При ошибке journal persisted и in-memory parked rows остаются без изменений.

## Совместимость

- Park/resume и kitchen print behavior перенесены без изменений.
- Existing keys `parked`, `currentOrderSession`, critical journal и JSON shapes сохранены.
- Сеть, sync и timers не добавлены.
- Version остаётся 130.52; `project.pbxproj` не изменялся.

## Автоматизированные проверки

- JavaScript syntax and runtime/API load order: PASS.
- Park/resume interruption recovery: PASS.
- Delete success and storage failure: PASS.
- Full Node suite: PASS, 231/231.
- Debug Simulator build without signing: `BUILD SUCCEEDED`.
- Built app contains `parked-orders.js`; source/bundle SHA-256:
  `6b45bbc14dc04d9b093364e9c892d95d9a3309aba4afa85e741575df630c72fb`.

## Отложенная проверка

Физическая проверка подписи, park/resume/delete, доставки, WEB-клиента и kitchen print остаётся в
общем финальном прогоне на iPad.
