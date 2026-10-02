# Research

## Граница

Переносятся `PRODUCT_UNITS`, unit/configuration helpers, `switchProductType`, `renderTypeFields`,
recipe component editor, modifier editor и stock/no-stock unlock helpers. `openProductModal`, shell,
snapshot, `saveProduct`, photo functions и dependency check остаются inline.

## Совместимость

`saveProduct` продолжает вызывать те же `saveProductConfiguration`, `validateModifierGroups` и
`normalizeModifierGroup`. Модуль не читает и не пишет storage самостоятельно. Classic script сохраняет
прежние глобальные function bindings для HTML handlers и других feature scripts.

## Риск inline actions

`renderComponentOptions`, `renderModifierProductPickerList` и `openModifierSelection` вставляли product
ID внутрь одинарной JavaScript-строки. HTML escaping недостаточно: браузер декодирует entity перед
исполнением. Решение — `JSON.stringify(String(value))`, затем `escapeAttr` всего аргумента.
