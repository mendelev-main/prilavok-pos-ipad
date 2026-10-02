# Quickstart: проверка payment module

1. Parse inline runtime and every production module.
2. Verify `payment.js` loads before startup and exports the legacy globals.
3. Run full tests for payment journal, split recovery, loyalty, stock, receipt and printing.
4. Build Simulator without signing.
5. Compare bundled `payment.js` with source.
6. Defer physical cash/card/split/printer checks to final iPad acceptance.

## Completed evidence

- Mechanical comparison with the previous inline block: exact match.
- Full Node suite: 244/244 PASS.
- Simulator build without signing: BUILD SUCCEEDED.
- Bundled `payment.js` SHA-256 matches source.
