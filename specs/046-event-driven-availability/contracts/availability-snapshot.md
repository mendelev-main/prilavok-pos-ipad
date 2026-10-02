# Availability Snapshot Contract

`POST /api/availability/snapshot` keeps the existing headers and payload:

```json
{
  "version": 1,
  "revision": 1,
  "sampledAt": "ISO-8601",
  "items": [{"externalId": "product-id", "quantity": 0}]
}
```

The POS sends only persisted product IDs and quantities. It sends no names, prices or catalog data.
Backend order creation must reject quantities above the newest accepted snapshot; that validation is an
external contract and is not implemented in the current iPad repository.
