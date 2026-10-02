# Runtime boundary: analytics

## Provided global API

Компонент сохраняет period handlers, calculation helpers, chart renderers,
`loadLoyaltyAnalytics()` и `renderAnalyticsScreen()`.

Основные точки: `analyticsRange`, `setAnalyticsDate`, `setAnalyticsPreset`, `analyticsOrders`,
`analyticsData`, `renderAnalyticsBars`, `inventoryCostValue`, `loadLoyaltyAnalytics`,
`renderAnalyticsScreen`.

## Consumed runtime API

Компонент использует `state`, `localDateString`, `getProduct`, `currentShiftEmployeeIsAdmin`,
`stockQtyText`, `money`, escaping, modal/render/flash helpers и существующий `loyaltyApi`.
Он загружается после `warehouse-reporting.js` и до `loadAll()`.

## Persistent and network contract

- Локальные источники и формулы остаются неизменными.
- Новых storage writes или ключей нет.
- Единственный сетевой путь — существующий read loyalty KPI для администратора.
- Ошибка loyalty read остаётся локализованной в `state.loyaltyAnalytics.error`.
- Новые timers, retry и sync triggers не добавляются.
