# Quickstart

```bash
node --check PrilavokPOS/Web/js/features/product-configuration.js
node --test tests/product-stock.test.cjs
node --test tests/*.test.cjs
node specs/003-ipad-production-audit/diagnostics.cjs
xcodebuild -project PrilavokPOS.xcodeproj -scheme PrilavokPOS -sdk iphonesimulator \
  -configuration Debug -derivedDataPath /tmp/mpos-derived-042 CODE_SIGNING_ALLOWED=NO build
```

Audit diagnostics are historical reproducers: completed fixes produce `reproduced: false` and the
script intentionally exits non-zero while any historical defect is no longer reproducible.
