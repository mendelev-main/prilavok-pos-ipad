# Runtime boundary: hall and bookings

## Provided global API

Компонент сохраняет существующие booking time helpers, CRUD столов и броней, edit-mode/pointer
handlers, modal actions и `renderBookingsScreen()`.

Основные точки: `bookingWindow`, `tableBookings`, `tableBusyAt`, `createHallTable`,
`confirmDeleteHallTable`, `saveNewBooking`, `saveEditedBooking`, `cancelBooking`,
`hallPointerStart/Move/End`, `renderBookingsScreen`.

## Consumed runtime API

Компонент использует `state`, `saveKey`, `uid`, `localDateString`, render/modal/flash helpers,
escaping и browser DOM/pointer APIs. Он загружается до `loadAll()`.

## Persistent contract

- Prefix remains `prilavok_`.
- Keys remain `hallTables` and `bookings`.
- Existing table and booking fields remain unchanged.
- No network operation or synchronization is introduced.
