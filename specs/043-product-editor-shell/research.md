# Research

## Граница

Переносятся `openProductModal`, snapshot/dirty functions, finish/request/save shell, section navigation,
usage rendering, summary and full editor markup. `productDependsOn`, `saveProduct`, WEB persistence and
all photo functions остаются в `pos.html`.

## Load order

`product-editor.js` загружается после `product-configuration.js`; все scripts загружаются до
`loadAll()`. Вызовы `saveProduct` и photo functions происходят только после пользовательского действия,
когда основной inline runtime уже определён.

## Catalog actions

`openProductModal('${p.id}')` и `toggleProductOnline('${p.id}')` небезопасны для совместимого
строкового ID. Используется уже введённый `productInlineArg`.
