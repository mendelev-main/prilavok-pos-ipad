# Implementation Plan: ограниченный lifecycle LAN-печати

**Branch**: `main` | **Spec**: [spec.md](spec.md)

1. Перенести реестр и callbacks `NWConnection` на выделенную serial queue.
2. Свести success, failure и timeout к одному idempotent finish.
3. Добавить deadline для `.waiting` и полуоткрытого TCP-соединения.
4. Собрать приложение и сохранить hardware/TSan сценарии до финальной приёмки.
