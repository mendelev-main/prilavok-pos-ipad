# Runtime boundary: shifts module

## Provided globals

Current-shift access, shift order/totals/drawer calculations, Telegram shift reports, shift screen, open/close dialogs and commits, cash movements, history modal and shift report printing.

## Consumed globals

State, critical storage journal, employee helpers, receipt discount calculation, Telegram configuration, monthly warehouse report trigger, modal/render/format helpers and native printer bridges.

## Load order

Inline shared runtime → `shifts.js` → feature consumers including payment and receipts → `loadAll()`.

## Excluded

Employee CRUD/access redesign, payment finalization, return commit, Telegram transport settings and native printer implementation remain in their current owners.
