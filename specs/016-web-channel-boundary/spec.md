# Feature Specification: граница входящих WEB-каналов

**Feature Branch**: `main`  
**Created**: 2026-10-02  
**Status**: Automated acceptance complete; live integration deferred  
**Roadmap**: R4  

## User Scenario

POS получает заказы сайта и подтверждает уже локально сохранённые заказы независимо от ручной
публикации меню. Входящее событие, reconnect или запуск приложения не могут незаметно отправить
каталог товаров на backend.

## Requirements

- **FR-001**: EventSource использует только канал входящих WEB-заказов.
- **FR-002**: Входящее событие сохраняется локально и не вызывает menu/availability upload.
- **FR-003**: ACK/retry использует только существующий журнал принятия и endpoint заказа.
- **FR-004**: Полная публикация каталога вызывает `/api/menu/sync` только по явной кнопке.
- **FR-005**: Успешная ручная публикация может сразу обновить разрешённый snapshot остатков.
- **FR-006**: Reconnect operational/loyalty/ACK не вызывает полную публикацию каталога.

## Success Criteria

- **SC-001**: Детерминированный EventSource-тест принимает и сохраняет заказ без `fetch`.
- **SC-002**: Тест ручной синхронизации подтверждает единственный путь к `/api/menu/sync`.
- **SC-003**: Существующие availability tests подтверждают отсутствие online/network trigger.
- **SC-004**: Полный Node suite и Simulator build проходят.
