# Runtime Boundary Contract

`Web/js/features/employees.js` экспортирует в глобальную область прежние обработчики:

- `employeeShortName`, `employeeDisplayName`
- `openEmployeeModal`, `toggleEmployeeAdminPassword`, `saveEmployee`
- `showEmployeeAdminInfo`, `employeeDeletionAllowed`, `deleteEmployee`, `confirmDeleteEmployee`

Модуль загружается после `shifts.js`, поскольку delete protection читает текущую смену, и до `loadAll()`. Inline UI и остальные feature scripts продолжают вызывать прежние имена.
