# Data Model: модуль резервных копий

Новых сущностей, ключей, полей и миграций нет.

- Export продолжает создавать JSON `version: 12`.
- Обязательные коллекции: `products`, `employees`, `shifts`, `orders`.
- Отсутствующие optional collections старых backup нормализуются в `[]`.
- Присутствующие optional collections должны быть массивами.
- Применение storage-части продолжает использовать `backup-import` critical journal.
- Printer settings остаются в существующем adapter contract.

