# Runtime boundary: durable split payment

- `completeSplitPayment(index)` persists the proposed paid state before publishing it to memory.
- `loadAll()` restores only a strictly valid draft matching the current receipt total.
- `openPaymentModal()` resumes a restored draft instead of offering full payment again.
- Back controls reject silent abandonment once a paid part exists.
- `finalizePayment()` validates the final array and clears `currentOrderSession` through its existing
  multi-key journal.

