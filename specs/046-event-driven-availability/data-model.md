# Data Model

No new persisted entity is introduced. Existing `webAvailabilityRevision` remains monotonic. Snapshot
items remain `{externalId, quantity}`, where `null` means untracked stock and zero blocks availability.
The pending generation and active request are runtime-only state.
