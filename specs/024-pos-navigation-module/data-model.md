# Data Model: POS navigation

## PosNavigation

`{ version: 1, categories: [{ category, items }] }`

Each item is either:
- folder: `{ type: "folder", id, name, parentId: "" }`
- product placement: `{ type: "product", id, parentId }`

Stored under logical key `posNavigation` with the unchanged `prilavok_` prefix.

## Layout

Existing object with `categoryOrder`, presentation maps and `tiles`. Tile position uses `col` and `row`. Stored under logical key `layout`.

No schema change or migration is part of this stage.
