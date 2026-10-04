# Quickstart

```bash
node --test tests/*.test.cjs
xcodebuild -project PrilavokPOS.xcodeproj -scheme PrilavokPOS -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/mpos-owner-report CODE_SIGNING_ALLOWED=NO build
```

После установки: Сетевые настройки → Telegram → ID владельца → Сохранить. Владелец открывает бота командой `/start` и нажимает «Получить информацию».
