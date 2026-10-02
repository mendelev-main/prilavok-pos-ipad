# Implementation Plan: единый scene lifecycle

**Branch**: `main` | **Spec**: [spec.md](spec.md)

1. Удалить создание legacy-окна из `AppDelegate`.
2. Сохранить существующий single-scene manifest и `SceneDelegate` без изменений.
3. Добавить source-level regression test и собрать приложение.

Lifecycle на устройстве проверяется в финальной приёмке.
