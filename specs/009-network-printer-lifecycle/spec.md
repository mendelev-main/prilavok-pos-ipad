# Feature Specification: ограниченный lifecycle LAN-печати

**Feature Branch**: `main`  
**Created**: 2026-10-01  
**Status**: Automated acceptance complete; hardware/TSan acceptance deferred  
**Roadmap**: R1 Production acceptance 130.52  
**Finding**: A003-F08

## User Scenario

Если LAN-принтер недоступен или соединение остаётся в состоянии ожидания, задание завершается
понятной ошибкой за ограниченное время. Параллельные задания не повреждают список соединений и
каждое сообщает не более одного результата.

## Requirements

- **FR-001**: Создавать, обновлять и удалять соединения только на выделенной serial queue.
- **FR-002**: Отменять незавершённое задание через 10 секунд.
- **FR-003**: Обрабатывать `.waiting` через общий deadline.
- **FR-004**: Удалять state handler, отменять соединение и удалять его из реестра при завершении.
- **FR-005**: Отправлять ровно одно terminal-событие ошибки или успеха.
- **FR-006**: Не менять ESC/POS payload, настройки принтера и формат чека.

## Success Criteria

- **SC-001**: Simulator build проходит с serial queue и deadline.
- **SC-002**: Автоматические JS-тесты и синтаксические проверки не получают регрессий.
- **SC-003**: Недоступный IP и 20 параллельных заданий внесены в финальный iPad/TSan checklist.
