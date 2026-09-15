# Prilavok POS — Offline-First Architecture

## Core rule

The iPad POS is the authoritative source of operational data.

## Required behavior

1. The POS must continue operating if internet access is lost.
2. Sales, receipts, shifts, catalog changes and local settings must be committed locally before any remote synchronization is attempted.
3. Remote services are synchronization targets, not the primary database for live POS operation.
4. A server response must never silently overwrite newer local POS state.
5. Synchronization must be retryable and must not block checkout, receipt creation, printing or shift operations.
6. Every migration from `pos.html` into modules must be incremental and verified on a physical iPad before the next migration step.

## Manual synchronization requirement

Synchronization is USER-INITIATED ONLY.

The application must not automatically synchronize after a local data change, on a timer, in the background, on launch, on reconnect, or when network availability changes.

The only permitted synchronization trigger is the existing synchronization button in:

`Настройки → Сетевые настройки`

Required flow:

1. A user changes data in the POS.
2. The change is saved locally on the iPad immediately.
3. The POS continues operating normally, regardless of internet availability.
4. The local state may be marked as having pending synchronization changes.
5. No network synchronization is started automatically.
6. The user opens `Настройки → Сетевые настройки` and presses the existing synchronization button.
7. Only then may the POS send its current authoritative local state to the backend.
8. The backend/web version is updated from POS data.
9. If synchronization fails, local POS data remains unchanged and POS operation continues normally.

## Synchronization direction and conflict rule

Authoritative direction:

`iPad POS → Backend → Web / Mini App`

The iPad POS remains the source of truth.

Remote data must not overwrite authoritative local POS data during normal synchronization. Any future remote-to-POS import feature must be designed as a separate explicit user action and must not be part of the standard synchronization button unless separately approved.

## Synchronization status UX

The Network Settings screen should eventually expose clear synchronization state, for example:

- pending local changes;
- last successful synchronization time;
- synchronization in progress;
- synchronization succeeded;
- synchronization failed / no connection.

A failed synchronization must never prevent sales or other local POS operations.

## Application version visibility requirement

The POS must always expose its current application version in the Settings screen so it is easy to verify which build is running on the iPad during testing and support.

The version is displayed in the `Настройки` screen inside the `Быстрые настройки` module, aligned on the right side of the module header.

Required UI behavior:

1. The left side of the header remains `Быстрые настройки`.
2. The right side displays the current version in a compact form, for example `Версия 130.16`.
3. The version label must be visually secondary and must not compete with the quick-action buttons.
4. The version must be updated whenever the POS application version is advanced.
5. This version indicator is a permanent diagnostics/support element and should not be removed during future UI refactors.

## Local storage adapter requirement

All operational POS persistence must pass through a local storage adapter before any synchronization layer is allowed to use the same data.

The adapter must preserve compatibility with the current `pos.html` persistence model:

- existing logical keys remain unchanged;
- the localStorage prefix remains `prilavok_`;
- existing JSON payload shapes remain unchanged;
- `window.storage` remains supported where available;
- `localStorage` remains the offline fallback on the iPad;
- reads and writes must not require internet access;
- the adapter must never start synchronization as a side effect of a write.

Storage and synchronization are separate concerns. A successful local write means the POS operation is complete even if the backend is unreachable.

## Migration sequence

1. Add inactive module boundaries.
2. Document the existing data model and persistence points.
3. Introduce a local storage adapter behind the existing behavior.
4. Introduce manual synchronization orchestration with no automatic triggers.
5. Add durable pending-change tracking if required by the selected sync payload strategy.
6. Move one business domain at a time from `pos.html` into modules.
7. Keep printing and checkout regression tests mandatory after each move.

## v130.12 scope

This version added the future module structure. None of the new files were connected to `pos.html`, so existing runtime behavior remained unchanged.

## v130.13 requirement change

The synchronization design is now explicitly manual-only. The existing button in `Настройки → Сетевые настройки` is the sole approved trigger for standard POS-to-backend synchronization. Automatic/background synchronization is prohibited unless this requirement is intentionally changed later.

## v130.14 requirement change

The `Быстрые настройки` module must display the current POS application version on the right side of its header. This version indicator is retained as a permanent support and test-verification element.

## v130.16 scope

A real offline-first storage adapter now exists at `PrilavokPOS/Web/js/core/storage.js`. It mirrors the current storage contract without changing keys or payload formats and never triggers synchronization. Runtime wiring into the monolithic `pos.html` remains a separate incremental migration step and must be regression-tested on a physical iPad before broader replacement of direct storage calls.


## v130.17 scope

`pos.html` loads the bundled `Web/js/core/storage.js` before its main script.
Existing `loadKey` / `saveKey` remain async compatibility facades. Read failures
still return the caller's fallback and notify `markStorageBroken`; write failures
still notify it without escaping into callers. Provider selection is captured once
with the original `typeof window.storage !== 'undefined'` semantics.

Logical keys, `prilavok_`, JSON serialization, `window.storage` arguments and
`loadAll` are unchanged. No migration, data clearing, new network operations or
synchronization triggers are introduced. Existing network behavior is unchanged.
The legacy `Web/js/storage.js` is not loaded. Other modules remain inactive.

Xcode copies the Web folder as a local resource. Only core/storage.js is executed
by the new script tag. Version 130.17 uses the existing MARKETING_VERSION stamping
phase; the project change is limited to resource registration and the two version
values. The user has confirmed the physical-iPad test with «Все работает»; v130.17 became the confirmed checkpoint at that stage.

Before accepting v130.17 on a physical iPad, update over the existing app without
uninstalling, verify existing data and unfinished orders, test offline sales,
product edits, receipts/printing, shift cash movements and persistence after a
restart. Check the Quick Settings version and manual menu synchronization. A
storage-failure test belongs on test data, never by corrupting operational data.


## v130.18 — nested recipe consumption and compatible receipt extension

This stage fixes stock accounting for composite products before the separate
product-editor redesign. `productIngredients` expands nested recipes into simple
products and sums shared ingredients. The same quantities drive availability,
cart/checkout validation and the sale's stock deduction. Cycles, missing products,
empty recipes and non-positive/non-finite quantities are rejected before mutation.
Products with disabled stock tracking contribute cost but are not deducted.
A valid recipe with no tracked ingredients has unlimited stock availability.

### Explicit additive data transition: stockConsumption v1

Only newly created receipts gain the following optional field inside the existing
`orders` array (illustrative IDs and quantities):

```json
{
  "stockConsumption": {
    "version": 1,
    "items": [
      { "productId": "flour-id", "qty": 0.2 },
      { "productId": "water-id", "qty": 0.1 }
    ]
  }
}
```

Quantities are totals for the entire sold order in the original stock units.
Only simple products actually deducted are recorded. An empty items array means
nothing was deducted; it must not fall back to the current recipe during return.
The receipt snapshot is saved through the existing adapter with `orders`.

This is an explicit backward-compatible addition, not a rewrite of existing JSON.
No localStorage key, prefix, product ID, recipe field or existing field semantics
is changed. No bulk migration or clearing runs on launch. Existing receipt fields
and old receipts remain untouched; old and new receipts may coexist in one array.
The existing backup exporter/importer preserves the complete orders, including
this field. Receipt display and native printing continue using existing fields.

For new receipts, return first validates all recorded targets, then restores the
recorded quantities regardless of later recipe or noStockTracking changes. Missing
or changed-type targets and malformed/unsupported snapshots abort the return
before any stock, return status or cash movement is changed. Deleting or changing
the type of a simple product referenced by an unreturned snapshot is blocked.

Old receipts without the field keep the legacy one-level return path. Their exact
historical recipe cannot be reconstructed: return after recipe edits remains a
known limitation for old receipts. Never fabricate snapshots from today's recipe.
Older application versions do not use this snapshot for returns; do not treat a
downgrade as validated stock accounting after v130.18 sales. No downgrade or
user-data restoration is performed by this stage.

Local-storage failures remain subject to the existing storage warning contract;
this stage does not introduce transactional writes across products/orders/shifts.
Historical supplier-demand calculations still use their existing recipe logic;
this stage does not rebuild historical analytics from the new snapshot.

### Validation gate

Run `node --test tests/product-stock.test.cjs`. Tests use the actual runtime with
synthetic localStorage, never operational data or network. Coverage includes
nested/shared consumption, fractional quantities, insufficient stock, cycles,
legacy receipts, snapshot return, duplicate return, backup/restart compatibility,
missing targets, payment fields and printing bridge payload.

On physical iPad, update over v130.17 without uninstalling; verify version 130.18.
With test goods in consistent existing units: flour stock 10, water stock 10;
dough uses flour 0.2 and water 0.1; pizza uses dough 1. Selling one pizza must leave
flour 9.8 and water 9.9. Change the dough recipe to flour 0.3, return that new receipt,
and verify flour/water return to 10, including after restarting the app. Test a
second recipe sharing flour, insufficient combined stock, cash/card/split payment,
old/new receipt printing, a rejected recipe cycle, and offline operation.
The user confirmed this physical-iPad stage with «Да все работает коректно».
v130.18 is now the confirmed checkpoint. This does not authorize commit/push.


## v130.19 — интерфейс карточки товара

Редактор находится в отдельном product-editor-root вне перерисовываемого app.
Поля и состав живут в черновике до явного сохранения; выход с изменениями требует
выбора сохранить/не сохранять/остаться. Черновик не является автосохранением и
не восстанавливается после завершения процесса приложения.

Сохраняется существующая схема products и components [{productId, qty}],
идентификаторы и префикс prilavok_. Новых постоянных ключей и миграций нет.
Расчёт остатков, продаж, возвратов, stockConsumption v1, печать и Swift не изменены.
«Где используется» вычисляет связи из локального состояния без сети; счётчики
чеков учитывают прямые позиции и имеющиеся снимки списания, отложенные заказы —
прямые позиции. Это не полный аудит приёмок и заказов поставщикам.

Фото использует прежний upload endpoint до сохранения товара: известный долг
local-first не устранён на этом этапе. При его ошибке карточка остаётся открытой,
исходный товар не меняется; можно убрать выбранное фото и сохранить без него.
Если товар изменился во время upload, устаревшая копия не применяется.
Существующий фасад saveKey по-прежнему сам обрабатывает ошибки storage;
успешное закрытие карточки не добавляет новой гарантии транзакционности.

Новая версия требует отдельного теста на физическом iPad. Контрольная версия — v130.18.


## v130.20 — единицы и конфигурации товара; ожидает iPad

Добавлены необязательные поля products: stockUnit (неизменная базовая единица),
stockDisplayUnit (единица ввода карточки), minStock (в базовых единицах), sku,
internalNote. Для components добавлено необязательное displayUnit.
Это совместимое расширение схемы: ключи и префикс прежние, массовой миграции нет.
Отсутствующие поля сохраняют прежнюю семантику; при обычном сохранении старого товара
единицы не добавляются автоматически. Первое явное назначение stockUnit трактует
существующие числа в выбранной единице без пересчёта — пользователь должен проверить
их смысл. После назначения базовая единица не меняется; смена единицы ввода между
кг/г или л/мл пересчитывает поля карточки, но не сохранённые stock/cost или историю.
qty рецептуры всегда нормализован в базовую единицу ингредиента. Поэтому вложенное
списание, снимки stockConsumption v1, старые возвраты и приёмки используют прежние
числа. Конверсия массы в объём/штуки запрещена. Составной товар считается одной
продаваемой позицией; выход полуфабриката в кг/л пока не поддерживается.
Тип товара с назначенными единицами или зависимостями защищён от смены во избежание
несовместимости рецептур. Для другого типа создаётся отдельный товар.

Минимальный остаток — подсказка карточки/каталога, без блокировки продаж или
автоматической закупки. Артикул доступен в поиске каталога. Заметка локальная,
не попадает в чек/меню, но входит в резервную копию вместе с products.
Приёмки и заказы поставщику остаются в базовых единицах; подписи уточнены.
Цена продажи и касса не пересчитываются. Сеть и фото-путь v130.19 не меняются.
Нельзя считать поля displayUnit указанием новых единиц для старого stockConsumption.

38 тестов проверяют совместимость, сохранение/перезапуск, пересчёт и продажи/возвраты.
Визуальный тест и полная iOS-сборка не подтверждены; требуется физический iPad.


## v130.21 — заказы поставщикам и приёмка по ТТН

Пользователь согласовал средневзвешенную себестоимость. Новый заказ хранит requestVersion=1,
в строках requestedQty/requestedUnit (упаковка, коробка или совместимая физическая
единица), stockUnit, packSize и expectedQty. qty сохраняет ожидаемое базовое количество,
либо 0 при неизвестном размере упаковки; expectedQty=null явно означает отсутствие
оценки. Эти числа не являются приходом на склад. Старые заказы без новых полей
читаются прежним способом. Текст и нативный PDF используют снимок заказанного количества.
Количество разных единиц больше не суммируется как штуки. PDF принимает quantityText,
для старого payload сохранён fallback. Кассовый printReceipt не изменён.

В карточке простого товара можно задать purchaseUnit и purchasePackSize (размер в
неизменной базовой единице); в конкретном заказе значения можно переопределить.
После создания себестоимость readonly; saveProduct дополнительно сохраняет текущую
себестоимость независимо от поля UI. Смена единицы отображения не меняет её базовое
значение. Новая себестоимость при приходе: (остаток × себестоимость + сумма ТТН) /
(остаток + фактический приход), без округления себестоимости до двух знаков.
Суммы документов отображаются с точностью валюты. Для отрицательного остатка в
расчёте стоимости старый объём принимается равным нулю. Товары без учёта остатков
не увеличивают остаток; их себестоимость берётся из принятой строки.

Приёмка — единый экран для заказа и закупки без заказа. Поля ТТН: supplierId,
invoiceNumber, invoiceDate; в строках invoiceQty/invoiceUnit/invoiceUnitPrice как
снимок документа, qty/unitCost/totalCost по-прежнему в базовых единицах. При изменении
цены пересчитывается сумма; при вводе суммы выводится цена. Сумма строки является
основанием расчёта себестоимости. Все строки проверяются до изменения склада.
Непоставленная позиция задаётся как 0/0. Можно добавить дополнительные строки.
Предварительное подтверждение показывает итоговый остаток и себестоимость; при
финальном подтверждении расчёт повторяется по актуальному остатку. Повторное
подтверждение уже принятого заказа не создаёт повторный приход.

Явное «Сохранить черновик и выйти» сохраняет receivingDraftV2 в заказе; для приёмки
без заказа используется новый локальный ключ receivingDraft (с префиксом prilavok_).
Это единственный новый ключ; новых сетевых вызовов/автосинхронизации нет. Старые
receivingDraft поддерживаются при открытии. Незавершённые черновики не входят в
резервную копию; подтверждённые ТТН входят в существующий exportBackup. Автосохранения
ввода нет. Сохранение черновика проверяет ошибку адаптера и не закрывает экран при
ошибке. Проводка сохраняет существующие products/purchaseOrders/receivings через
saveKey; это прежнее сохранение в несколько ключей, не новая ACID-транзакция.

Заказ закрывается по факту одной подтверждённой приёмки, в том числе с расхождением;
остаток заказа автоматически не переносится. При неизвестном весе упаковки нельзя
вычислить недовоз по весу; нулевая поставка отмечается как расхождение. Полностью
нулевую ТТН подтверждать нельзя — остаётся черновик. Исторические чеки, себестоимость
продаж, старые приёмки и stockConsumption не мигрируются.

53 автоматических теста пройдены, JavaScript и Swift синтаксически проверены.
Полная iOS-сборка, визуальная проверка нового UI и нативного PDF требуют iPad;
не считать версию подтверждённой до теста пользователя. Commit/push не разрешены.


## v130.30 — отчёт складского учёта

Раздел Analytics → «Складской учёт» читает только локальные products, receivings и orders. Отчёт и фильтры не сохраняются в хранилище, ключи и JSON не меняются. Доступ к странице и экспорту ограничен действующей проверкой администратора смены.

- Поступления берутся из проведённых приёмок, кроме adminDeleted. Период определяется timestamp приёмки, а не invoiceDate документа. Поддержаны старые однотоварные записи и items.
- Расход при продаже — только сохранённый stockConsumption версии 1. Возврат учитывается по returnedAt, независимо от даты продажи. Текущая рецептура не используется для восстановления старых чеков.
- Остатки на начало и конец восстанавливаются от текущего склада вычитанием известных последующих движений. Это расчёт, а не полный исторический регистр: ручные правки не журналировались.
- Поступления имеют фактическую сумму строки; расход, возвраты и остаток на конец оцениваются по текущей себестоимости. Сохранённая себестоимость позиций чека показывается отдельно до возвратов.
- Удалённые товары и товары без учёта остатков не получают выдуманного текущего остатка. Неизвестная стоимость обозначается прочерком, пробелы истории указаны явно. НДС не рассчитывается без исходных ставок.
- PDF формируется локально через новый action shareWarehouseReport существующего native bridge. Пользователь сам выбирает действие в системном меню Поделиться. Сеть и синхронизация не вызываются.

Это аналитический отчёт по имеющимся данным, а не новый журнал движений или юридически значимый бухгалтерский регистр. Для точного исторического учёта нужен отдельный согласованный этап хранения неизменяемых движений и их стоимости.


## v130.44 — локальная навигация кассы

Дополнительный ключ `prilavok_posNavigation` через существующий storage adapter: `{version:1,categories:[{category,items:[{type,id,parentId,name?}]}]}`. Существующие ключи и JSON товаров/раскладки не меняются. При отсутствии ключа используется прежний порядок sortOrder, все товары остаются в корне категории; автоматического переноса или очистки данных нет. Изменённая навигация сохраняется до обновления state, отказ записи оставляет прежнее состояние.

Папки имеют один уровень внутри категории. В папках используются ссылки productId, перемещение не меняет product.category, рецептуру, stock или WEB. Новые товары добавляются в корень; удалённые/сменившие категорию ссылки не скрывают действующие товары. Переименование категории переносит её локальную навигацию. Удаление папки возвращает товары в корень. Внутри категории поиск видит также товары из её папок.

Резервная копия версии 10 добавляет необязательный posNavigation. Импорт старой копии без него восстанавливает категории без папок. Старые версии приложения не отображают новые папки; товары/основная раскладка остаются читаемыми, но повторный экспорт из старой версии не сохраняет папки. Синхронизация и backend не получают новый ключ автоматически.
