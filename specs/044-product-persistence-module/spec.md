# Feature Specification: модуль сохранения товара

**Roadmap**: R1, R8
**Baseline**: `41ee5e4`
**Scope**: сохранение карточки товара и управление её WEB-признаком без изменения поведения

## Problem

Критическая граница сохранения товара остаётся в `pos.html`. Она объединяет проверку формы,
совместимое обновление JSON, обязательную локальную запись и последующую необязательную загрузку фото.
Для дальнейшей модульной миграции эту границу нужно выделить целиком, не меняя её порядок операций.

## User Scenarios

### US1 — товар сохраняется локально до сети

Создание или изменение товара сначала надёжно записывает полный массив товаров локально. Ошибка
storage оставляет прежнее состояние и не запускает upload. Недоступный backend не отменяет сохранение.

### US2 — существующие товары остаются совместимыми

Редактирование сохраняет неизвестные поля старых и будущих записей, единицы, рецептуры,
модификаторы, остаток, себестоимость и local-first признаки фотографии в прежнем формате.

### US3 — WEB-признак сохраняет текущие права и поведение

Администратор открытой смены может изменить публикацию товара; остальные сотрудники получают
прежний отказ. Полная синхронизация меню при этом не запускается.

## Functional Requirements

- **FR-001**: Локальная запись товара MUST завершаться до любой попытки upload фотографии.
- **FR-002**: Ошибка локальной записи MUST сохранять прежние `state.products` и MUST NOT запускать сеть.
- **FR-003**: Ошибка upload MUST оставлять локально сохранённый товар с прежними retry-признаками.
- **FR-004**: Product JSON, storage key, units, recipes, modifiers and unknown fields MUST remain unchanged.
- **FR-005**: WEB controls MUST preserve current role checks and MUST NOT trigger menu synchronization.
- **FR-006**: Photo picker, compression and native read implementation MUST remain outside this stage.
- **FR-007**: Existing global function names MUST remain available to inline UI and feature modules.

## Success Criteria

- **SC-001**: Все существующие тесты сохранения товара проходят через новый module boundary.
- **SC-002**: Module load/API test подтверждает порядок до editor, catalog и startup.
- **SC-003**: Storage failure regression подтверждает отсутствие state publication и network request.
- **SC-004**: Full Node suite, syntax, diagnostics and Simulator build pass.

## Assumptions

- Функциональное поведение, интерфейс, локальные данные, сеть и версия приложения не меняются.
- Физическая проверка редактора товара остаётся частью итоговой приёмки на iPad.
