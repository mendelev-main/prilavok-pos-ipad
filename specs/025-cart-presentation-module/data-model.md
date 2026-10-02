# Data Model: current order presentation

The component reads existing cart line fields and edits only existing session fields:
`qty`, `comment`, `discountId`, `orderLabel`, customer display fields, `orderType`,
`deliveryFee` and `deliveryTariffSelected`.

Persistence continues through the existing `currentOrderSession` shape. No schema or migration is introduced.
