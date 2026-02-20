# Base de Datos - Cambios y Estructura

## 📋 Resumen de Cambios en BD

### Objetivo
Crear tablas locales en la BD del FEDI para gestionar usuarios y roles, eliminando la dependencia del sistema PERITOS para esta funcionalidad.

---

## 🗄️ Tablas Creadas

### 1. Tabla `cat_Roles`

**Propósito**: Catálogo de roles disponibles en el sistema FEDI.

**Reemplaza**: Consulta al sistema PERITOS para obtener roles.

**Estructura**:
```sql
CREATE TABLE [dbo].[cat_Roles] (
    [RolID] VARCHAR(50) NOT NULL,                      -- PK: Identificador único del rol
    [Sistema] VARCHAR(50) NOT NULL DEFAULT '0022FEDI-INT',
    [DescripcionRol] VARCHAR(200) NULL,
    [Activo] BIT NOT NULL DEFAULT 1,                   -- 1=Activo, 0=Inactivo
    [FechaCreacion] DATETIME NOT NULL DEFAULT GETDATE(),
    [CreadoPor] VARCHAR(100) NULL,
    [FechaModificacion] DATETIME NULL,
    [ModificadoPor] VARCHAR(100) NULL,
    CONSTRAINT [PK_cat_Roles] PRIMARY KEY CLUSTERED ([RolID] ASC)
);
```

**Datos insertados**:
| RolID | Descripción |
|-------|-------------|
| ROL_0022FEDI_USER | Usuario básico del FEDI - Acceso al sistema |
| ROL_0022FEDI_ADMIN | Administrador del FEDI - Gestión completa del sistema |
| ROL_0022FEDI_FIRMANTE | Usuario autorizado para firmar documentos electrónicamente |
| ROL_0022FEDI_CONSULTOR | Usuario de solo lectura - Consulta de documentos |
| ROL_0022FEDI_CARGADOR | Usuario autorizado para cargar documentos al sistema |
| ROL_0022FEDI_OBSERVADOR | Observador - Recibe notificaciones sin capacidad de firma |

**Total de filas**: 6

---

### 2. Tabla `tbl_UsuarioRol`

**Propósito**: Relación muchos-a-muchos entre usuarios (LDAP) y roles del FEDI.

**Reemplaza**: Consulta al sistema PERITOS para obtener qué usuarios tienen qué roles.

**Estructura**:
```sql
CREATE TABLE [dbo].[tbl_UsuarioRol] (
    [UsuarioRolID] INT IDENTITY(1,1) NOT NULL,         -- PK autoincremental
    [UsuarioID] VARCHAR(100) NOT NULL,                 -- Email del usuario (de LDAP)
    [RolID] VARCHAR(50) NOT NULL,                      -- FK a cat_Roles
    [Sistema] VARCHAR(50) NOT NULL DEFAULT '0022FEDI-INT',
    [Activo] BIT NOT NULL DEFAULT 1,                   -- 1=Activo, 0=Inactivo
    [FechaAsignacion] DATETIME NOT NULL DEFAULT GETDATE(),
    [AsignadoPor] VARCHAR(100) NULL,                   -- Usuario que asignó el rol
    [FechaBaja] DATETIME NULL,
    [BajaPor] VARCHAR(100) NULL,
    [Observaciones] VARCHAR(500) NULL,

    CONSTRAINT [PK_tbl_UsuarioRol] PRIMARY KEY CLUSTERED ([UsuarioRolID] ASC),
    CONSTRAINT [FK_UsuarioRol_Rol] FOREIGN KEY ([RolID])
        REFERENCES [dbo].[cat_Roles]([RolID]),
    CONSTRAINT [UQ_UsuarioRol] UNIQUE NONCLUSTERED ([UsuarioID], [RolID])
);
```

**Datos insertados** (usuario administrador DEV/QA):
| UsuarioRolID | UsuarioID | RolID | AsignadoPor |
|--------------|-----------|-------|-------------|
| 1 | dgtic.dds.ext023@ift.org.mx | ROL_0022FEDI_ADMIN | SYSTEM |
| 2 | dgtic.dds.ext023@ift.org.mx | ROL_0022FEDI_USER | SYSTEM |
| 3 | dgtic.dds.ext023@ift.org.mx | ROL_0022FEDI_FIRMANTE | SYSTEM |

**Total de filas**: 3

---

## 📊 Índices Creados

### 1. `IX_UsuarioRol_Usuario`
**Propósito**: Optimizar búsquedas por usuario (ej: "¿Qué roles tiene este usuario?")

```sql
CREATE NONCLUSTERED INDEX [IX_UsuarioRol_Usuario]
ON [dbo].[tbl_UsuarioRol] ([UsuarioID] ASC)
INCLUDE ([RolID], [Activo]);
```

**Consultas optimizadas**:
```sql
SELECT RolID FROM tbl_UsuarioRol WHERE UsuarioID = 'usuario@ift.org.mx' AND Activo = 1;
```

---

### 2. `IX_UsuarioRol_Rol`
**Propósito**: Optimizar búsquedas por rol (ej: "¿Qué usuarios tienen este rol?")

```sql
CREATE NONCLUSTERED INDEX [IX_UsuarioRol_Rol]
ON [dbo].[tbl_UsuarioRol] ([RolID] ASC)
INCLUDE ([UsuarioID], [Activo]);
```

**Consultas optimizadas**:
```sql
SELECT UsuarioID FROM tbl_UsuarioRol WHERE RolID = 'ROL_0022FEDI_FIRMANTE' AND Activo = 1;
```

---

### 3. `IX_UsuarioRol_Activo`
**Propósito**: Optimizar filtrado de usuarios activos

```sql
CREATE NONCLUSTERED INDEX [IX_UsuarioRol_Activo]
ON [dbo].[tbl_UsuarioRol] ([Activo] ASC, [UsuarioID] ASC);
```

**Consultas optimizadas**:
```sql
SELECT DISTINCT UsuarioID FROM tbl_UsuarioRol WHERE Activo = 1;
```

---

## 🔐 Constraints (Restricciones)

### Primary Keys (PKs)
1. **PK_cat_Roles**: `RolID` en tabla `cat_Roles`
2. **PK_tbl_UsuarioRol**: `UsuarioRolID` en tabla `tbl_UsuarioRol`

### Foreign Keys (FKs)
1. **FK_UsuarioRol_Rol**: `tbl_UsuarioRol.RolID` → `cat_Roles.RolID`
   - Garantiza que solo se pueden asignar roles existentes
   - Evita eliminación accidental de roles en uso

### Unique Constraints (UQs)
1. **UQ_UsuarioRol**: Combinación `(UsuarioID, RolID)` en `tbl_UsuarioRol`
   - Evita duplicados: un usuario no puede tener el mismo rol dos veces
   - Permite que un usuario tenga múltiples roles diferentes

---

## 📈 Estadísticas de la BD

### Tamaño estimado
```sql
SELECT
    t.name AS Tabla,
    SUM(p.rows) AS Filas,
    CAST(SUM(a.total_pages) * 8.0 / 1024 AS DECIMAL(10,2)) AS TamanoMB
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.name IN ('cat_Roles', 'tbl_UsuarioRol')
AND p.index_id IN (0,1)
GROUP BY t.name;
```

**Resultado esperado** (inicial):
| Tabla | Filas | TamañoMB |
|-------|-------|----------|
| cat_Roles | 6 | 0.01 |
| tbl_UsuarioRol | 3 | 0.01 |

---

## 🔄 Flujo de Datos

### ANTES (con PERITOS):
```
1. Usuario intenta acceder al sistema
2. FEDI consulta a PERITOS: "¿Qué roles tiene este usuario?"
   GET {autoRegistroUrl}/registro/consultas/roles/1/{usuario}/0015MSPERITOSDES-INT
3. PERITOS responde con roles
4. FEDI valida permisos
5. Usuario accede al sistema
```

**Problemas**:
- ❌ Dependencia de sistema externo
- ❌ Si PERITOS falla, FEDI no puede validar usuarios
- ❌ Latencia adicional por llamada HTTP

---

### DESPUÉS (con BD local):
```
1. Usuario intenta acceder al sistema
2. FEDI consulta BD local: "SELECT RolID FROM tbl_UsuarioRol WHERE UsuarioID = '...' AND Activo = 1"
3. BD responde con roles (consulta local instantánea)
4. FEDI valida permisos
5. Usuario accede al sistema
```

**Ventajas**:
- ✅ Independencia de sistemas externos
- ✅ Alta disponibilidad
- ✅ Consulta local (< 1ms)
- ✅ Transacciones atómicas con documentos

---

## 🔍 Consultas Útiles

### Ver todos los roles
```sql
SELECT * FROM cat_Roles WHERE Activo = 1 ORDER BY RolID;
```

### Ver todos los usuarios con roles
```sql
SELECT
    ur.UsuarioID,
    STRING_AGG(ur.RolID, ', ') AS Roles,
    COUNT(*) AS CantidadRoles
FROM tbl_UsuarioRol ur
WHERE ur.Activo = 1
GROUP BY ur.UsuarioID
ORDER BY ur.UsuarioID;
```

### Verificar si un usuario tiene un rol específico
```sql
SELECT COUNT(*) AS TieneRol
FROM tbl_UsuarioRol
WHERE UsuarioID = 'usuario@ift.org.mx'
AND RolID = 'ROL_0022FEDI_FIRMANTE'
AND Activo = 1;
-- Resultado: 1 = Tiene el rol, 0 = No tiene el rol
```

### Ver usuarios con rol de administrador
```sql
SELECT DISTINCT UsuarioID
FROM tbl_UsuarioRol
WHERE RolID = 'ROL_0022FEDI_ADMIN'
AND Activo = 1;
```

### Auditoría: Ver historial completo de un usuario
```sql
SELECT
    UsuarioRolID,
    RolID,
    CASE WHEN Activo = 1 THEN 'Activo' ELSE 'Inactivo' END AS Estado,
    FechaAsignacion,
    AsignadoPor,
    FechaBaja,
    BajaPor,
    Observaciones
FROM tbl_UsuarioRol
WHERE UsuarioID = 'dgtic.dds.ext023@ift.org.mx'
ORDER BY FechaAsignacion DESC;
```

---

## 🛠️ Mantenimiento

### Agregar un nuevo rol al sistema
```sql
INSERT INTO cat_Roles (RolID, Sistema, DescripcionRol, CreadoPor)
VALUES ('ROL_0022FEDI_NUEVO', '0022FEDI-INT', 'Descripción del nuevo rol', 'admin@ift.org.mx');
```

### Desactivar un rol (soft delete)
```sql
UPDATE cat_Roles
SET Activo = 0,
    FechaModificacion = GETDATE(),
    ModificadoPor = 'admin@ift.org.mx'
WHERE RolID = 'ROL_0022FEDI_OBSOLETO';
```

### Agregar un usuario al sistema
```sql
-- Rol básico (obligatorio)
INSERT INTO tbl_UsuarioRol (UsuarioID, RolID, AsignadoPor, Observaciones)
VALUES ('nuevo.usuario@ift.org.mx', 'ROL_0022FEDI_USER', 'admin@ift.org.mx', 'Usuario nuevo');

-- Rol firmante (opcional)
INSERT INTO tbl_UsuarioRol (UsuarioID, RolID, AsignadoPor, Observaciones)
VALUES ('nuevo.usuario@ift.org.mx', 'ROL_0022FEDI_FIRMANTE', 'admin@ift.org.mx', 'Autorizado para firmar');
```

### Remover un rol de un usuario (soft delete)
```sql
UPDATE tbl_UsuarioRol
SET Activo = 0,
    FechaBaja = GETDATE(),
    BajaPor = 'admin@ift.org.mx',
    Observaciones = 'Rol removido por cambio de puesto'
WHERE UsuarioID = 'usuario@ift.org.mx'
AND RolID = 'ROL_0022FEDI_FIRMANTE'
AND Activo = 1;
```

---

## 📝 Scripts de Validación

### Validar integridad referencial
```sql
-- Verificar que todos los roles en tbl_UsuarioRol existen en cat_Roles
SELECT ur.RolID, COUNT(*) AS Asignaciones
FROM tbl_UsuarioRol ur
LEFT JOIN cat_Roles r ON ur.RolID = r.RolID
WHERE r.RolID IS NULL
GROUP BY ur.RolID;
-- Resultado esperado: 0 filas (todos los roles existen)
```

### Verificar usuarios sin rol básico
```sql
-- Usuarios que tienen roles pero no tienen ROL_0022FEDI_USER
SELECT DISTINCT ur.UsuarioID
FROM tbl_UsuarioRol ur
WHERE ur.Activo = 1
AND NOT EXISTS (
    SELECT 1 FROM tbl_UsuarioRol ur2
    WHERE ur2.UsuarioID = ur.UsuarioID
    AND ur2.RolID = 'ROL_0022FEDI_USER'
    AND ur2.Activo = 1
);
-- Resultado esperado: 0 filas (todos tienen rol básico)
```

### Ver usuarios duplicados (nunca debería haber)
```sql
SELECT UsuarioID, RolID, COUNT(*) AS Duplicados
FROM tbl_UsuarioRol
WHERE Activo = 1
GROUP BY UsuarioID, RolID
HAVING COUNT(*) > 1;
-- Resultado esperado: 0 filas (constraint UQ_UsuarioRol lo previene)
```

---

## 🔄 Migración a PRODUCCIÓN

### Cambio de administrador DEV → PROD

**Script para ejecutar en PRODUCCIÓN**:
```sql
-- PASO 1: Desactivar administrador de DEV
UPDATE tbl_UsuarioRol
SET Activo = 0,
    FechaBaja = GETDATE(),
    BajaPor = 'SYSTEM',
    Observaciones = 'Desactivado por migración a PRODUCCIÓN'
WHERE UsuarioID = 'dgtic.dds.ext023@ift.org.mx'
AND Activo = 1;

-- PASO 2: Crear administrador de PROD
INSERT INTO tbl_UsuarioRol (UsuarioID, RolID, AsignadoPor, Observaciones) VALUES
('deid.ext33@crt.gob.mx', 'ROL_0022FEDI_ADMIN', 'SYSTEM', 'Administrador PROD'),
('deid.ext33@crt.gob.mx', 'ROL_0022FEDI_USER', 'SYSTEM', 'Rol base'),
('deid.ext33@crt.gob.mx', 'ROL_0022FEDI_FIRMANTE', 'SYSTEM', 'Rol firmante');

-- PASO 3: Verificar el cambio
SELECT UsuarioID, STRING_AGG(RolID, ', ') AS Roles
FROM tbl_UsuarioRol
WHERE UsuarioID IN ('dgtic.dds.ext023@ift.org.mx', 'deid.ext33@crt.gob.mx')
GROUP BY UsuarioID;
```

---

## 📦 Respaldo y Recuperación

### Respaldo de tablas
```sql
-- Generar script de respaldo
SELECT * INTO cat_Roles_BACKUP_20260216 FROM cat_Roles;
SELECT * INTO tbl_UsuarioRol_BACKUP_20260216 FROM tbl_UsuarioRol;
```

### Recuperación desde respaldo
```sql
-- Restaurar desde respaldo (si algo sale mal)
DELETE FROM tbl_UsuarioRol;
DELETE FROM cat_Roles;

INSERT INTO cat_Roles SELECT * FROM cat_Roles_BACKUP_20260216;
INSERT INTO tbl_UsuarioRol SELECT * FROM tbl_UsuarioRol_BACKUP_20260216;
```

---

## 📊 Diagrama de Relaciones

```
┌─────────────────────────────────┐
│         cat_Roles               │
├─────────────────────────────────┤
│ PK: RolID (VARCHAR(50))         │
│     Sistema                     │
│     DescripcionRol              │
│     Activo                      │
│     FechaCreacion               │
│     CreadoPor                   │
└─────────────────────────────────┘
                │
                │ 1
                │
                │ N
                ▼
┌─────────────────────────────────┐
│      tbl_UsuarioRol             │
├─────────────────────────────────┤
│ PK: UsuarioRolID (INT IDENTITY) │
│     UsuarioID (VARCHAR(100))    │◄─── Email de LDAP
│ FK: RolID (VARCHAR(50))         │
│     Sistema                     │
│     Activo                      │
│     FechaAsignacion             │
│     AsignadoPor                 │
│     FechaBaja                   │
│     BajaPor                     │
│     Observaciones               │
│                                 │
│ UQ: (UsuarioID, RolID)          │
└─────────────────────────────────┘
```

---

**Última actualización**: 16/Feb/2026
**Versión**: 1.0
**Estado**: Implementado y validado
