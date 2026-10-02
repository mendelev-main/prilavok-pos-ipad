# Data Model: модуль клиентов и лояльности

Новых сущностей, полей и миграций нет. Модуль использует существующие:

- transient `state.customer`, `loyaltyPrograms`, `loyaltyRedemptions`;
- order fields `loyaltySync`, `loyaltyReversal`, `loyaltyRewardAllocations`;
- current-order session loyalty snapshot для незавершённой split payment;
- backend customer, program, ledger and order representations.

Safe inline serialization меняет только HTML presentation действий.

