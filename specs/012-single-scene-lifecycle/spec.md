# Feature Specification: единый scene lifecycle

**Feature Branch**: `main`  
**Created**: 2026-10-02  
**Status**: Automated acceptance complete; device acceptance deferred  
**Roadmap**: R5 Единый scene lifecycle  
**Finding**: A003-F12

## User Scenario

При запуске iPadOS создаётся ровно одно окно и один `POSViewController`, поэтому фоновые таймеры,
WEB events и native bridge не дублируются скрытым экземпляром POS.

## Requirements

- **FR-001**: Оставить владельцем окна только `SceneDelegate`, указанный в scene manifest.
- **FR-002**: `AppDelegate` выполняет только application-level launch.
- **FR-003**: Не менять Info.plist, интерфейс или данные приложения.

## Success Criteria

- **SC-001**: Автоматическая проверка находит создание `POSViewController` только в SceneDelegate.
- **SC-002**: Debug Simulator build и полный Node suite проходят.
- **SC-003**: Launch/background/foreground и освобождение контроллера остаются в финальном iPad/Instruments прогоне.
