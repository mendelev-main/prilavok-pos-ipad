# Results: ограниченный lifecycle LAN-печати

**Baseline**: `d12c97d` · **Version**: 130.52 · **Date**: 2026-10-01

## Изменение

- Создание, callbacks и реестр `NWConnection` выполняются на выделенной serial queue.
- Каждое задание получает deadline 10 секунд; `.waiting` остаётся допустимым переходным
  состоянием только до этого срока.
- Единый idempotent `finish` очищает handler, отменяет соединение, удаляет его из реестра и
  отправляет не более одного terminal-события.
- ESC/POS encoder, payload и настройки LAN-принтера не изменены.

## Автоматизированные проверки

- Node suite: PASS, 185/185.
- Native bridge JavaScript `node --check`: PASS.
- Debug Simulator build без signing: `BUILD SUCCEEDED`.
- Компилятор не выдал предупреждений для `NetworkPrinterManager.swift`.
- `project.pbxproj` и версия 130.52 не изменены.

Недоступный принтер, отключение Wi‑Fi и 20 параллельных заданий под Thread Sanitizer остаются в
[iPad checklist](../003-ipad-production-audit/ipad-checklist.md#7-lan-принтер-и-native-bridge)
и выполняются в финальном прогоне.
