# Feature Specification: Payment presentation

**Roadmap**: R12

**Baseline**: M POS 130.54

**Date**: 2026-10-02

## Goal

Стандартизировать интерфейс обычной и разделённой оплаты, сохранив без изменений денежные расчёты, журналирование и завершение продажи.

## Requirements

1. `payment.js` не содержит inline style attributes.
2. Обычная и разделённая цифровые клавиатуры используют семантический `hidden` с прежними моментами показа и скрытия.
3. Чек, сумма, сдача и действия оплаты используют именованные presentation classes.
4. Окна наличной и карточной части имеют единую визуальную иерархию.
5. Итоговый чек использует общие классы строк, скидок, комментариев и платежей.
6. Cash/card/split calculations, loyalty guard, delivery checks, critical storage, stock mutation and printing не меняются.
7. Полная автоматизированная матрица и simulator build проходят.

## Success criteria

- В `payment.js` остаётся 0 inline style attributes.
- Основная, разделённая и подтверждающая поверхности не выходят за контейнер.
- Клавиатуры открываются и закрываются как прежде.
- Существующие payment, split, loyalty, receipt, stock и storage tests проходят.

## Out of scope

- Изменение способов оплаты и округления.
- Изменение порядка локального сохранения и печати.
- Изменение схемы чека или split draft.
