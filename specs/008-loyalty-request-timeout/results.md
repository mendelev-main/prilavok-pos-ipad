# Results: ограничение ожидания программы лояльности

**Baseline**: `edfb42c` · **Version**: 130.52 · **Date**: 2026-10-01

## Изменение

- Все запросы через `loyaltyApi()` получают единый deadline 5 секунд.
- Зависший `fetch` отменяется через `AbortController`; таймер и обработчик внешней отмены
  освобождаются в `finally`.
- При недоступной повторной проверке подарка payment guard открывает существующий сценарий
  «Продолжить без подарка» и не проводит оплату без действия кассира.
- Расчёт подарков, локальные ключи и данные чека не изменены.

## Автоматизированные проверки

- Node suite: PASS, 185/185.
- Новый stalled loyalty request test: PASS, 1/1.
- Inline JavaScript и storage adapter parse: PASS.
- Native bridge JavaScript `node --check`: PASS.
- Debug Simulator build без signing: `BUILD SUCCEEDED`.
- Собранный bundle содержит timeout и отображает версию 130.52.
- `project.pbxproj` не изменён.

Ручной сценарий отключения backend во время проверки подарка остаётся в общем
[iPad checklist](../003-ipad-production-audit/ipad-checklist.md#6-сеть-web-и-лояльность)
и выполняется в финальном прогоне.
