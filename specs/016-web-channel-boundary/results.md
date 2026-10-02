# Results: граница входящих WEB-каналов

**Baseline**: `5268ff7` · **Version**: 130.52 · **Date**: 2026-10-02

## Проверенная граница

- EventSource подключается только к `/api/orders/events`, сохраняет входящий заказ локально и не
  выполняет исходящий `fetch`.
- Повторный запуск EventSource закрывает предыдущий источник.
- `/api/menu/sync` встречается в runtime-коде один раз и вызывается явной кнопкой администратора.
- Успешная ручная публикация меню запускает разрешённое немедленное обновление остатков.
- Существующие тесты подтверждают, что availability не запускается при online event, а ACK/retry
  использует отдельный durable journal.

## Автоматизированные проверки

- WEB boundary regression tests: PASS, 2/2.
- Полный Node suite: PASS, 208/208.
- Debug Simulator build без signing: `BUILD SUCCEEDED`.
- Runtime-код, `project.pbxproj` и версия 130.52 не изменены.

Разрыв/восстановление реальной сети, SSE delivery и live backend ACK остаются в финальном
интеграционном прогоне на физическом iPad.
