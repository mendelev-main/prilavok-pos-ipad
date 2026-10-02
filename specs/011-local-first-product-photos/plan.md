# Implementation Plan: local-first фотографии товаров

**Branch**: `main` | **Spec**: [spec.md](spec.md)

1. Добавить native sandbox-хранилище JPEG и read-only `mpos-image` scheme.
2. Передавать стабильный local image ID вместе с preview.
3. Сохранять карточку и pending-маркер до upload.
4. После upload обновлять только поля фотографии в свежем снимке каталога.
5. Добавить timeout, ручной retry при следующем сохранении и regression tests.

Выбор фото и offline/relaunch проверяются на физическом iPad в финальной приёмке.
