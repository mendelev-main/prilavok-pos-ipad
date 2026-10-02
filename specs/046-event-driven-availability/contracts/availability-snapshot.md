# Availability Snapshot Contract

`POST /api/availability/snapshot` keeps the existing headers and payload:

```json
{
  "version": 1,
  "revision": 1,
  "sampledAt": "ISO-8601",
  "items": [{"externalId": "product-id", "quantity": 0}],
  "settledWebOrderIds": ["backend-order-id"]
}
```

The POS sends only persisted product IDs and quantities. After a WEB order is paid locally, its
backend ID is included in `settledWebOrderIds`; existing paid receipt history restores the ID after an
app restart. The backend can then stop subtracting that reservation. It sends no names, prices or
catalog data.

Backend order creation rejects quantities above the newest effective availability. Confirmation and
reservation are atomic. Missing snapshot/device identity fails closed; local POS work remains unaffected.
