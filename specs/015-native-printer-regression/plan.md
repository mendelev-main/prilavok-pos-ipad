# Implementation Plan: регрессия native bridge и печати

**Branch**: `main` | **Spec**: [spec.md](spec.md)

1. Зафиксировать фактический JS → WKScriptMessage → NetworkPrinterManager contract.
2. Добавить детерминированный harness для нескольких принтеров и перехвата payload.
3. Проверить auto/manual routing, категории, copies, comments и shift-close.
4. Удалить доказанно неиспользуемую обёртку `printReceipt` без изменения поведения.
5. Оставить raster, TCP 9100 и обрезчик для физической финальной проверки.
