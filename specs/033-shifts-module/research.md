# Research: shift module boundary

## Selected boundary

The shift domain was distributed across five areas: current-shift access, totals/drawer balance, Telegram shift payloads, shift screen and operations, and historical report/reprint. These functions share one financial model and are consolidated into `Web/js/features/shifts.js`.

## Verified invariants

1. Open, movement and close clone `state.shifts`, commit through the critical journal and replace live state only after success.
2. Telegram, monthly report and shift printing start after the local commit.
3. Returned orders are excluded from net sales; saved refund movements remain auditable and are compensated once in physical drawer balance.
4. Cash/card/split payments, a cash return, deposit and withdrawal produce consistent screen and report totals.
5. The existing hardcoded administrator password policy is explicitly out of scope by user decision.

## Confirmed risk and decision

A non-finite legacy/corrupt opening cash, payment or movement could make drawer cash `Infinity`/`NaN`. Comparisons against that value could permit new movements, delivery, return or close. Keep the stored bytes untouched and reject the new operation whenever derived drawer cash is non-finite or negative.

## Load order

Load `shifts.js` first among feature scripts. Payment and receipts consume its globals; startup/render runs only after every feature script has loaded.
