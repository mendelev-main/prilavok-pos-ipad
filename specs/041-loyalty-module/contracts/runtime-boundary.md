# Runtime Boundary: loyalty

Classic script `PrilavokPOS/Web/js/features/loyalty.js` сохраняет customer, reward, lifecycle and
admin global functions, используемые HTML, analytics, parked orders, payment и receipts.

Load order: shifts → employees → loyalty → remaining feature modules → payment/receipts → startup.

Удаляемые legacy globals:

- `openLoyaltyAdminModalLegacy`
- `createLoyaltyProgram`

