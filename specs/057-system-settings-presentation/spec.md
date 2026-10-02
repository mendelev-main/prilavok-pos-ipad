# Feature Specification: System and network settings presentation

**Roadmap**: R12

**Baseline**: M POS 130.54

**Date**: 2026-10-02

## Goal

Стандартизировать статическое оформление системных состояний, сетевых конфигураций, Telegram, выбора темы и подтверждения удаления внутри `pos.html` без изменения поведения приложения.

## User scenarios

1. Администратор открывает сетевые конфигурации и видит единообразные карточки синхронизации, LAN-принтера и Telegram.
2. Пользователь выбирает светлую или тёмную тему через стандартные кнопки без управляющих emoji.
3. Пользователь видит прежние состояния загрузки, смены и подтверждения удаления.

## Requirements

1. `pos.html` не содержит inline style attributes в markup и JavaScript templates.
2. Network, printer и Telegram layout использует именованные CSS-классы и существующие settings-компоненты.
3. Выбор темы сохраняет прежние обработчики и selected styling, но не использует emoji как управляющие иконки.
4. Ручная синхронизация, сохранение network/printer/Telegram, тестовые запросы и storage formats не меняются.
5. Полная автоматизированная матрица и simulator build проходят.

## Success criteria

- В `pos.html` остаётся 0 inline style attributes.
- Network и appearance screens корректны в светлой и тёмной темах.
- Существующие network, printer, Telegram, theme и delete handlers сохраняются.

## Out of scope

- Изменение сетевых URL, таймаутов и триггеров.
- Изменение ручной синхронизации меню.
- Изменение Telegram-уведомлений и LAN-печати.
- Изменение прав доступа или паролей.
