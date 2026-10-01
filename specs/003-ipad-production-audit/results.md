# Results: полный production-аудит iPad-приложения

**Date**: 2026-10-01  
**Baseline**: `6975821` (`main`, `origin/main`)  
**Version**: 130.52  
**Initial worktree**: clean

Аудит выполнен без production-синхронизации и без изменения runtime.

## Итог

Текущую 130.52 нельзя считать полностью прошедшей production acceptance: найдены **3 P0**, **7 P1**
и **4 P2**. Главный общий дефект — совместимый фасад `saveKey()` скрывает ошибку записи, а несколько
составных операций изменяют память/UI и связанные localStorage-ключи независимо.

Критический контур оплаты, возврата, приёмки и импорта backup защищён журналом и прошёл тесты.
Основные блокеры находятся рядом с этим контуром: отложенные чеки, смены и инвентаризация.

Полное описание, последствия и критерии закрытия: [findings.md](findings.md).

## Проверки

| Проверка | Результат |
|---|---|
| Git baseline | clean `6975821`, `main == origin/main`, версия 130.52 |
| Node suite | PASS, 161/161 |
| Inline JavaScript + storage adapter | PASS |
| `node --check` native JS bridge files | PASS |
| Synthetic storage/network diagnostics | 9/9 сценариев подтверждены |
| Debug simulator build, signing off | `BUILD SUCCEEDED` |
| Xcode static analyzer | `ANALYZE SUCCEEDED`, code findings отсутствуют |
| Built bundle resources | `pos.html`, adapter и оба JS bridge-файла присутствуют |
| Build-time version stamp | в bundle и UI — 130.52 |
| Runtime diff | отсутствует; изменена только документация/diagnostics |

Команды сборки использовали отдельные DerivedData в `/private/tmp`. Xcode оставляет два
некритичных предупреждения проекта: legacy headermap и build phase `Stamp POS Version` без output.

## Границы доказательств

Не запускались production backend, ручная синхронизация, реальные WEB-заказы, Telegram и запись
пользовательских данных. Матрица просмотренных областей находится в [coverage.md](coverage.md).
Simulator build и unit-тесты не доказывают поведение при suspend/kill,
нехватке места, настоящем LAN TCP 9100, AirPrint и выборе фото. Эти проверки перечислены в
[ipad-checklist.md](ipad-checklist.md).

## Рекомендуемый порядок исправлений

1. Отложенный чек — атомарное перемещение и recovery.
2. Смена и движения наличных — строгая запись до Telegram/печати/UI success.
3. Инвентаризация — одна journal transaction.
4. Валидация загружаемой формы данных и безопасный degraded startup.
5. Timeout лояльности и local-first фото.
6. Deadline/serialization LAN-принтера.
7. Авторизация администратора — после отдельного решения по модели доступа.

Каждый пункт следует вести отдельной небольшой спецификацией и принимать на физическом iPad.
