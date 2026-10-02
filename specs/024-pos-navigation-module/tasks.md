# Tasks: модуль навигации рабочей зоны

- [X] T001 Создать Spec Kit-комплект и зафиксировать runtime/storage boundary
- [X] T002 Исследовать точную contiguous границу и существующие navigation regressions
- [X] T003 Перенести runtime в `Web/js/features/pos-navigation.js` без изменения алгоритмов
- [X] T004 Подключить модуль до `loadAll()` и исполнить его в fixture
- [X] T005 Добавить load-order/public API contract test
- [X] T006 Проверить byte-equivalence и отсутствие inline-дубликата
- [X] T007 Выполнить syntax checks и полный Node suite
- [X] T008 Выполнить Simulator build и проверить bundle
- [X] T009 Обновить architecture, roadmap, results и закрыть tasks
- [X] T010 Проверить итоговый diff, версию и `project.pbxproj`

## Dependencies

T003–T005 → T006–T008 → T009–T010. Физическая проверка остаётся в финальном прогоне.
