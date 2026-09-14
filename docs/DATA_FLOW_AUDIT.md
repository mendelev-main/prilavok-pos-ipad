# Data Flow Audit

## Current architecture

The iPad application keeps the working POS experience inside `PrilavokPOS/pos.html`.
The file remains the active runtime source and must not be split without testing on iPad.

## Target architecture

```
iPad POS
  |
  +-- Local storage (source of truth)
  |
  +-- Business modules
  |
  +-- Sync queue
          |
          v
       Backend/Web
```

## Migration rules

1. Do not replace the current working data flow in one step.
2. Extract adapters first, then move logic gradually.
3. Every migration step must keep iPad offline operation working.
4. Local POS state has priority over remote state.

## Planned modules

- storage: local persistence
- sync: background synchronization
- products: catalog and categories
- sales: cart and checkout
- receipts: history and printing data
- shifts: cash movements and shift lifecycle
- settings: configuration

## Current checkpoint

v130.11 starts documentation of boundaries before code extraction.
