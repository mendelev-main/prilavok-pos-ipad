# Implementation Plan

Добавить Push Notifications entitlement для Debug/Release, запрос системного разрешения и native bridge
регистрации device token. JS передаёт существующие backend URL/device key и настройку звука; token не
попадает в POS localStorage.

Backend добавляет таблицу активных device token и transactional outbox. AFTER INSERT trigger создаёт
ровно одно push-задание внутри транзакции заказа. Worker получает задания через `FOR UPDATE SKIP LOCKED`,
отправляет privacy-safe APNs alert по HTTP/2 и помечает доставку либо назначает bounded retry.

В foreground push вызывает выбранный POS-звук и показывает баннер без системного sound, а mutation
observer отключает дублирующий сигнал после успешной APNs-настройки. В background/lock screen звук
воспроизводит iPadOS из APNs payload.

Проверки: Node/PGlite, JavaScript syntax, Swift compile через unsigned Simulator build, entitlement в
готовом bundle, полный regression suite. Финальный physical test выполняется после настройки APNs secrets.
