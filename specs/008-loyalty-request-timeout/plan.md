# Implementation Plan: ограничение ожидания программы лояльности

**Branch**: `main` | **Spec**: [spec.md](spec.md)

1. Обернуть `loyaltyApi()` в общий пятисекундный `AbortController` deadline.
2. Сохранить обработку HTTP-ошибок и внешней отмены.
3. Проверить никогда не завершающийся запрос через реальный payment guard.

Ручная проверка offline loyalty выполняется в финальном acceptance.
