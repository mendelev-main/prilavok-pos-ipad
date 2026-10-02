# Results: отдельные каналы онлайн-каталога

**Date**: 2026-10-02

## Delivered

- Существующий `availableOnline` сохранён и отображается как «Онлайн заказ».
- Добавлен независимый `availableInOnlineMenu` с переключателем «Онлайн меню».
- В онлайн-разделе карточки добавлено публичное описание; используется существующий ключ `description`.
- Ручной menu sync передаёт оба признака, описание, фото и прежние поля товара.
- Страница заказа использует `available_online`, страница меню — `visible_in_menu`.
- Backend migration добавляет новый столбец без удаления или пересоздания данных.
- До применения migration backend продолжает прежнее поведение без отказа menu/sync endpoint.

## Compatibility

- Старые товары без нового ключа получают `availableInOnlineMenu: true`, поэтому не исчезают из меню.
- Их прежнее значение `availableOnline` не меняется.
- Новый товар сохраняет прежнее начальное состояние формы; импортированные товары имеют оба флага выключенными.
- Ни один локальный флаг не запускает сеть: публикация происходит только после ручной синхронизации.
- Storage prefix, storage key, цены, остатки, рецептуры, checkout и availability snapshot не изменены.
- Синхронизация каталога остаётся только ручной.

## Verification

- JavaScript syntax checks: passed.
- POS regression suite: 322 passed.
- Backend regression suite: 62 passed.
- PostgreSQL migration test, including reapply: passed.
- `git diff --check`: passed in both repositories.
- iOS Simulator build without signing: `BUILD SUCCEEDED`; прежние project warnings остались.
- Built bundle contains the changed feature modules byte-for-byte.
- Browser smoke-check in dark theme: оба switches, описание, labels and spacing render correctly.

## Deployment order

1. Deploy backend code (safe fallback keeps the old channel until schema is ready).
2. Apply `20261002230000_product_online_channels.sql` in Supabase.
3. Update iPad and run the existing manual menu synchronization once.
4. Verify one menu-only product on `/menu/` and its absence on the online-order page.

## Production deployment

Verified on 2026-10-02:

- Railway is serving backend commit `5ac56d6`.
- Supabase migration `20261002230000_product_online_channels.sql` was applied successfully.
- At migration verification time the catalog contained 213 products: all 213 retained
  `visible_in_menu = true`, 96 retained `available_online = true`, and no new flag was `NULL`.
- Production `/health` returned HTTP 200.
- Production `/api/menu` returned 96 orderable products.
- Production `/api/menu?surface=menu` returned 198 active menu products.
- The different endpoint counts confirm that menu visibility and order availability are filtered independently.

## Deferred physical acceptance

On iPad: save both toggle combinations, enter a long description, restart the app, perform manual sync,
then verify both web surfaces. This remains part of the final physical-device matrix.
