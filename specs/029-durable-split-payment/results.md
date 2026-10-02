# Results: надёжная раздельная оплата

**Baseline**: `860d88e` · **Version**: 130.52 · **Date**: 2026-10-02

## Реализовано

- Первая и каждая следующая подтверждённая часть split-оплаты сначала сохраняется через
  `criticalStorageJournal`, затем получает live-статус «Оплачено».
- Versioned `paymentDraft` хранится как необязательное поле прежнего `currentOrderSession`; новых
  storage keys нет.
- Draft содержит точную сумму и части оплаты. При выбранном подарке вместе с ним сохраняются loyalty
  inputs, определившие уже принятую сумму.
- После перезапуска валидный draft восстанавливается и payment screen открывается снова.
- Back на основном и split payment screen не удаляет принятую часть.
- Если все части были сохранены, но финальный чек не успел создаться, доступна кнопка «Завершить
  оплату».
- Финальный boundary теперь отклоняет неизвестный метод, отрицательную/нечисловую сумму и неверные
  cash/card metadata.

## Совместимость

- Старые `currentOrderSession` без optional draft загружаются прежним путём.
- Existing keys, receipt payment rows, product/shift/order formats and critical journal are unchanged.
- Completed receipt still clears session in the same atomic products/orders/shifts/session commit.
- Backup v12 carries the same current session including an unfinished valid draft.
- No network, sync, timer, version or `project.pbxproj` change.

## Автоматизированные проверки

- Full Node suite and JavaScript parse: PASS, 238/238.
- New tests cover storage-before-live ordering, journal creation failure, interrupted-write recovery,
  restart, loyalty-defined total, Back guards, final clearing and malformed payment input.
- Debug Simulator build without signing: `BUILD SUCCEEDED`.
- Built `cart-composition.js` equals source (SHA-256
  `ede7269b1eed8ad786dc0c47dfe76f1a3c587b943beac13ca65447f33f0c9037`).
- Built `pos.html` differs only by the existing `__MPOS_VERSION__` stamp and
  `notification-native.js` injection.

## Отложенная проверка на iPad

В общем финальном прогоне: принять первую часть наличными и картой, проверить Back, принудительно
закрыть и открыть M POS, убедиться в восстановлении статуса/остатка, завершить вторую часть и
проверить единственный чек, однократное списание склада, печать и восстановление подарка лояльности.
