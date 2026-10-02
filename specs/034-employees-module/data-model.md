# Data Model: сотрудники

Сохраняется существующий массив `prilavok_employees`.

```text
Employee {
  id: string
  name: string
  phone: string
  role: "admin" | "employee"
  ...unknown legacy fields preserved on edit
}
```

Новая схема, migration или normalization не вводятся. Смены и чеки продолжают ссылаться на исторические `employeeId`/`employeeName`; удаление сотрудника их не изменяет.
