# Implementation Plan

1. Добавить совместимое поле `ownerChatId` в Telegram-настройки POS и колонку `telegram_owner_chat_id` в `devices`.
2. Расширить ручное сохранение Telegram-настроек, сохранив порядок local-first.
3. Добавить краткоживущий backend broker: bot request → SSE → POS response.
4. Рассчитать текущую смену на POS существующими правилами `shiftTotals` и сохранёнными строками чеков.
5. Добавить владельцу кнопку в существующий процесс `project_bot` без второго poller/webhook.
6. Проверить авторизацию, offline timeout, закрытую смену, суммы оплат и группировки.
