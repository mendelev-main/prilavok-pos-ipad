# Prilavok — Telegram Phone Verification Specification

Status: NEXT FEATURE / planned implementation

## 1. Goal

Protect online ordering from anonymous order spam by requiring phone ownership verification through a Telegram bot before an untrusted customer can submit an online order to Prilavok POS.

Telegram verification is intended to be the primary low-cost verification channel. SMS verification may be added later as a fallback, but is not required for the first implementation.

This feature applies to the customer web ordering flow. It must not change the offline operation of the iPad POS.

## 2. Core rule

A phone number typed into the web order form is NOT considered verified by itself.

For Telegram verification, the phone number is considered verified only when all of the following are true:

1. The backend created a valid one-time verification session for the current browser/order flow.
2. The customer opened the official Prilavok Telegram bot through the verification link generated for that session.
3. The customer explicitly shared their own phone contact using Telegram's contact-sharing mechanism (`request_contact`).
4. The backend verified that the received contact belongs to the Telegram user who sent it.
5. The normalized Telegram phone number matches the normalized phone number entered in the web order form.
6. The verification session has not expired, been consumed, or been invalidated.

A phone number manually typed as a Telegram message must NEVER count as verification.

## 3. Target user flow

1. Customer adds products to the cart.
2. Customer opens checkout.
3. Customer enters phone number and optional comment.
4. If the current customer/device does not already have a valid trusted verification, the site displays `Подтвердить через Telegram`.
5. The web frontend asks the backend to create a verification session.
6. Backend creates a cryptographically random, single-use verification token with a short expiration time.
7. Site opens the official Telegram bot using a deep link containing only an opaque verification token, for example conceptually: `t.me/<bot>?start=<opaque_token>`.
8. Bot identifies the pending verification session from the token.
9. Bot asks the user to press `Поделиться номером телефона` using a Telegram `request_contact` keyboard button.
10. Telegram sends the contact to the bot.
11. Backend validates the Telegram update and contact ownership.
12. Backend normalizes the received phone to canonical international form and compares it to the phone stored in the verification session.
13. On exact normalized match, backend marks the verification session as verified and binds it to the Telegram user ID.
14. Web page checks the verification status and displays `✓ Номер подтверждён через Telegram`.
15. Only then may the order submission endpoint accept the order, unless another explicitly approved fallback flow exists.
16. Once the order is accepted, the verification session cannot be reused to submit additional arbitrary orders.

## 4. Architecture

Conceptual flow:

```text
Customer Web
    |
    | create verification
    v
Prilavok Backend
    |
    | one-time opaque token
    v
Telegram Bot
    |
    | request_contact
    v
Telegram user shares own contact
    |
    v
Prilavok Backend
    |
    | phone + Telegram identity verified
    v
Web checkout becomes verified
    |
    v
Order endpoint
    |
    v
iPad POS / online-order delivery mechanism
```

Verification is a backend security decision. The browser must never be able to mark itself verified by changing JavaScript/localStorage values.

## 5. Required backend data

The exact database technology may change, but the logical model should support at least:

### phone_verification_sessions

- `id`
- `token_hash` — store a hash where practical rather than the raw deep-link token
- `phone_normalized`
- `status` — `pending`, `verified`, `consumed`, `expired`, `cancelled`
- `telegram_user_id` — nullable until verification succeeds
- `created_at`
- `expires_at`
- `verified_at`
- `consumed_at`
- optional browser/session binding identifier
- optional order-draft identifier
- attempt counters / abuse metadata

Raw verification tokens must be high entropy, unpredictable and short-lived.

## 6. Phone normalization

Both the number entered on the website and the number received from Telegram must be normalized server-side before comparison.

For Belarusian customers the UI may accept convenient forms such as:

- `+375297103220`
- `375297103220`
- `8 029 710-32-20`

but the backend should compare a canonical international representation, preferably E.164 where valid.

Frontend formatting is convenience only. Backend validation is authoritative.

## 7. Telegram contact ownership validation

The implementation must not trust an arbitrary contact object blindly.

When Telegram supplies a contact, the backend/bot must verify that the contact represents the sender's own contact where Telegram supplies the necessary sender/user relationship information. A contact forwarded/shared for another person must not verify the session.

Telegram bot tokens and webhook secrets must exist only on the backend/environment configuration and must never be embedded in the public website or iPad POS bundle.

## 8. Verification session lifetime

Initial recommended policy:

- pending deep-link verification session: approximately 10 minutes;
- token: single-use;
- successful session: consumed when used for its intended checkout/order authorization;
- expired/consumed token: cannot be reactivated.

Exact limits can be tuned after production usage.

## 9. Remembering verified customers

We should avoid forcing a regular customer to open Telegram for every order.

Future/initial implementation may issue a separate signed trusted-device verification credential after successful Telegram verification.

Recommended initial trust lifetime: 30–90 days, configurable.

Important rules:

- the trusted credential must be issued and validated by the backend;
- storing `phoneVerified=true` in localStorage is NOT sufficient;
- changing the checkout phone number invalidates trust for that phone unless the new number has independently been verified;
- server-side revocation must remain possible;
- sensitive raw Telegram data should not be exposed to the browser unnecessarily.

## 10. Anti-spam behavior

Telegram verification is one layer, not the entire abuse defense.

The order API should additionally support rate limiting using a combination of signals such as:

- verified Telegram user ID;
- verified normalized phone number;
- IP/network signal where appropriate;
- browser/session identifier;
- order frequency;
- repeated identical order fingerprints.

A user must not be able to bypass limits simply by editing the phone field.

Suggested starting limits must be conservative and configurable rather than hard-coded into UI code.

## 11. Protect the verification system itself

An attacker must not be able to spam verification sessions or abuse the bot.

Required protections:

- rate-limit verification-session creation;
- limit active pending sessions per browser/IP/phone;
- expire unused sessions automatically;
- reject replayed/consumed tokens;
- limit failed phone-match attempts;
- do not reveal unnecessary information about whether a phone or Telegram account already exists;
- log abuse/security events without logging secrets.

## 12. Web UX

Checkout should remain simple.

Recommended state:

```text
Телефон
[ +375 __ ___-__-__ ]

Комментарий
[ ... ]

[ Подтвердить через Telegram ]
```

After Telegram verification:

```text
✓ Номер подтверждён через Telegram

[ Оформить заказ ]
```

The UI must clearly handle:

- waiting for Telegram confirmation;
- phone mismatch;
- verification expired;
- verification cancelled;
- Telegram not installed / deep-link problem;
- backend unavailable;
- already verified customer/device.

The order/cart data must not be lost when the customer temporarily leaves the browser to open Telegram.

## 13. Phone mismatch flow

If the Telegram number differs from the website number, the backend must NOT verify the session.

The UI should explain the issue without exposing sensitive account information, for example:

`Номер в Telegram не совпадает с номером, указанным в заказе. Проверьте номер и попробуйте снова.`

The user can return to checkout, correct the phone number and start a new verification session.

## 14. Telegram unavailable

First implementation may use Telegram as the only strong phone verification mechanism if approved for launch.

Architecture must nevertheless allow a future fallback channel, for example SMS OTP, without rewriting the order domain.

Verification should therefore be represented generically by the backend as a verified phone/identity result rather than baking Telegram-specific checks directly into every order handler.

Possible future methods:

- `telegram`
- `sms_otp`
- administrator/manual exception if explicitly designed

## 15. Relationship to POS offline-first architecture

This feature is for INTERNET CUSTOMER ORDERS and must not weaken the POS offline-first rules.

- The iPad POS does not need Telegram to perform local sales.
- Local POS checkout must never depend on Telegram verification.
- Telegram verification occurs on the web/backend side before an online order is accepted for delivery to POS.
- Failure of Telegram/backend must not block normal local POS operations.
- The iPad remains authoritative for its local operational data according to `OFFLINE_FIRST_ARCHITECTURE.md`.

## 16. Privacy / data minimization

Store only data necessary for verification, abuse prevention and the customer/order relationship.

At minimum:

- do not store Telegram access credentials client-side;
- do not request Telegram permissions unrelated to verification;
- do not request chat history;
- do not treat Telegram verification as permission for marketing messages;
- avoid retaining raw verification tokens after they are no longer needed;
- define retention for expired verification sessions during implementation.

## 17. Security boundary

The final order endpoint must independently check authorization/verification on the backend.

It is NOT acceptable to rely on:

- a disabled/enabled HTML button;
- frontend JavaScript state;
- URL query parameters claiming verification;
- localStorage flag alone;
- a phone number merely present in a Telegram message.

The backend is responsible for deciding whether the order is eligible to be accepted.

## 18. Suggested implementation stages

### Stage 1 — Telegram bot verification MVP

- bot exists;
- backend creates one-time session;
- Telegram deep link opens correct session;
- bot requests user's own contact;
- backend matches phone;
- web displays verification result;
- order endpoint requires valid verification.

### Stage 2 — anti-spam hardening

- rate limits;
- Telegram-user limits;
- phone limits;
- session/IP limits;
- duplicate-order protection;
- security logging.

### Stage 3 — trusted returning customer

- signed trusted-device credential;
- configurable 30–90 day validity;
- server-side revocation;
- transparent checkout for returning verified customers.

### Stage 4 — optional fallback

- SMS OTP or another approved verification channel if real customer usage shows it is necessary.

## 19. Acceptance criteria for MVP

Feature is ready for release only when all of these are true:

1. An unverified browser cannot submit a protected online order by directly calling the order API.
2. Manually typing a phone number to the bot does not verify it.
3. Sharing the Telegram user's own contact can verify the matching checkout number.
4. A different Telegram contact/phone does not verify the checkout.
5. Expired tokens fail.
6. Reused tokens fail.
7. Verification for one checkout/session cannot be trivially transferred to an unrelated phone/order.
8. Leaving the site for Telegram does not erase the cart.
9. Backend restart does not incorrectly turn pending sessions into verified sessions.
10. Telegram outage/failure does not affect local iPad POS sales.
11. Rate limits prevent practical high-frequency order spam and verification-session spam.
12. Secrets are not present in frontend source or the iPad web bundle.

## 20. Non-goals for the first version

Not required initially:

- SMS provider integration;
- Telegram Mini App;
- customer loyalty system;
- marketing subscriptions;
- customer chat history access;
- automatic messages unrelated to the order;
- changing POS local/offline checkout behavior.

## 21. Future opportunities

Once a verified Telegram identity is safely associated with a customer, later separately approved features could include:

- order status notifications (`Принят`, `Готовится`, `Готов`);
- repeat-order shortcut;
- order history;
- Telegram Mini App entry;
- customer account/loyalty features.

These are future features and must not be silently enabled merely because the customer verified their phone.

## 22. Implementation note

Before coding, verify the current Telegram Bot API behavior and current backend/order architecture. Do not implement from assumptions in this document if Telegram's API contract has changed.

The feature should be added incrementally and tested end-to-end before it becomes mandatory for production orders.
