# Results: регрессия native bridge и печати

**Baseline**: `89bb318` · **Version**: 130.52 · **Date**: 2026-10-02

## Изменение

- Добавлен отдельный VM-harness для `network-printer.js` с несколькими LAN-принтерами и
  перехватом каждого native payload.
- Зафиксированы auto/manual routing, copies, category filtering, comments, shift-close и безопасное
  отсутствие WK bridge.
- Добавлена проверка Swift contract: action routing, IPv4 validation, десятисекундный deadline и
  поддерживаемые типы печатных документов.
- Удалена неиспользуемая wrapper-логика `printReceipt`; фактический путь повторной печати через
  `sendOrderToPrint` не изменён.

## Автоматизированные проверки

- `node --check PrilavokPOS/network-printer.js`: PASS.
- Printer regression suite: PASS, 6/6.
- Полный Node suite: PASS, 206/206.
- Debug Simulator build без signing: `BUILD SUCCEEDED`.
- `project.pbxproj` и версия 130.52 не изменены.

Качество raster, доступность TCP 9100, реальные 58/80 мм, обрезчик и денежный ящик остаются в
финальной ручной приёмке на физическом iPad и подключённых принтерах.
