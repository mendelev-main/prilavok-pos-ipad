# Data Model

## POS `prilavok_telegram`

Добавляется optional-строка `ownerChatId`. Старые записи совместимы и получают пустое значение при загрузке.

## Backend `public.devices`

Добавляется nullable `telegram_owner_chat_id text` с проверкой `^[0-9]{1,20}$`.

## Временный отчёт

`generatedAt`, `shiftOpen`, `shiftOpenedAt`, `employeeName`, `currency`, `orders`, `revenue`, `cash`, `card`, `categories[]`, `products[]`. Backend ограничивает строки и массивы; в PostgreSQL отчёт не записывается.
