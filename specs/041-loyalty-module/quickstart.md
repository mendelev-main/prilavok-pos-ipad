# Quickstart: проверка этапа 041

```bash
node --test tests/*.test.cjs
find PrilavokPOS/Web/js -name '*.js' -print0 | xargs -0 -n1 node --check
node specs/003-ipad-production-audit/diagnostics.cjs
xcodebuild -project PrilavokPOS.xcodeproj -scheme PrilavokPOS \
  -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

Физическая loyalty-проверка остаётся в итоговой iPad acceptance-матрице.

