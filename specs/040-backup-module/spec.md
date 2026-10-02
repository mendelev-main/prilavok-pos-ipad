# Feature Specification: модуль резервных копий

**Roadmap**: R1, R8  
**Baseline**: `6fe3a25`  
**Scope**: JSON backup export, validation and atomic import

## Problem

Граница резервных копий остаётся в `pos.html`. Проверка необязательных коллекций не отличает
отсутствующее поле старого backup от присутствующего поля неверного типа и может молча заменить
повреждённый раздел пустым массивом при восстановлении.

## User Scenarios

### US1 — совместимое восстановление

Backup версий 1–12 с корректными обязательными разделами восстанавливается как раньше. Отсутствующие
необязательные разделы старых версий получают прежние значения по умолчанию.

### US2 — отказ до изменения данных

Если присутствующий массивный раздел имеет неверный тип, импорт отклоняется до journal и не меняет
runtime или локальные данные.

### US3 — отдельная граница backup

Экспорт, валидация, применение и выбор JSON-файла находятся в `Web/js/features/backup.js`, сохраняя
существующий глобальный API и порядок запуска.

## Functional Requirements

- **FR-001**: Backup format MUST remain version 12.
- **FR-002**: Versions 1–12 MUST retain current defaults for absent optional sections.
- **FR-003**: A present collection with a non-array value MUST be rejected before storage writes.
- **FR-004**: Import MUST continue through `commitCriticalStorage('backup-import', ...)`.
- **FR-005**: Existing global backup function names and UI entry points MUST remain.
- **FR-006**: Storage keys, JSON fields, printer adapter contract, network and sync MUST not change.

## Success Criteria

- **SC-001**: Regression test proves malformed optional collections cannot clear local data.
- **SC-002**: Module load/API test proves the module loads before startup.
- **SC-003**: Existing backup v11/v12, journal, printer and navigation tests pass.
- **SC-004**: Full Node suite, syntax checks, diagnostics and Simulator build pass.

