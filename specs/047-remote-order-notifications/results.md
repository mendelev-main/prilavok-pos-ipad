# Results

## Автоматическая проверка

- Backend: 61/61 Node/PGlite tests pass.
- iPad: 298/298 Node contract and regression tests pass.
- Unsigned Debug Simulator build: `BUILD SUCCEEDED`.
- `git diff --check`: pass в обоих репозиториях.
- Версия iPad build: 130.53.

## База данных

Production migrations `order_push_notifications` и `expire_stale_order_push_notifications` применены к
Supabase 2026-10-02. Проверено:

- token table, outbox table и order trigger существуют;
- `anon` не может регистрировать APNs token;
- `authenticated` не может забирать outbox jobs;
- `service_role` может забирать outbox jobs;
- delivery window 15 минут присутствует, устаревший backlog не отправляется.

RLS advisors содержат только ожидаемый информационный сигнал `rls_enabled_no_policy`: обе новые таблицы
полностью закрыты от client roles и предназначены только для backend service role.

## Осталось для физической приёмки

- Настроить Apple APNs key в Railway secrets.
- Установить 130.53 на физический iPad, разрешить уведомления и выполнить сценарии SC-003/SC-004.
