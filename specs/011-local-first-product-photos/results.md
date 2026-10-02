# Results: local-first фотографии товаров

**Baseline**: `78a2c20` · **Version**: 130.52 · **Date**: 2026-10-02

## Изменение

- Native picker сохраняет подготовленный JPEG атомарно в Application Support и возвращает UUID.
- `mpos-image` scheme показывает локальный JPEG без base64 в localStorage.
- Карточка и добавочные поля `localImageId`/`imageUploadPending` сохраняются до upload.
- Upload ограничен 10 секундами; ошибка оставляет карточку и local image для ручного retry.
- Успешный ответ обновляет только поля фото в свежем снимке товара, сохраняя текущий остаток.
- Локальные поля не входят в явно сформированный payload онлайн-меню.
- Несохранённые, заменённые и удалённые изображения очищаются из sandbox.
- Все три WK message handler используют weak proxy и снимаются при освобождении POS-контроллера.

## Совместимость

Префикс и существующий ключ `products` не изменены. Новые поля добавочные: старые записи не требуют
миграции, текущий редактор уже сохраняет неизвестные поля, а WEB получает прежний `imageUrl`.

## Автоматизированные проверки

- Node suite: PASS, 193/193.
- Новые local-first photo tests: PASS, 4/4.
- Inline JavaScript и native bridge JavaScript syntax: PASS.
- Debug Simulator build без signing: `BUILD SUCCEEDED`.
- `project.pbxproj` и версия 130.52 не изменены.

Offline/relaunch, замена и удаление фото остаются в
[iPad checklist](../003-ipad-production-audit/ipad-checklist.md#7-lan-принтер-и-native-bridge)
и выполняются в финальном прогоне.
