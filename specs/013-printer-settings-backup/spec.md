# Feature Specification: сохранность настроек принтеров

**Feature Branch**: `main`  
**Created**: 2026-10-02  
**Status**: Automated acceptance complete; device deferred  
**Roadmap**: R1 Production acceptance 130.52  
**Finding**: A003-F13

## User Scenario

Настройки LAN-принтеров и звуковых уведомлений сохраняются с контролем ошибок и переносятся полной
резервной копией. Существующие установки продолжают читать точные исторические ключи `printers` и
`posNotificationSettings` без очистки или скрытой миграции.

## Requirements

- **FR-001**: Сохранить точные исторические localStorage keys и JSON-форматы.
- **FR-002**: Централизовать parse/write и помечать storage broken при ошибке.
- **FR-003**: Не показывать успех и не отправлять пробную печать после ошибки сохранения.
- **FR-004**: Добавить printer settings в backup v12 с проверкой формы.
- **FR-005**: Старые backup v1–v11 импортировать без изменения текущих настроек принтеров.
- **FR-006**: Не менять маршрутизацию печати, ESC/POS payload или UI.

## Success Criteria

- **SC-001**: Backup v12 round-trip восстанавливает принтеры и уведомления.
- **SC-002**: Повреждённый раздел отклоняется до изменения данных.
- **SC-003**: Старые backup остаются совместимыми.
- **SC-004**: Полный Node suite, JS syntax и Simulator build проходят.
