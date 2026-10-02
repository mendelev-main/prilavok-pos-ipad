# Results: единый scene lifecycle

**Baseline**: `2b03a82` · **Version**: 130.52 · **Date**: 2026-10-02

## Изменение

- `AppDelegate` больше не создаёт legacy `UIWindow` и `POSViewController`.
- Единственным владельцем окна остаётся `SceneDelegate`, уже указанный в Info.plist.
- Single-scene настройка и пользовательское поведение не изменены.

## Автоматизированные проверки

- Node suite: PASS, 194/194.
- Новый lifecycle ownership test: PASS, 1/1.
- Debug Simulator build без signing: `BUILD SUCCEEDED`.
- Info.plist, `project.pbxproj` и версия 130.52 не изменены.

Launch/background/foreground и подтверждение deinit остаются в
[iPad checklist](../003-ipad-production-audit/ipad-checklist.md#7-lan-принтер-и-native-bridge)
и выполняются в финальном прогоне.
