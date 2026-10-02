# Research: модуль интерфейса приёмки

На baseline `5f4a79a` `viewReceivingModal` экранирует supplier, invoice number/date and product name,
но выводит `invoiceQty ?? qty` напрямую. Вложенные rows из backup не проходят deep schema
validation, поэтому строковое значение может разорвать HTML карточки истории.

Repository-wide search показал, что `addReceivingLine` и `removeReceivingLine` имеют только места
объявления. Текущий интерфейс новой приёмки использует `receivingDocumentMarkup`,
`addInvoiceProduct` и `removeInvoiceLine`.

Classic scripts разделяют один global runtime в WKWebView, поэтому перенос сохраняет существующие
inline handlers и связи между `purchase-orders.js`, `receiving-ui.js`, `receiving-drafts.js` и
`receiving.js` без bundler или сетевой загрузки.

