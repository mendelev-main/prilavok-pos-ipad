# Data Model

Новых сущностей и миграций нет.

- `products[].stockUnit`, `stockDisplayUnit`, `recipeYield`, `recipeUnit`, `recipeYieldManual` сохраняются без изменений.
- `products[].components[]`: прежние `productId`, `qty`, optional `displayUnit`.
- `products[].modifierGroups[]`: прежние group/option ID, limits, product link, POS name, quantity and price delta.
- Legacy products without unit fields keep their existing numeric interpretation.
