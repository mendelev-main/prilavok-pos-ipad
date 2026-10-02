# Implementation Plan

1. Разделить loading, loaded-empty и error состояния выбранного клиента и обновлять открытое окно после завершения запроса.
2. Сохранять loyalty programs, redemptions и customer binding в существующий `currentOrderSession` additive-полями.
3. Перестроить picker на цифровой ввод и компактные карточки в существующей дизайн-системе M POS.
4. Сформировать immutable receipt snapshot применённых скидок и программ в момент локальной оплаты.
5. Использовать snapshot в payment preview, receipt history/reprint и `NetworkPrinterManager`.
6. Проверить совместимость старых сессий/чеков, расчёты, возвраты, backup, JS syntax и iOS build.

## Constitution Check

- POS и запись оплаты остаются локальными и выполняются до loyalty publish.
- Storage key и существующие поля не переименовываются; новые поля только добавляются.
- Сетевая ошибка программы лояльности не блокирует обычную локальную оплату.
- Каталожная синхронизация и её триггеры не меняются.
- `project.pbxproj` и версия не меняются.
