# Research: модуль клиентов и лояльности

На baseline `da62659` customer order flow находится рядом с session helpers, а admin loyalty UI —
в settings runtime. Payment, receipts, parked orders и analytics используют их глобальные функции.
Classic script после `shifts.js` и до dependent features сохраняет этот контракт.

`escapeAttr(value)` защищает HTML-разметку, но не формирует JavaScript literal. HTML parser декодирует
`&#39;` перед выполнением `onclick`, поэтому конструкция `fn('${escapeAttr(id)}')` небезопасна для
backend-controlled strings. Корректная граница: `escapeAttr(JSON.stringify(String(value)))`,
вставленная без дополнительных кавычек.

Repository-wide search подтвердил отсутствие рабочих call sites у
`openLoyaltyAdminModalLegacy` и `createLoyaltyProgram`.

