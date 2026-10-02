# Runtime Boundary Contract

`product-editor.js` отвечает за editor lifecycle и markup. Он вызывает существующие domain helpers,
`saveProduct` и photo functions, но не владеет их persistence/network behavior.

Product IDs в HTML actions передаются через `productInlineArg(value)`, определённый модулем
конфигурации как JSON serialization с последующим attribute escaping.
