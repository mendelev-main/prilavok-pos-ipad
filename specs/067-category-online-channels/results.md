# Results: отдельные каналы категорий

**Date**: 2026-10-03

## Delivered

- В списке и редакторе категорий доступны независимые переключатели «Онлайн меню» и «Онлайн заказ».
- `layout.categoryOnlineOrder` и `layout.categoryOnlineMenu` сохраняются локально.
- Старый `layout.categoryOnline` сохранён как совместимый фасад онлайн-заказа.
- Legacy layout и backup переносят прежнее значение в оба канала.
- Manual menu sync передаёт два признака категории и применяет их к товарам соответствующей категории.
- Backend migration добавляет два category columns без удаления строк.
- `/api/menu` и `/api/menu?surface=menu` фильтруют категории и исключают товары скрытых категорий.
- Backend-first deployment безопасно откатывается к старым category columns до применения миграции.

## Verification

- POS regression suite: 323 passed.
- Backend regression suite: 64 passed.
- Category migration test, including reapply: passed.
- JavaScript syntax checks: passed.
- `git diff --check`: passed in both repositories.
- iOS Simulator build without signing: `BUILD SUCCEEDED`.
- Production migration `20261003003000_category_online_channels.sql` applied successfully.
- Production data check: 17 categories total, 10 available for order, 10 visible in menu, 0 invalid `NULL` values.
- Railway deployment is active on backend commit `4f183390df018c530066e7cc2ad7779dbb651a86`.
- Production API check: `/health` returned 200; order surface returned 10 categories / 96 products; menu surface returned 10 categories / 104 products.
- Current iPad build installed and launched successfully on `iPad (Work Project)` through Xcode.

## Deferred acceptance

- On iPad set a category to menu ON / order OFF, restart, manually synchronize, and verify both WEB surfaces.
