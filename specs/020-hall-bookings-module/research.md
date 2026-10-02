# Research: модуль зала и бронирований

## Полный непрерывный домен

**Decision**: Перенести блок от `bookingDateTime` до `renderBookingsScreen` целиком.

**Rationale**: В блок входят единая временная модель, CRUD, drag и UI; соседние analytics и WEB orders
остаются отдельными доменами.

**Alternatives considered**: Разделение hall layout и bookings сейчас оставило бы тесные взаимные
вызовы между двумя новыми файлами и увеличило бы поверхность первого этапа.

## Совместимый глобальный API

**Decision**: Использовать классический script до `loadAll()` без переименования функций.

**Rationale**: Root render и inline handlers уже зависят от этих глобальных имён.

## Тестовое покрытие до дальнейших изменений

**Decision**: Добавить contract, overlap/sorting и persistence/cascade tests одновременно с переносом.

**Rationale**: У домена не было отдельных автоматизированных проверок. Новые тесты фиксируют
существующее поведение, не меняя его.

## Существующая persistence-модель

**Decision**: Сохранить `saveHall()` и `saveBookings()` как совместимые фасады над `saveKey`.

**Rationale**: Изменение транзакционности нескольких ключей должно быть отдельным safety-срезом с
явным recovery contract.
