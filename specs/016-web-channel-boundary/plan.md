# Implementation Plan: граница входящих WEB-каналов

**Branch**: `main` | **Spec**: [spec.md](spec.md)

1. Зафиксировать EventSource URL, persistence и отсутствие исходящего upload.
2. Зафиксировать явный UI-вызов `/api/menu/sync` и разрешённый post-sync availability snapshot.
3. Повторно проверить ACK/retry, reconnect и десятиминутный availability contract.
4. Не менять runtime-поведение до live iPad/backend integration test.
