# Runtime Boundary: backup

Classic script `PrilavokPOS/Web/js/features/backup.js` сохраняет глобальные функции:

- `exportBackup`
- `backupArray`
- `validateBackupData`
- `applyBackupData`
- `importBackup`

Модуль загружается после feature dependencies и до `loadAll()`.

