# M POS: текущая архитектура

Это reference-документ о фактической системе. Он не хранит backlog и task-status. Постоянные инварианты задаёт [constitution](../.specify/memory/constitution.md), будущие срезы — [roadmap](../ROADMAP.md), а проверяемые изменения — `specs/`.

## Продукт и runtime

M POS — offline-first iPad POS для кафе. Публичное имя — **M POS**; исторические технические имена `PrilavokPOS`, bundle identifier, имена файлов и storage-prefix `prilavok_` сохраняются для совместимости.

```text
Swift/UIKit application
  └─ WKWebView
      ├─ PrilavokPOS/pos.html: UI и основная business logic
      ├─ Web/js/core/storage.js: storage adapter
      ├─ Web/js/features/shifts.js: смены, кассовые итоги, движения и отчёт
      ├─ Web/js/features/employees.js: сотрудники, локальные роли и защищённое сохранение
      ├─ Web/js/features/loyalty.js: клиенты, подарки, начисление/reversal и администрирование
      ├─ Web/js/features/product-configuration.js: единицы, рецептуры и редактор модификаторов
      ├─ Web/js/features/product-persistence.js: local-first сохранение товара и WEB-признак
      ├─ Web/js/features/product-editor.js: lifecycle, dirty-state и разметка карточки товара
      ├─ Web/js/features/suppliers.js: справочник поставщиков и связи с товарами
      ├─ Web/js/features/purchase-orders.js: заказы поставщикам и их локальная история
      ├─ Web/js/features/receiving-ui.js: экран, история и редактор документа приёмки
      ├─ Web/js/features/receiving-drafts.js: начало, повторное открытие и сохранение черновика приёмки
      ├─ Web/js/features/web-orders.js: входящие WEB-заказы, local-first acceptance и ACK/recovery
      ├─ Web/js/features/inventory.js: график, черновик, фиксация и завершение инвентаризации
      ├─ Web/js/features/warehouse-reporting.js: read-only складской отчёт и PDF/XLSX payload
      ├─ Web/js/features/analytics.js: локальные KPI продаж и отображение loyalty-аналитики
      ├─ Web/js/features/product-catalog.js: CSV-импорт, поиск, сортировка и таблица товаров
      ├─ Web/js/features/product-categories.js: category CRUD и оформление плиток
      ├─ Web/js/features/pos-navigation.js: папки, плитки и раскладка рабочей зоны
      ├─ Web/js/features/cart-presentation.js: текущий заказ, скидки и параметры доставки
      ├─ Web/js/features/cart-composition.js: добавление, модификаторы, количество и удаление строк
      ├─ Web/js/features/parked-orders.js: атомарная парковка, восстановление и удаление заказов
      ├─ Web/js/features/payment.js: cash/card/split, durable draft, проведение и оплаченный чек
      ├─ Web/js/features/receipts.js: история чеков, LAN reprint handoff и атомарный полный возврат
      ├─ Web/js/features/hall-bookings.js: карта зала, столы и локальные бронирования
      ├─ Web/js/features/backup.js: export, validation и journaled import резервной копии
      ├─ network-printer.js: JS-граница LAN-печати
      └─ notification-native.js: native notifications

PrilavokPOSApp.swift / SceneDelegate.swift
  ├─ lifecycle и WKWebView bridge
  ├─ photo picker / image processing
  ├─ native share, PDF и XLSX
  └─ Telegram/native callbacks

NetworkPrinterManager.swift
  └─ LAN printing через NWConnection
```

Большая часть JS пока остаётся в `pos.html`. Модули в `PrilavokPOS/Web` подключаются постепенно по
одному домену. Feature-компоненты загружаются после основного runtime и до `loadAll()`, сохраняя
прежний глобальный API для inline-обработчиков. Инвентаризация продолжает использовать общий
critical storage journal. `warehouse-reporting.js` только читает локальные движения и формирует
совместимый payload для существующих native PDF/XLSX и Telegram-путей. `hall-bookings.js` сохраняет
прежний глобальный API карты зала и работает с прежними ключами `hallTables` и `bookings`.
`analytics.js` рассчитывает показатели из локальных чеков; существующий read центральных loyalty KPI
остаётся необязательным и при сетевой ошибке не блокирует локальный отчёт. `product-catalog.js`
сохраняет additive local-first импорт и presentation-only поиск/сортировку прежнего каталога.
`product-categories.js` поддерживает прежние category references в товарах, layout и POS-навигации.
`pos-navigation.js` нормализует прежний `posNavigation`, управляет папками и размещением плиток,
не изменяя товары или остатки; root layout продолжает храниться в прежнем `layout`.
`cart-presentation.js` отображает текущий заказ и редактирует его существующую локальную сессию;
проверка остатков, парковка, оплата, проведение чека и печать остаются в основном runtime.
`cart-composition.js` формирует строки заказа только после aggregate stock validation и сохраняет
прежнюю локальную сессию; parking/payment/receipt остаются отдельной критической границей.
`parked-orders.js` проводит park, resume и delete через существующий critical storage journal;
память меняется только после устойчивой локальной записи, а kitchen print запускается после park.
`payment.js` сохраняет прежние cash/card/split screens, loyalty guard и атомарное проведение продажи.
`receipts.js` использует сохранённый при продаже снимок списания, проводит остатки/чек/кассу одним
critical journal и передаёт повторную печать существующему LAN printer path. Физический баланс кассы
считает наличный возврат один раз, хотя он остаётся отдельным движением для аудита.
`shifts.js` владеет доступом к текущей смене, кассовыми итогами, открытием/закрытием, внесением/
изъятием, экраном истории и payload отчёта. Все изменения смены сначала проходят existing critical
journal; Telegram и печать запускаются после commit. Некорректный производный остаток блокирует новую
финансовую операцию, не переписывая сохранённые данные.
`employees.js` владеет отображением и CRUD сотрудников. Создание, изменение и удаление сначала
записывают полный снимок прежнего `prilavok_employees`, а затем публикуют его в памяти; при ошибке
storage UI сохраняет исходное состояние и позволяет повторить действие. Действующие роли, пароль и
ограничения удаления не изменены.
`loyalty.js` владеет поиском и привязкой клиента, расчётом подарка, публикацией оплаченной
продажи, повтором pending-операции, reversal и административными экранами. Сетевой сбой не блокирует
локальную оплату; endpoint, timeout, payload и локальные поля чека сохранены. Backend ID и названия в
inline actions сериализуются как JSON и затем экранируются для HTML-атрибута.
`product-configuration.js` владеет преобразованием единиц, редактором состава, модификаторами и
разблокировкой складских полей карточки. Он не записывает storage и не выполняет сеть: прежний
`saveProduct` остаётся границей commit в `product-persistence.js`, а photo picker path остаётся в
основном runtime. Product ID в
редакторе и выборе модификаторов сериализуются как JSON и экранируются для HTML-атрибута.
`product-persistence.js` владеет проверкой и сохранением карточки, dependency check и WEB-признаком.
Полный snapshot товаров сначала записывается через storage adapter и только потом публикуется в
памяти; необязательный upload фото выполняется после local commit и не отменяет его при ошибке сети.
Формат товара, ключ storage, роль администратора и ручная синхронизация меню не изменены.
`product-editor.js` владеет открытием, закрытием, dirty-state, навигацией, summary и основной
разметкой карточки. Обработка выбора и сжатия фото остаётся в основном runtime. Строки
каталога передают product ID в open/keyboard/WEB actions через JSON serialization и attribute escaping.
`suppliers.js` владеет справочником поставщиков и их связями с простыми товарами. CRUD сначала
записывает полный снимок прежнего `prilavok_suppliers`, а затем публикует его в памяти. Исторические
заказы и приёмки сохраняют собственные `supplierId`/`supplierName` и при удалении справочника не
переписываются.
`purchase-orders.js` владеет созданием, удалением, отображением, историей и передачей заказов
поставщикам. Создание и удаление используют прежний critical journal и общий guard; durable result
отделён от presentation, поэтому сбой открытия карточки не превращает уже сохранённый заказ в ложный
failure. Идентификаторы из совместимых backup экранируются в inline actions.
`receiving-ui.js` владеет экраном ожидающих поставок, историей и редактором документа. Он сохраняет
прежний глобальный API и порядок загрузки, не читает и не записывает storage самостоятельно. Значение
количества из совместимой исторической записи выводится как текст, поэтому повреждённый backup не
может внедрить разметку в карточку приёмки.
`receiving-drafts.js` владеет границей начала и отложенного продолжения приёмки. Новый order draft
сначала записывается в снимке `purchaseOrders`, после чего публикуется и открывается; сохранённый
draft открывается без повторной записи. Standalone draft сохраняет прежний ключ `receivingDraft`.
`receiving.js` владеет проверкой строк, средневзвешенной себестоимостью и проведением прихода.
Приёмка занимает общий `criticalOperationBusy`, записывает товары, заказ и историю одним critical
journal и только затем публикует снимки в runtime. Это исключает пересечение с оплатой, возвратом,
сменой, инвентаризацией и другими критическими локальными операциями.
`backup.js` экспортирует schema v12 и восстанавливает storage-часть через существующий critical
journal. Отсутствующие optional collections старых версий сохраняют прежние defaults; если такой
раздел присутствует с неверным типом, импорт прекращается до первой записи.

## Данные и offline-first

- iPad POS — авторитетный источник операционных данных.
- Продажи, чеки, смены, товары, рецептуры, приёмка и основная касса работают без интернета.
- Логические storage-ключи пишутся с префиксом `prilavok_`; формат и ключи не меняются без миграции.
- `loadKey`/`saveKey` — совместимый фасад над `Web/js/core/storage.js`.
- Оплата, возврат, приёмка и backup-import используют `prilavok_criticalStorageJournal`: после прерывания заранее сохранённый снимок доводится до целого состояния на следующем запуске.
- После принятия первой части раздельной оплаты versioned `paymentDraft` сохраняется как необязательное
  поле существующего `currentOrderSession`. Каждая новая оплаченная часть сначала проходит через
  critical journal; запуск восстанавливает тот же payment flow, а финальный чек атомарно очищает draft.
- Backup v12 включает основные операционные сущности, навигацию, инвентаризацию, зал/брони,
  незавершённый текущий заказ и исторические настройки принтеров; импорт сначала валидируется.

## Домены POS

- Касса: текущий заказ, cash/card/split, доставка, отложенные чеки, скидки, печать и возврат.
- Товары: простые/составные, вложенные рецептуры, модификаторы, единицы, остатки, себестоимость, WEB-публикация, CSV-import, категории и папки.
- Склад: заказы поставщикам, приёмка, средневзвешенная себестоимость, инвентаризация, отчёт PDF/XLSX.
- Смены и сотрудники: открытие/закрытие, кассовые движения, роль administrator, защита самоудаления.
- Лояльность: клиент привязывается к оплаченному чеку; выбранный подарок проверяется до cash/card/split
  оплаты, а при недоступной сети локальную продажу можно продолжить без подарка; pending сохраняется
  до сети; подарочные единицы не участвуют в новом накоплении; sale завершается до reversal.
- Зал, бронирования, аналитика, складский учёт и настройки остаются локальными доменами.

## Сетевые границы

- Основное направление: POS → Backend → Web / Mini App.
- Полная публикация меню — только явной кнопкой в сетевых настройках.
- Согласованные узкие каналы: доступность остатков, operational snapshot/heartbeat/outbox, входящие WEB-события и ACK/retry, loyalty retry, Telegram-отчёты.
- Ни один сетевой канал не должен блокировать локальную продажу.
- Backend URL по умолчанию — `https://project-dubrovno.up.railway.app`; сохранённая на iPad конфигурация имеет приоритет.

## Backend

Backend — Node/Express в отдельном GitHub-репозитории, Railway runtime и Supabase/PostgreSQL. Меню, WEB-заказы, Telegram-подтверждение телефона, клиенты и loyalty обслуживаются центрально. Создание подтверждённого WEB-заказа и замена правил loyalty выполняются атомарными restricted RPC.

## Печать и отчёты

- Штатный путь печати — сетевой ESC/POS; Bluetooth и HTTP Print Bridge не используются.
- Есть отдельные шаблоны платёжного и кухонного чека, category routing, comments, copies и reprint.
- Складские и закупочные отчёты экспортируются через native PDF/XLSX/share; ежемесячный складской PDF может уходить в настроенный Telegram-чат.

## Версия и проверки

Текущая сборка — **130.52**. Debug и Release используют Xcode `MARKETING_VERSION`; build phase штампует то же значение в заголовок Настроек. Отдельный roadmap-срез R2 должен устранить дублирование между build configurations.

Автоматические тесты покрывают JS syntax, кассу, рецептуры, возвраты, storage failures, приёмку, аналитику, импорт, навигацию, WEB и loyalty. Самый новый датированный baseline и границы доказательств указаны в [audit results](../specs/001-production-audit/results.md). Симулятор и unit tests не заменяют приёмку на физическом iPad.
