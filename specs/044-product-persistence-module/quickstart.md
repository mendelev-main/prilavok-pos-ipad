# Quickstart

```bash
node --check PrilavokPOS/Web/js/features/product-persistence.js
node --test tests/product-stock.test.cjs
node --test tests/*.test.cjs
node specs/003-ipad-production-audit/diagnostics.cjs
xcodebuild -project PrilavokPOS.xcodeproj -scheme PrilavokPOS -sdk iphonesimulator \
  -configuration Debug -derivedDataPath /tmp/mpos-derived-044 CODE_SIGNING_ALLOWED=NO build
```
