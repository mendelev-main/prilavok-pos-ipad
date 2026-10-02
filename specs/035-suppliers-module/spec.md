# Feature Specification: поставщики

**Feature Branch**: `main`

**Created**: 2026-10-02

**Status**: Implemented

**Input**: Продолжить production-аудит закупочного контура: проверить CRUD поставщиков, устранить подтверждённую потерю изменений при storage failure и выделить ограниченный модуль без изменения заказов, приёмки, UI или данных.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Поставщик сохраняется устойчиво (Priority: P1)

Создание и изменение имени/товаров поставщика появляются в памяти и UI только после успешной записи.

### User Story 2 - Сбой хранения не создаёт ложный успех (Priority: P1)

При ошибке storage исходный список и связи с товарами остаются прежними, форма доступна для повтора.

### User Story 3 - Удаление сохраняет историю (Priority: P1)

Администратор удаляет поставщика из справочника после локальной записи; существующие заказы и приёмки со снимком поставщика не меняются.

### User Story 4 - Модуль сохраняет runtime-контракт (Priority: P1)

Настройки используют прежние глобальные обработчики после переноса в classic script.

## Requirements *(mandatory)*

- **FR-001**: Create/edit/delete MUST записывать отдельный снимок `prilavok_suppliers` до изменения `state.suppliers`.
- **FR-002**: Storage failure MUST сохранять исходное состояние, не закрывать форму и разрешать повтор.
- **FR-003**: Повторное нажатие во время записи MUST NOT создавать дубликат или повторное удаление.
- **FR-004**: Edit MUST сохранять неизвестные legacy-поля поставщика.
- **FR-005**: Delete MUST повторно проверять действующее право администратора непосредственно перед записью.
- **FR-006**: Исторические `purchaseOrders` и `receivings` MUST оставаться неизменными.
- **FR-007**: Ключ, JSON shape, UI, заказ, приёмка, сеть, версия и `project.pbxproj` MUST остаться без изменений.

## Success Criteria *(mandatory)*

- **SC-001**: Node regression и JavaScript syntax проходят полностью.
- **SC-002**: Success/failure/repeated-action/access tests доказывают storage-first порядок.
- **SC-003**: Simulator build успешен, bundle содержит идентичный модуль.
- **SC-004**: `pos.html` больше не определяет `saveSupplier`.
