# Results: проверка лояльности перед split-оплатой

**Baseline**: `31f1eb8` · **Version**: 130.52 · **Date**: 2026-10-02

## Реализовано

- New split creation uses the same bounded loyalty revalidation as cash/card.
- A confirmed reward creates parts from the discounted total.
- An unavailable reward leaves split state empty, so no payment part can be accepted.
- Offline continuation clears the reward, refreshes the payment screen and creates parts from the
  recalculated full total.
- Cancel clears the deferred action without changing the reward or payment state.
- Repeated taps while validation is in flight produce one request and one split action.
- A restored durable draft with paid parts retains its accepted amount and bypasses recalculation.

## Совместимость

- No storage key, JSON shape, endpoint, timer or sync behavior changed.
- Existing cash/card offline flow continues through the same guard callbacks.
- Version remains 130.52; `project.pbxproj` is unchanged.

## Автоматизированные проверки

- Full Node suite and JavaScript syntax: PASS, 243/243.
- New tests cover valid, unavailable, offline continue, offline cancel and concurrent-tap paths.
- Debug Simulator build without signing: `BUILD SUCCEEDED`.
- Built `pos.html` contains the source change and differs only by the existing version stamp and
  `notification-native.js` injection.

## Отложенная проверка на iPad

В финальном прогоне проверить split с доступным подарком, недоступным подарком и отключённым
интернетом; в offline-варианте подтвердить, что и чек, и обе части показывают полную сумму.
