# Runtime boundary: split loyalty validation

- A new split with selected rewards invokes `beginPaymentWithLoyaltyGuard` once.
- Valid response continues to split creation.
- Invalid response leaves payment parts absent.
- Network failure opens the existing local-sale choice; continue clears redemptions before action.
- Paid durable split state bypasses new validation and remains immutable in value.

