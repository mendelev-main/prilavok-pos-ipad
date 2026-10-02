# Runtime Boundary Contract

`Web/js/features/receiving-drafts.js` предоставляет прежние globals:

- `receivingDraftForOrder`
- `openReceivingDocument`
- `saveReceivingDraft`

Модуль загружается после базовых supplier/access helpers и до `loadAll()`. Он вызывает существующие render/input/page helpers только во время пользовательского действия, после загрузки всех scripts.
