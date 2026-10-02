# Runtime boundary: WEB orders

## Provided global API

Компонент сохраняет существующие глобальные точки вызова:

- `startWebOrderEvents()`
- `openWebEventsModal()` и `openWebOrder(id)`
- `selectWebReadyEstimate(value)` и `editWebReadyTime()`
- `acceptWebOrder(id, readyEstimate)`
- `recoverWebAcceptanceJournal()`
- `saveLegacyWebReadyEstimate(id, readyEstimate)`
- `markCurrentWebOrderReady()`
- `testWebOrder()`

## Consumed runtime API

Компонент использует уже созданные `state`, `window.PrilavokCore.Storage`, `loadKey`, `saveKey`,
`markStorageBroken`, `networkConfigFromState`, функции отрисовки/модальных окон, складскую проверку,
кухонную печать и стандартные browser API `EventSource`, `fetch`, `AbortController`.

`pos.html` обязан загрузить компонент после объявления этих зависимостей и до вызова `loadAll()`.

## Persistent contract

- Storage prefix remains `prilavok_`.
- Keys remain `webEvents`, `webOrderAcceptances`, and `parked`.
- Existing JSON records remain readable without migration.
- Persistence order remains journal preparation → parked save → journal local stage → backend ACK.

## Network contract

- Event stream: `GET /api/orders/events?deviceKey=...`.
- Acceptance: `POST /api/orders/{id}/accept` with `X-Device-Key` and `readyEstimate`.
- The component does not publish the catalog and does not start manual synchronization.

## Failure contract

- Missing network configuration or EventSource leaves local POS available.
- Malformed incoming events are ignored.
- Storage failure is surfaced and cannot be reported as a successful local acceptance.
- Backend failure retains local state for recovery and must not duplicate kitchen printing.
