# Quickstart: проверка split loyalty guard

1. Select a valid gift and open split; parts must equal the discounted total.
2. Return zero rewards from loyalty and verify no split is created.
3. Simulate offline, choose continue, and verify parts equal the full total.
4. Double-tap while validation is pending and verify one request/action.
5. Run full automated tests and Simulator build.

## Completed evidence

- Full Node suite: 243/243 PASS.
- Simulator build without signing: BUILD SUCCEEDED.
- Built `pos.html` differs only by the existing version stamp and native notification injection.
