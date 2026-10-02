# Data Model: кассовые смены

No persisted schema changes.

- Shift identity, employee snapshot, opening/closing timestamps, opening cash and counted cash are unchanged.
- `cashMovements` retains existing deposit/withdrawal/subtype rows.
- Orders remain linked by `shiftId`; no receipt fields are added.
- `shiftTotals`, refund compensation and drawer balance remain derived, non-persisted values.
- Telegram, PDF and printer report payload fields are unchanged.
