# Runtime Boundary: receiving UI

Classic script `PrilavokPOS/Web/js/features/receiving-ui.js` сохраняет глобальные функции:

- `viewReceivingModal`
- `receivingHistoryMarkup`
- `toggleReceivingHistory`
- `renderReceivingScreen`
- `receivingDocumentInput`
- `updateInvoiceLine`
- `addInvoiceProduct`
- `removeInvoiceLine`
- `receivingDocumentMarkup`
- `toggleReceivingPanel`
- `finishReceivingPage`
- `renderReceivingDocument`

Load order: suppliers → purchase orders → receiving UI → receiving drafts → receiving completion.

