# Results: модуль WEB-заказов

**Baseline**: `75483ec` · **Version**: 130.52 · **Date**: 2026-10-02

## Реализованный срез

- WEB-orders runtime перенесён из `pos.html` в `Web/js/features/web-orders.js`.
- Сохранён существующий глобальный API, поэтому UI и inline-обработчики не переписывались.
- `loadAll()` запускается после загрузки feature-компонента.
- Xcode продолжает копировать всю папку `Web`; `project.pbxproj` не изменялся.
- `pos.html` уменьшен с 6919 до 6740 строк; второй домен в этап не включён.

## Совместимость

- Storage prefix и ключи `webEvents`, `webOrderAcceptances`, `parked` не изменены.
- JSON-структуры, порядок local-first записи, URL и payload backend не изменены.
- Версия приложения остаётся 130.52.

## Автоматизированные проверки

- JavaScript syntax: PASS.
- Runtime load-order/public API contract: PASS.
- Полный Node suite: PASS, 209/209.
- Debug Simulator build without signing: `BUILD SUCCEEDED`.
- Собранный `.app` содержит `Web/js/features/web-orders.js`.

Физическая проверка получения и принятия WEB-заказа остаётся в согласованном финальном ручном
прогоне.

## Follow-up: личное уведомление о новом заказе — 2026-10-04

- В Telegram-настройки добавлены локальные поля `deviceChatId` и `notifyOnlineOrders`; старые записи загружаются с выключенным флагом.
- Новый WEB-заказ сначала записывается в `webEvents`, после чего нативный мост отправляет на личный Telegram ID сообщение `Получен онлайн заказ проверьте POS`.
- ID рабочей группы и темы продолжают использоваться только для прежних групповых отчётов.
- Повторное SSE-событие не дублирует сообщение; ошибка storage отменяет уведомление и не блокирует POS.
- Полный Node-набор и контрольная simulator-сборка без подписи проходят; интерфейс Telegram проверен в браузере на компактном размере iPad.
