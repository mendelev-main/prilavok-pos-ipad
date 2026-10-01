# Results: безопасный запуск при повреждённой форме storage

**Baseline**: `7c7bf85` · **Version**: 130.52 · **Date**: 2026-10-01

## Изменение

- `loadAll()` проверяет корневой тип массивов записей и объектных настроек до их
  использования.
- Некорректные значения заменяются безопасным значением только в памяти и включают
  предупреждение о повреждённом storage.
- Исходные строки `products`, `layout`, `network`, `hallTables` и других повреждённых
  ключей не перезаписываются во время запуска.
- Некорректные элементы массива товаров исключаются только из рабочего состояния;
  исходный JSON остаётся доступен для восстановления.
- Ключи, префикс `prilavok_`, структура корректных данных, UI и сетевая логика не изменены.

## Автоматизированные проверки

- Node suite: PASS, 184/184.
- Новые storage shape recovery tests: PASS, 2/2.
- Inline JavaScript и storage adapter parse: PASS.
- Native bridge JavaScript `node --check`: PASS.
- Debug Simulator build без signing: `BUILD SUCCEEDED`.
- `project.pbxproj` и версия 130.52 не изменены.

Ручной degraded-startup сценарий остаётся в общем
[iPad checklist](../003-ipad-production-audit/ipad-checklist.md#1-запуск-и-локальные-данные--p0)
и выполняется в финальном прогоне.
