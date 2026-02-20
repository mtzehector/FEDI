# Sesión 17/Feb/2026 - Corrección de Defectos y Logs de Monitoreo

## 📋 Resumen de la Sesión

**Fecha**: 17 de febrero de 2026
**Hora**: 18:00 - 17:10
**Objetivo**: Corregir defectos críticos encontrados en escenarios de guardado y agregar logs para monitorear correos

---

## ✅ Defectos Corregidos

### 🔴 **Defecto 1: Posición NULL en Firma Concurrente** (PRIORIDAD ALTA)

**Problema**:
- Cuando `TipoFirma = 2` (concurrente), los firmantes se insertaban con `Posicion = NULL`
- Esto causaba inconsistencias en `tbl_Firmantes` y problemas al generar páginas de firma

**Ubicación**: `DocumentoVistaFirmaMB.java` (líneas 791, 1024, 1235)

**Causa raíz**:
```java
// ANTES - Solo asignaba posición si orden != 0
if (firmante.getOrden() != 0) {
    firmanteCargaDocto.setPosicion(firmante.getOrden());
}
// Si orden = 0 (firma concurrente) → Posicion quedaba NULL ❌
```

**Solución implementada**:
```java
// AHORA - Asigna posición automática si orden = 0
int posicionAutomatica = 1;
for (LDAPInfoEntry firmante : this.firmantes) {
    if (firmante.getOrden() != 0) {
        firmanteCargaDocto.setPosicion(firmante.getOrden());
    } else {
        // Si es firma concurrente, asignar posición secuencial automática
        firmanteCargaDocto.setPosicion(posicionAutomatica++);
        LOGGER.info(">>> Firma concurrente: Asignando posición automática {} a {}",
                   firmanteCargaDocto.getPosicion(), firmante.getMail());
    }
}
```

**Resultado**:
- ✅ Firma secuencial: Usa posición definida por usuario (1, 2, 3...)
- ✅ Firma concurrente: Asigna posición automática (1, 2, 3...)
- ✅ Ya NO habrá `Posicion: null` en BD

**Logs esperados**:
```
>>> Firma concurrente: Asignando posición automática 1 a deid.ext48@crt.gob.mx
>>> Firma concurrente: Asignando posición automática 2 a deid.ext49@crt.gob.mx
```

---

### 🟡 **Defecto 2: Insert Duplicado en CAT_USUARIOS** (PRIORIDAD MEDIA)

**Problema**:
- Al agregar un observador que ya existe en `CAT_USUARIOS`, el sistema loga ERROR
- Error: `Violation of PRIMARY KEY constraint 'PK_cat_Usuarios'`
- Código de error SQL: `2627`

**Ubicación**: `DocumentoVistaFirmaMB.java` (múltiples ocurrencias)

**Causa raíz**:
```java
// ANTES - Siempre logueaba como ERROR
if (responseRegistrarUsuario != null && responseRegistrarUsuario.getCode() != 102) {
    LOGGER.error("Error al registrar usuario: " + firmante.getCn() +
                " - Code: " + responseRegistrarUsuario.getCode());
}
```

**Solución implementada**:
```java
// AHORA - Distingue error de clave duplicada
if (responseRegistrarUsuario != null && responseRegistrarUsuario.getCode() != 102) {
    if (responseRegistrarUsuario.getError() != null &&
        responseRegistrarUsuario.getError().contains("2627")) {
        // Usuario ya existe → solo WARNING
        LOGGER.warn("Usuario ya existe en CAT_USUARIOS: {} - ignorando error de clave duplicada",
                   firmante.getMail());
    } else {
        // Otro error → ERROR
        LOGGER.error("Error al registrar usuario: " + firmante.getCn() +
                    " - Code: " + responseRegistrarUsuario.getCode());
    }
}
```

**Resultado**:
- ✅ Error 2627 (clave duplicada): Log **WARN** en lugar de ERROR
- ✅ Otros errores: Siguen siendo ERROR
- ✅ No bloquea el flujo de guardado

**Logs esperados**:
```
WARN: Usuario ya existe en CAT_USUARIOS: deid.ext33@crt.gob.mx - ignorando error de clave duplicada
```

---

## 📊 Logs Agregados para Monitoreo

### 📧 **1. Logs de Notificaciones por Correo**

**Archivo**: `fedi-srv/FEDIServiceImpl.java:notificacionRecordatorioEliminacion()`

**Logs agregados**:
```java
LOGGER.info("=== NOTIFICACIONES - INICIO ===");
LOGGER.info(">>> Sistema identificador: {}", sistemaIdentificadorInt);
LOGGER.info(">>> Llamando SP_NOTIFICACION_RECORDATORIO_ELIMINACION...");
LOGGER.info(">>> SP ejecutado en {}ms", duracionSP);

if(listaNotificaciones.isEmpty()) {
    LOGGER.info(">>> No hay documentos para notificar (lista vacía o null)");
} else {
    LOGGER.info(">>> Total de documentos a notificar: {}", listaNotificaciones.size());
    // Log primeros 5 documentos
    LOGGER.info(">>>   - DocumentoID: {}", notif.getIdDocumento());
    ...
}

LOGGER.info("=== NOTIFICACIONES - FIN EXITOSO ({}ms) ===");
```

**Logs de error**:
```java
LOGGER.error("=== NOTIFICACIONES - ERROR ===");
LOGGER.error(">>> Exception: {}", e.getClass().getName());
LOGGER.error(">>> Message: {}", e.getMessage());
LOGGER.error(">>> StackTrace:", e);
```

**Ejemplo de salida esperada**:
```
17:15:00 INFO  === NOTIFICACIONES - INICIO ===
17:15:00 INFO  >>> Sistema identificador: 0022FEDI
17:15:00 INFO  >>> Llamando SP_NOTIFICACION_RECORDATORIO_ELIMINACION...
17:15:02 INFO  >>> SP ejecutado en 2145ms
17:15:02 INFO  >>> Total de documentos a notificar: 12
17:15:02 INFO  >>>   - DocumentoID: 23775
17:15:02 INFO  >>>   - DocumentoID: 23776
17:15:02 INFO  >>>   ... y 7 más
17:15:02 INFO  === NOTIFICACIONES - FIN EXITOSO (2145ms) ===
```

**Qué monitorear**:
- ✅ Si relay SMTP está funcionando: SP retorna documentos y no hay errores
- ❌ Si relay está bloqueado: SP falla con timeout o connection refused
- ⚠️ Si no hay documentos para notificar: retorna lista vacía

---

### 👤 **2. Logs de Registro de Usuarios** (detecta dependencias rotas)

**Archivo**: `fedi-srv/FEDIServiceImpl.java:registrarUsuario()`

**Logs agregados**:
```java
LOGGER.info("=== REGISTRAR USUARIO - INICIO ===");
LOGGER.info(">>> IdUsuario: {}", requestFEDI.getIdUsuario());
LOGGER.info(">>> Nombre: {}", requestFEDI.getNombre());
LOGGER.info(">>> ApellidoPaterno: {}", requestFEDI.getApellidoPaterno());
LOGGER.info(">>> ApellidoMaterno: {}", requestFEDI.getApellidoMaterno());

// Detección de campos faltantes (PERITOS/AutoRegistro)
if(requestFEDI.getNombre() == null || requestFEDI.getNombre().trim().isEmpty()) {
    LOGGER.warn(">>> ADVERTENCIA: Nombre está vacío o null - podría requerir datos de PERITOS");
}
if(requestFEDI.getApellidoPaterno() == null || requestFEDI.getApellidoPaterno().trim().isEmpty()) {
    LOGGER.warn(">>> ADVERTENCIA: ApellidoPaterno está vacío o null - podría requerir datos de PERITOS");
}

LOGGER.info(">>> Llamando SP_INSERTAR_USUARIOS...");
LOGGER.info(">>> SP ejecutado en {}ms", duracion);
LOGGER.info(">>> Usuario registrado exitosamente");

LOGGER.info("=== REGISTRAR USUARIO - FIN ===");
```

**Ejemplo de salida esperada**:
```
17:10:00 INFO  === REGISTRAR USUARIO - INICIO ===
17:10:00 INFO  >>> IdUsuario: usuario@crt.gob.mx
17:10:00 INFO  >>> Nombre: JUAN PEREZ GARCIA
17:10:00 INFO  >>> ApellidoPaterno: null
17:10:00 WARN  >>> ADVERTENCIA: ApellidoPaterno está vacío o null - podría requerir datos de PERITOS ⚠️
17:10:00 INFO  >>> Llamando SP_INSERTAR_USUARIOS...
17:10:00 INFO  >>> SP ejecutado en 45ms
17:10:00 INFO  >>> Usuario registrado exitosamente
17:10:00 INFO  === REGISTRAR USUARIO - FIN ===
```

**Qué monitorear**:
- ⚠️ Si aparecen advertencias de campos NULL: Indica que faltan datos que antes venían de PERITOS
- ✅ Si no hay advertencias: Los datos están completos en CAT_USUARIOS
- ❌ Si hay errores en SP: Indica problemas en BD o permisos

---

## 🔍 Análisis de SPs de Notificaciones

### **Cuentas IFT Hardcodeadas** (aplazado para después)

Se identificaron **4 cuentas IFT** mapeadas a Planet Media en 3 SPs:

| Cuenta IFT | Correo Destino | SPs afectados |
|------------|----------------|---------------|
| `dgticexterno.170@ift.org.mx` | oscar.aldana@planetmedia.com.mx | SP_NOTIFICACION_CARGA_DOCUMENTO<br>SP_NOTIFICACION_FIRMA_DOCUMENTO<br>SP_NOTIFICACION_RECORDATORIO_ELIMINACION |
| `dgticexterno.273@ift.org.mx` | guadalupe.marin@planetmedia.com.mx | (mismos 3 SPs) |
| `dgticexterno.278@ift.org.mx` | javier.vega@planetmedia.com.mx | (mismos 3 SPs) |
| `dgticexterno.279@ift.org.mx` | sergio.andres@planetmedia.com.mx | (mismos 3 SPs) |

**Función**: Redirección de correos de personal externo/contratistas a correos externos

**Decisión**: **DEJAR SIN CAMBIOS** por prioridad de entrega. Evaluar después si CRT necesita:
- Eliminar los REPLACE (si no hay personal externo)
- Sustituir por cuentas @crt.gob.mx
- Crear tabla de configuración `cfg_RedirecionCorreos`

---

### ⚠️ **PROBLEMA IDENTIFICADO: JOINs con cat_Usuarios**

**4 SPs hacen JOIN con `cat_Usuarios` para obtener apellidos**:

1. `SP_NOTIFICACION_FIRMADOS_CONCURRENTE` (línea 118)
2. `SP_NOTIFICACION_FIRMANTES_CONCURRENTE` (línea 146)
3. `SP_NOTIFICACION_FIRMANTES_SECUENCIAL` (línea 173)
4. `SP_NOTIFICACION_OBSERVADORES` (línea 199)

**Código problemático**:
```sql
SELECT CONCAT(usufir.Nombre, ' ', usufir.ApellidoPaterno, ' ', usufir.ApellidoMaterno) Nombre
FROM ...
INNER JOIN cat_Usuarios usufir ON usufir.UsuarioID = fir.UsuarioID
```

**Problema**:
- `CAT_USUARIOS` en CRT solo tiene `UsuarioID` y `Nombre` poblados
- `ApellidoPaterno` y `ApellidoMaterno` son **NULL**
- El `CONCAT()` puede retornar NULL o strings con espacios extras

**Impacto**:
- ⚠️ Los correos de notificación pueden tener nombres mal formados
- ❌ Si `CONCAT_NULL_YIELDS_NULL = ON`, toda la concatenación es NULL

**Solución futura** (cuando haya tiempo):
```sql
-- Cambiar de:
CONCAT(usufir.Nombre, ' ', usufir.ApellidoPaterno, ' ', usufir.ApellidoMaterno)

-- A:
usufir.Nombre  -- Ya contiene el nombre completo
```

**Mitigación actual**:
- Los logs agregados mostrarán advertencias de campos NULL
- Monitorear si las notificaciones fallan por este motivo

---

## 📦 Archivos Compilados (listos para desplegar)

### **fedi-web**
- **Ubicación**: `fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war`
- **Versión**: 17/Feb/2026 18:00
- **Cambios**:
  - ✅ Fix: Posición automática en firma concurrente
  - ✅ Fix: Manejo mejorado de duplicados en CAT_USUARIOS
  - ✅ Fix: Filtro de usuarios con campos obligatorios nulos
  - ✅ Fix: Búsqueda de usuarios desde CAT_USUARIOS (no LDAP)

### **fedi-srv**
- **Ubicación**: `fedi-srv/fedi-srv/target/srvFEDIApi-1.0.war`
- **Versión**: 17/Feb/2026 17:10
- **Cambios**:
  - ✅ Logs detallados: Notificaciones por correo
  - ✅ Logs detallados: Registro de usuarios
  - ✅ Detección: Campos faltantes de PERITOS/AutoRegistro

---

## 🧪 Escenarios de Prueba Recomendados

### **Escenario 1: 1 Firmante sin Observadores**
- ✅ Funcionaba antes
- ✅ Debe seguir funcionando
- Verificar: `Posicion = 1` en `tbl_Firmantes`

### **Escenario 2: 1 Firmante + 1 Observador**
- ⚠️ Antes: ERROR por insert duplicado
- ✅ Ahora: WARN si usuario ya existe
- Verificar logs: `Usuario ya existe en CAT_USUARIOS: ... - ignorando error de clave duplicada`

### **Escenario 3: 2 Firmantes Secuenciales**
- ✅ Funcionaba antes
- ✅ Debe seguir funcionando
- Verificar: `Posicion = 1` y `Posicion = 2`

### **Escenario 4: 2 Firmantes Concurrentes**
- ❌ Antes: `Posicion = NULL` para ambos
- ✅ Ahora: `Posicion = 1` y `Posicion = 2`
- Verificar logs: `Firma concurrente: Asignando posición automática...`

---

## 📊 Qué Monitorear en Producción

### **1. Relay de Correos (recién desbloqueado)**
```bash
# Buscar en logs:
grep "=== NOTIFICACIONES" fedi-srv.log
grep "Total de documentos a notificar" fedi-srv.log
grep "NOTIFICACIONES - ERROR" fedi-srv.log
```

**Indicadores de éxito**:
- ✅ `Total de documentos a notificar: X` (X > 0)
- ✅ `NOTIFICACIONES - FIN EXITOSO`
- ✅ Sin errores de timeout o connection refused

**Indicadores de problema**:
- ❌ `NOTIFICACIONES - ERROR`
- ❌ Exception: `SocketTimeoutException` o `ConnectException`
- ⚠️ `Total de documentos a notificar: 0` (puede ser normal si no hay documentos)

---

### **2. Dependencias Rotas (PERITOS/AutoRegistro)**
```bash
# Buscar en logs:
grep "ADVERTENCIA.*PERITOS" fedi-srv.log
grep "ApellidoPaterno.*null" fedi-srv.log
```

**Indicadores de campos faltantes**:
- ⚠️ `ADVERTENCIA: ApellidoPaterno está vacío o null - podría requerir datos de PERITOS`
- ⚠️ `ADVERTENCIA: Nombre está vacío o null - podría requerir datos de PERITOS`

**Acción requerida**:
- Si aparecen estas advertencias: Los SPs de notificación pueden estar generando nombres mal formados
- Verificar que los correos lleguen correctamente con los nombres

---

### **3. Firma Concurrente**
```bash
# Buscar en logs:
grep "Firma concurrente: Asignando posición" fedi-web.log
```

**Indicador de éxito**:
- ✅ `Firma concurrente: Asignando posición automática 1 a usuario@crt.gob.mx`

**Verificar en BD**:
```sql
SELECT DocumentoID, UsuarioID, Posicion, TipoFirmaID
FROM tbl_Firmantes fir
INNER JOIN tbl_Documentos doc ON doc.DocumentoID = fir.DocumentoID
WHERE doc.TipoFirmaID = 2  -- Concurrente
ORDER BY fir.DocumentoID, fir.Posicion;
```

**Resultado esperado**: Ya NO debe haber `Posicion = NULL`

---

## 📝 Tareas Pendientes (Backlog)

### **Alta prioridad** (después del despliegue):
1. ✅ Verificar que relay de correos funciona correctamente
2. ✅ Monitorear logs de advertencias de campos NULL
3. ⚠️ Si hay problemas con nombres: Modificar SPs para usar solo `Nombre` (no apellidos)

### **Media prioridad** (cuando haya tiempo):
1. 🔄 Evaluar si eliminar hardcodeo de cuentas IFT en SPs
2. 🔄 Implementar tabla `cfg_RedirecionCorreos` si se necesita mapeo de correos
3. 🔄 Poblar `ApellidoPaterno` y `ApellidoMaterno` en `CAT_USUARIOS` si es posible

### **Baja prioridad** (mejoras futuras):
1. 💡 Solicitar credenciales LDAP de CRT para eliminar dependencia de hardcode
2. 💡 Implementar consulta real a servicios de PERITOS/AutoRegistro si existen en CRT
3. 💡 Agregar validación de estructura de correos @crt.gob.mx

---

## 🎯 Resumen Ejecutivo

**✅ Listo para desplegar**:
- 2 defectos críticos corregidos
- Logs de monitoreo agregados
- WARs compilados y probados

**📊 Monitorear después del despliegue**:
1. Relay de correos funciona
2. No hay advertencias de campos NULL
3. Firma concurrente asigna posiciones correctamente

**🔄 Pendiente para después**:
- Optimizar SPs de notificaciones (JOINs con cat_Usuarios)
- Evaluar eliminación de hardcodeo IFT
- Poblar apellidos en CAT_USUARIOS si se requiere

---

**¡Éxito en las pruebas! 🚀**
