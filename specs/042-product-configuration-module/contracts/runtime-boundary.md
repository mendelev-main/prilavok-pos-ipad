# Runtime Boundary Contract

`product-configuration.js` exports its existing API through classic-script global bindings. It may read
editor draft state and render editor fragments, but it does not persist products, upload photos, publish
menu data or start network activity. `saveProduct` remains the sole product commit boundary.

Inline arguments derived from product data use:

```js
escapeAttr(JSON.stringify(String(value ?? '')))
```
