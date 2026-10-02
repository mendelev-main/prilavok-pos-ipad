# Implementation Plan

1. Зафиксировать переходы loyalty engine модульными тестами.
2. Создать Supabase migration для нормализации балансов, ограничения программы и атомарной функции продажи.
3. Ограничить create/update/manual adjustment на backend.
4. Сформировать одно Telegram-сообщение с прогрессом всех затронутых программ.
5. Убрать настройку количества подарков из POS и ограничить выбор одним подарком.
6. Выполнить backend, POS и migration regression suites.
7. Применить migration, развернуть backend и проверить живой сценарий.
