# Research: модуль аналитики

## Решение 1: вынести локальные расчёты и экран одним доменом

**Decision**: Перенести period helpers, aggregation, chart rendering, access helpers,
`loadLoyaltyAnalytics()` и `renderAnalyticsScreen()` в `features/analytics.js`.

**Rationale**: Эти функции образуют один UI/runtime-контур и вызываются только экраном аналитики.

**Alternatives considered**: Перенести только формулы — оставляет экран и public API разделёнными;
перенести складской отчёт повторно — он уже имеет отдельный компонент.

## Решение 2: сохранить текущий loyalty read

**Decision**: Перенести существующий запрос без изменений и не добавлять вызовы или retry.

**Rationale**: Экран уже показывает центральные loyalty KPI администраторам, а catch переводит только
этот блок в error state. Локальные чеки не зависят от ответа.

**Alternatives considered**: Удалить запрос — продуктовое изменение; объединить с operational channel —
меняет сетевую границу и требует отдельного решения.

## Решение 3: тестировать production-файл

**Decision**: Исполнять `analytics.js` в общей VM fixture и добавить tests для public API,
локальных итогов и backend failure.

**Rationale**: Это доказывает загрузку реального shipped-кода и offline separation.
