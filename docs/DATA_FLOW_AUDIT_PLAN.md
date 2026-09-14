# Data Flow Audit Plan

## Goal
Prepare Prilavok POS for offline-first architecture without changing current behavior.

## Rules

- iPad POS local data is the source of truth.
- Internet loss must not stop sales operations.
- Server data must never silently overwrite local POS state.
- Synchronization is a background process only.

## Audit Areas

### Products
- Product storage
- Categories
- Prices
- Stock balances

### Orders and Receipts
- Cart state
- Payments
- Discounts
- Comments
- Delivery orders

### Shifts
- Opening shift
- Cash movements
- Closing shift

### Synchronization
- API calls
- Conflict handling
- Offline queue

## Migration Rule

Move existing working logic only after its current behavior is documented and tested on iPad.
