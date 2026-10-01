# Запуск проверки

Сначала прочитать results.md: baseline включает незакоммиченный рабочий код.
На рабочем iPad не имитировать quota, не стирать storage и не импортировать тестовую базу.
Сценарии разрушающих отказов — только изолированная синтетическая среда.

Из корня POS (node должен быть доступен в PATH):
```sh
node --test tests/*.test.cjs
node specs/001-production-audit/diagnostics.cjs
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project PrilavokPOS.xcodeproj -scheme PrilavokPOS -sdk iphonesimulator -configuration Debug -derivedDataPath /private/tmp/mpos-audit-build CODE_SIGNING_ALLOWED=NO build
```
Diagnostics exit 2 = известные дефекты воспроизведены, 1 = ошибка harness, 0 = дефекты не воспроизведены.
Это не acceptance suite: после исправлений добавить проверки ожидаемого поведения в tests/.
Backend: в checkout из results.md выполнить `node --test tests/*.test.mjs tests/*.test.cjs`.

Spec Kit без смены ветки:
```sh
SPECIFY_FEATURE_DIRECTORY=specs/001-production-audit SPECIFY_FEATURE_NO_PERSIST=1 bash .specify/scripts/bash/check-prerequisites.sh --json --require-spec --require-tasks --include-tasks
```

Физическая проверка: зафиксировать build/версию iPadOS/модель iPad/принтер, остатки и кассу до начала;
подготовить отдельные тестовые товары/клиента и список тестовых чеков. Пройти cases.md сверху вниз.
Для каждой строки записать дату, исполнителя, фактический результат и ID чеков без персональных данных.
Не считать старое «всё работает» подтверждением всех аварийных сценариев новой сборки.

Дополнительный checkout harness (также exit 2 при воспроизведении дефекта):
```sh
node specs/001-production-audit/checkout-diagnostics.cjs /absolute/path/to/backend
```
Он импортирует реальный checkout-service.js, но заменяет БД и verification искусственными объектами.
