# Quickstart: проверка этапа 034

```bash
node --test tests/*.test.cjs
node --check PrilavokPOS/Web/js/features/employees.js
xcodebuild -project PrilavokPOS.xcodeproj -scheme PrilavokPOS -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/mpos-employees-derived CODE_SIGNING_ALLOWED=NO build
```

На финальной физической матрице: создать сотрудника, изменить имя/телефон, выдать и снять admin с паролем, проверить запрет удаления себя и администратора, удалить обычного сотрудника и перезапустить приложение после каждого сохранения.
