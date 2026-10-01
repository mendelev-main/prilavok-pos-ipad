# Feature Specification: единый workflow GitHub Spec Kit

**Feature Branch**: `main`  
**Created**: 2026-10-01  
**Status**: Approved  
**Input**: Убрать конкурирующие MASTER/DELTA-процессы и вести дальнейшую работу по GitHub Spec Kit.

## User Scenarios & Testing

### User Story 1 — один статус работы (Priority: P1)

Владелец и разработчик видят приоритеты в `ROADMAP.md`, а точный статус каждой активной работы — в её `spec.md`, `plan.md`, `tasks.md` и `results.md`.

**Independent Test**: поиск по репозиторию не находит активных ссылок на `MASTER_SPEC.md`, `DELTA_SPEC.md` и `LOYALTY_SPEC.md` вне исторических архивов.

### User Story 2 — сохранённый контекст (Priority: P1)

Актуальная архитектура, правила offline-first, границы сети, критические данные и проверки не теряются при удалении корневых spec-файлов.

**Independent Test**: `docs/ARCHITECTURE.md`, `.specify/memory/constitution.md` и `specs/001-production-audit/` вместе описывают границы проекта и доказательства проверок.

### User Story 3 — малые независимые изменения (Priority: P2)

Каждая новая функция или существенное исправление получает отдельный каталог `specs/NNN-name/`; крупные темы делятся на срезы в roadmap.

**Independent Test**: индекс документации однозначно описывает цикл Constitution → Roadmap → Spec → Plan → Tasks → Implement → Converge/Results.

## Requirements

- **FR-001**: `.specify/memory/constitution.md` MUST оставаться единым источником постоянных инвариантов.
- **FR-002**: `ROADMAP.md` MUST хранить только приоритет, границу, зависимости, статус и ссылку на sub-spec.
- **FR-003**: Активные требования и задачи MUST жить в `specs/`, а не в roadmap или architecture reference.
- **FR-004**: `docs/ARCHITECTURE.md` MUST описывать текущую систему без backlog и промежуточных статусов.
- **FR-005**: Корневые `MASTER_SPEC.md`, `DELTA_SPEC.md`, `LOYALTY_SPEC.md` MUST быть удалены после переноса актуальных сведений.
- **FR-006**: Исторические baseline и results MUST оставаться неизменными, если их точность зависит от даты/коммита.
- **FR-007**: Рабочий runtime, Xcode project, схемы данных и версия при этой миграции MUST NOT изменяться.

## Success Criteria

- **SC-001**: В корне остаются `ROADMAP.md`, `.specify/`, `specs/` и обычные reference docs; MASTER/DELTA/LOYALTY отсутствуют.
- **SC-002**: Все неархивные Markdown-ссылки внутри репозитория разрешаются.
- **SC-003**: `specify integration status` остаётся `OK`.
- **SC-004**: `git diff --check` проходит; source/runtime diff отсутствует.

## Assumptions

- История удалённых root-spec сохраняется Git, поэтому дублирующая копия в активной документации не нужна.
- Версия 130.52 остаётся техническим `MARKETING_VERSION` в Xcode до отдельной versioning-spec.
