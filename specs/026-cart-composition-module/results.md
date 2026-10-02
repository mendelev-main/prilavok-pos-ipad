# Results: модуль формирования корзины

**Baseline**: `354bad6` · **Version**: 130.52 · **Date**: 2026-10-02

## Реализованный срез

- Cart identity, add-to-cart, manual price, modifiers, quantity, swipe handlers, line removal and
  empty-order reset перенесены в `Web/js/features/cart-composition.js`.
- Shared notifications, parking/resume, payment, stock mutation, receipt and printing остались в
  `pos.html`.
- `pos.html` уменьшен с 5132 до 5038 строк.

## Исправленный дефект

- Добавлена явная локальная инициализация `cartSwipeState=null`.
- До исправления direct click без предыдущего touchstart мог читать необъявленную переменную и
  завершаться `ReferenceError`.
- Regression test подтверждает открытие строки в свежем runtime без touch-жеста.

## Совместимость и безопасность

- 96 исходных строк функций перенесены без изменений; добавлена только инициализация swipe state.
- Cart line shape, `currentOrderSession`, keys, prefix `prilavok_` и JSON formats не изменены.
- Aggregate stock validation остаётся до cart mutation.
- Network/sync/timers не добавлены; version остаётся 130.52; `project.pbxproj` не изменялся.

## Автоматизированные проверки

- JavaScript syntax: PASS.
- Load-order/global API, direct click and comma manual-price contracts: PASS.
- Full Node suite: PASS, 228/228, включая stock/modifier/session/parking/payment/receipt regressions.
- Debug Simulator build without signing: `BUILD SUCCEEDED`.
- Built app contains the component; source/bundle SHA-256:
  `f26937001318ec42aadfe56bce6070f624dee93f6c629698e05f22a25fe585cd`.

## Отложенная проверка

Физическая проверка добавления, modifier modal, ручной цены, количества, click и swipe остаётся в
общем финальном ручном прогоне на iPad.
