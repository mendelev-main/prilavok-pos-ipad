# Feature Specification: Design component alignment

**Roadmap**: R12

**Baseline**: M POS 130.54

**Date**: 2026-10-02

## Goal

Свести основные визуальные варианты switches, status colors, fields и заметных доменных кнопок к документированной дизайн-системе, а Manrope сделать доступным без интернета.

## Requirements

1. Полноразмерные switches используют общую геометрию и off-state token; compact WEB switch остаётся документированным плотным вариантом.
2. Success, warning, info и danger состояния используют semantic tokens обеих тем.
3. Основные поля используют standard или large control geometry tokens.
4. Заметные доменные действия в настройках, сменах, topbar и storage warning используют именованные классы и semantic variants.
5. Manrope хранится в bundle `Web/fonts`, загружается локально и сопровождается лицензией OFL.
6. Standalone control icons используют общий CSS icon set и доступные подписи; emoji не используются как управляющие знаки.
7. Визуальные изменения не меняют данные, бизнес-операции и сеть.

## Acceptance

- Интерфейс не обращается к Google Fonts.
- Локальный font resource входит в копируемую Xcode folder-reference `Web`.
- Design-system tests проверяют font и общую геометрию controls.
- Полная автоматизированная матрица проходит.
- Light/dark landscape browser smoke-check проходит; физический iPad остаётся финальной ручной проверкой.
