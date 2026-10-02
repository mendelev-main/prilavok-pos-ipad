# Data Model: аналитика

## Analytics Range

- `from`: начало локальной даты в миллисекундах.
- `to`: конец локальной даты в миллисекундах.

## Local Analytics Result

- `orders`: невозвращённые чеки выбранного периода.
- `revenue`, `cash`, `card`, `cost`, `profit`, `avg`: числовые показатели.
- `employees`: имя и выручка, по убыванию.
- `categories`: имя, выручка и количество, по убыванию количества.
- `products`: имя, выручка и количество, по убыванию количества.

## Loyalty Analytics State

- `loyaltyAnalyticsKey`: период последнего запроса.
- `loyaltyAnalytics`: server payload либо `{error: true}`.

## Persistence

Компонент не вводит новых ключей и не записывает аналитические данные в localStorage.
Источники — существующие runtime-массивы `orders`, `shifts` и `products`.
