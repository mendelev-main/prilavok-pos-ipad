# Optional loyalty and privacy protocol 1

The website captures a separate unchecked choice. Only Telegram verification of the checkout activates membership. Existing customers are not enrolled implicitly. Subsequent unchecked orders do not withdraw membership. Withdrawal requires verified phone ownership and expires rewards/progress; 24 months without a qualifying paid purchase ends membership. Replayed events do not renew it. A pending checkout created before withdrawal cannot reenroll the old membership.

POS captures `loyaltyConsentVersion` and purchase timestamp in the paid receipt before any network call. A stale/missing version is never replaced using a later membership. Ordinary offline sales remain available; gifts require a fresh online membership/balance check. Existing paid receipt totals and stock consumption stay unchanged. Server instructions apply through the critical storage journal before acknowledgements; acknowledgements retry independently of the download cursor.

`privacyRules` is a new device-local storage key, not a replacement for existing keys or a backup schema change. Restoring a backup requires the configured backend to replay deletion instructions before committing the restored data. The backup's cached gift selection is invalidated. External backup files, Telegram chats, paper receipts and provider copies cannot be erased by tablet JavaScript; the operator must include them in retention procedures.

Runtime module: `Web/js/features/privacy.js`. Routine sync every 30 seconds while visible and on reconnect; financial completion of web orders is persisted in the paid order and retried. A device advertises protocol readiness after applying server instructions. Device acceptance and any periods offline remain operational responsibilities.

Validation: shared and Android tests run in Actions only. Physical acceptance must check opt-in, ordinary order without opt-in, withdrawal, reward disappearance, reconnect and backup restoration on the actual tablet. No local Android JS/JVM test, lint or APK assembly was run.
