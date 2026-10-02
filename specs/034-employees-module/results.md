# Results: сотрудники и локальные права

**Baseline**: `3843e91` · **Version**: 130.52 · **Date**: 2026-10-02

## Реализовано

- CRUD, display helpers и delete protection сотрудников выделены в `Web/js/features/employees.js`.
- Create/edit теперь формируют отдельный снимок, записывают `prilavok_employees` и только после успешной записи публикуют его в `state`.
- Storage failure оставляет исходный список и роль, не закрывает форму, не показывает успех и разрешает повтор.
- Повторное нажатие во время незавершённой записи не создаёт второго сотрудника.

## Доказательство совместимости

- Ключ `prilavok_employees`, массив и поля `id/name/phone/role` не изменены.
- При редактировании сохраняются неизвестные legacy-поля записи.
- Пароль, роли, запрет удаления себя и администратора, сохранение истории чеков/смен и UI-тексты не изменены.
- Сеть, синхронизация, version и `project.pbxproj` не изменены.
- `pos.html` уменьшился с 3924 до 3837 строк.

## Автоматизированные проверки

- Full Node suite и JavaScript syntax: PASS, 255/255.
- Create/edit success, storage failure, password/role, delete protection и repeated-save: PASS.
- Debug Simulator build without signing: `BUILD SUCCEEDED`.
- Source и bundled `employees.js` SHA-256: `5cab978f014c2d487f69cc7f7fda765731cea6aa3649fd3b71bac4f92b1b26ac`.

## Отложенная проверка на iPad

Создание, изменение, выдача/снятие admin, запреты удаления и перезапуск после операций остаются в общей финальной physical acceptance matrix.
