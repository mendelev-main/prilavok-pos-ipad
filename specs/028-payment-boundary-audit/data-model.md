# Data Model: payment boundary audit

No data model changes are made in this audit.

The inspected atomic payment set is:

- `products`: post-sale stock values;
- `orders`: the appended immutable receipt snapshot;
- `shifts`: delivery cash movement when applicable;
- `currentOrderSession`: the empty session written with the completed receipt;
- `criticalStorageJournal`: temporary recovery metadata cleared after completion.

`state._splitPayments` is transient and is the source of the confirmed durability defect.

