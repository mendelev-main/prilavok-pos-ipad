# Quickstart: проверка split recovery

1. Confirm one split part and inspect `prilavok_currentOrderSession.paymentDraft`.
2. Restart and verify the split screen reopens with that part paid.
3. Inject journal failure and verify the part remains unpaid.
4. Complete all parts and verify one receipt plus an empty session without draft.
5. Run full automated tests and Simulator build.
6. Defer the physical cash/card restart scenario to final iPad acceptance.

## Completed evidence

- Full Node suite: 238/238 PASS.
- Simulator build without signing: BUILD SUCCEEDED.
- Built `cart-composition.js` checksum matches source exactly.
- Built `pos.html` differs from source only by the existing version stamp and native notification
  script injection.
