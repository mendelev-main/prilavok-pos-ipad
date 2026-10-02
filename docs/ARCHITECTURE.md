# M POS: текущая архитектура

Это reference-документ о фактической системе. Он не хранит backlog и task-status. Постоянные инварианты задаёт [constitution](../.specify/memory/constitution.md), будущие срезы — [roadmap](../ROADMAP.md), а проверяемые изменения — `specs/`.

## Продукт и runtime

M POS — offline-first iPad POS для кафе. Публичное имя — **M POS**; исторические технические имена `PrilavokPOS`, bundle identifier, имена файлов и storage-prefix `prilavok_` сохраняются для совместимости.

```text
Swift/UIKit application
  └─ WKWebView
      ├─ PrilavokPOS/pos.html: UI и основная business logic
      ├─ Web/js/core/storage.js: storage adapter
      ├─ Web/js/features/web-orders.js: входящие WEB-заказы, local-first acceptance и ACK/recovery
      ├─ Web/js/features/inventory.js: график, черновик, фиксация и завершение инвентаризации
      ├─ Web/js/features/warehouse-reporting.js: read-only складской отчёт и PDF/XLSX payload
      ├─ Web/js/features/analytics.js: локальные KPI продаж и отображение loyalty-аналитики
      ├─ Web/js/features/product-catalog.js: CSV-импорт, поиск, сортировка и таблица товаров
      ├─ Web/js/features/product-categories.js: category CRUD и оформление плиток
      ├─ Web/js/features/pos-navigation.js: папки, плитки и раскладка рабочей зоны
      ├─ Web/js/features/cart-presentation.js: текущий заказ, скидки и параметры доставки
      ├─ Web/js/features/hall-bookings.js: карта зала, столы и локальные бронирования
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

## Данные и offline-first

- iPad POS — авторитетный источник операционных данных.
- Продажи, чеки, смены, товары, рецептуры, приёмка и основная касса работают без интернета.
- Логические storage-ключи пишутся с префиксом `prilavok_`; формат и ключи не меняются без миграции.
- `loadKey`/`saveKey` — совместимый фасад над `Web/js/core/storage.js`.
- Оплата, возврат, приёмка и backup-import используют `prilavok_criticalStorageJournal`: после прерывания заранее сохранённый снимок доводится до целого состояния на следующем запуске.
- Backup v12 включает основные операционные сущности, навигацию, инвентаризацию, зал/брони,
  незавершённый текущий заказ и исторические настройки принтеров; импорт сначала валидируется.

## Домены POS

- Касса: текущий заказ, cash/card/split, доставка, отложенные чеки, скидки, печать и возврат.
- Товары: простые/составные, вложенные рецептуры, модификаторы, единицы, остатки, себестоимость, WEB-публикация, CSV-import, категории и папки.
- Склад: заказы поставщикам, приёмка, средневзвешенная себестоимость, инвентаризация, отчёт PDF/XLSX.
- Смены и сотрудники: открытие/закрытие, кассовые движения, роль administrator, защита самоудаления.
- Лояльность: клиент привязывается к оплаченному чеку; pending сохраняется до сети; подарочные единицы не участвуют в новом накоплении; sale завершается до reversal.
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
