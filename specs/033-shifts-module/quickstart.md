# Quickstart: проверка кассовых смен

1. Parse inline runtime and every production module.
2. Verify `shifts.js` loads before payment/receipts/startup and exposes legacy globals.
3. Run open/movement/close journal failure and recovery tests.
4. Run the mixed shift: cash/card/split, cash return, deposit, withdrawal and exact close.
5. Run corrupt opening/drawer tests and confirm no mutation or storage write.
6. Build Simulator without signing and compare bundled `shifts.js` with source.
7. Defer real cash counting, Telegram and LAN shift print to final iPad acceptance.
