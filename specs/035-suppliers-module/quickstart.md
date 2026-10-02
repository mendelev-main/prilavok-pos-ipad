# Quickstart: проверка этапа 035

```bash
node --test tests/*.test.cjs
node --check PrilavokPOS/Web/js/features/suppliers.js
xcodebuild -project PrilavokPOS.xcodeproj -scheme PrilavokPOS -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/mpos-suppliers-derived CODE_SIGNING_ALLOWED=NO build
```

В финальной iPad-матрице: создать поставщика, изменить имя и набор товаров, перезапустить приложение, удалить обычную справочную запись администратором и убедиться, что старые заказы/приёмки сохранили имя.
