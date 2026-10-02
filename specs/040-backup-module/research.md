# Research: модуль резервных копий

На baseline `6fe3a25` функции `exportBackup`, `backupArray`, `validateBackupData`, `applyBackupData` и
`importBackup` находятся одним блоком в `pos.html`. Все call sites используют их глобальные имена.

`backupArray` возвращает `[]` и для отсутствующего необязательного поля, и для присутствующего поля
неверного типа. Первый случай нужен для совместимости старых backup, второй скрывает повреждение и
может очистить соответствующий раздел при успешном import.

Classic script сохраняет один global runtime WKWebView. Модуль можно загрузить после его runtime
dependencies и до `loadAll()` без bundler, сети или изменения native resource configuration.

