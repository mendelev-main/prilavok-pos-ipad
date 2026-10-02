# Data Model: split payment draft

Optional field on existing `currentOrderSession`:

```json
{
  "paymentDraft": {
    "version": 1,
    "totalCents": 1000,
    "parts": [
      {"method": "cash", "amount": 4, "paid": true, "cashGiven": 5, "change": 1},
      {"method": "card", "amount": 6, "paid": false, "cashGiven": null, "change": null}
    ],
    "updatedAt": 0
  }
}
```

The field is omitted when no part is paid and from an empty completed-order session. Existing fields,
keys and receipt payment rows are unchanged. When a draft exists, the session also snapshots the
current `loyaltyPrograms` and `loyaltyRedemptions`, because those inputs define the already accepted
receipt total; old sessions without these optional fields remain valid.
