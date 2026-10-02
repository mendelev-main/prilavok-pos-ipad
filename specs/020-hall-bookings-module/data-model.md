# Data model: модуль зала и бронирований

## HallTable (`hallTables`)

- `id`, `number`, `name`.
- `shape`: `square` или `rectangle`.
- `rotation`: угол в градусах.
- `x`, `y`: процентные координаты карты.

## Booking (`bookings`)

- `id`, `tableId`, `date`.
- `startAt`, `endAt`: ISO timestamps.
- `guestName`, `phone`, `guests`, `note`.
- `status`: active `confirmed` или `cancelled`.
- `createdAt`.

## State transitions

- Booking: отсутствует → confirmed → cancelled.
- Table: создаётся → редактируется/перемещается → удаляется вместе со связанными bookings.
- Hall edit mode: off → on → off; drag context существует только во время pointer sequence.

## Invariants

1. Активные брони одного стола не пересекаются.
2. `endA === startB` не является пересечением.
3. Отменённые брони не занимают стол и не отображаются в активном списке.
4. Удаление стола удаляет его bookings и очищает selection.
5. Формат существующих записей не нормализуется и не мигрируется при загрузке.
