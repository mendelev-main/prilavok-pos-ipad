# Research

## Existing boundary

`saveProduct` валидирует форму, строит совместимую копию товара, вызывает configuration helpers,
пишет полный snapshot через `PrilavokCore.Storage.set`, только затем публикует `state.products` и
пытается загрузить фото. При ошибке upload сохраняются `localImageId` и `imageUploadPending`.

## Extraction decision

Функцию следует переносить целиком: разделение local commit и upload между этапами увеличило бы риск
изменить порядок отказов. Photo picker, canvas compression и native bridge callbacks являются другой
ответственностью и остаются inline до отдельного этапа.

## Compatibility evidence

Существующие regressions проверяют storage failure, offline upload, pending retry, unknown fields,
единицы, себестоимость, остатки, рецептуры и модификаторы. Module fixture должен запускать тот же код
в новом script без изменения тестовых сценариев.
