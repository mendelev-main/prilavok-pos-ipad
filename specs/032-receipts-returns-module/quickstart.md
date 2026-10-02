# Quickstart: проверка чеков и возвратов

1. Parse inline runtime and every production module.
2. Verify `receipts.js` loads after `payment.js` and before `loadAll()` with all legacy globals.
3. Run full tests for cash/card/split receipts, return journal recovery, duplicate return, historical/legacy stock restoration, loyalty reversal and reprint.
4. Verify a 10 Br cash sale and full return leave a 100 Br opening drawer at 100 Br.
5. Verify invalid totals and cash parts produce no state or storage mutation.
6. Build Simulator without signing and compare bundled `receipts.js` with source.
7. Defer physical return, shift close and LAN reprint to final iPad acceptance.
