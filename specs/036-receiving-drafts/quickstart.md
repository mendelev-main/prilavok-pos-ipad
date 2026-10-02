# Quickstart: проверка этапа 036

```bash
node --test tests/*.test.cjs
node --check PrilavokPOS/Web/js/features/receiving-drafts.js
xcodebuild -project PrilavokPOS.xcodeproj -scheme PrilavokPOS -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/mpos-receiving-drafts-derived CODE_SIGNING_ALLOWED=NO build
```

В финальной iPad-матрице: открыть заказ, выйти позже, перезапустить и продолжить; проверить неизвестную упаковку и нулевой недовоз; сохранить standalone draft; завершить реальную приёмку отдельным сценарием.
