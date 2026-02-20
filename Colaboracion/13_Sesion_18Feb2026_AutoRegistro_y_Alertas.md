# Sesión 18-19 Feb 2026: Auto-Registro y Eliminación de Alertas

**Fecha:** 18-19 Febrero 2026
**Contexto:** Continuación de migración FEDI de IFT a CRT
**Objetivo:** Implementar auto-registro de usuarios y eliminar mensaje de alerta molesto

---

## 1. Confirmación: Hardcode Eliminado

**Usuario preguntó:** "¿Entonces ya no será necesario aun harcodear mi cuenta?"

**Respuesta:** ✅ NO, el hardcode ya NO es necesario.

**Cambios previos que lo eliminaron:**
- `AdminRolMB.obtenerDetalleUsuario()` - Busca en memoria en lugar de LDAP
- `AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario()` - Retorna error genérico en lugar de hardcode
- Líneas 322-342 de `AdminUsuariosServiceImpl.java` fueron completamente eliminadas

**WAR generado:** `FEDIPortalWeb-18Feb2026-2122-QA-FINAL-SIN-HARDCODE.war`

---

## 2. Implementación de Auto-Registro

### 2.1 Requerimiento

**Usuario solicitó:**
> "Agregar la función de autoregistro de la cuenta de quien inicia sesión y no está en nuestra tabla 'cat_Usuarios'. De esa manera bastará que un nuevo usuario con cuenta CRT inicie sesión en el FEDI para que ya se incluya en nuestra tabla para futuras consultas."

### 2.2 Primera Implementación

**Archivos modificados:**

1. **LoginMB.java** - Método `autoRegistrarUsuario()` (líneas 337-433)
   - Llamado después de login exitoso (líneas 267-273)
   - Verifica si usuario existe en cat_Usuarios
   - Si NO existe, extrae datos de Spring Security context
   - Inserta automáticamente

2. **FEDIService.java** - Nueva firma de método (línea 24)
   ```java
   void insertarUsuario(CatUsuario usuario) throws Exception;
   ```

3. **FEDIServiceImpl.java** - Implementación `insertarUsuario()` (líneas 169-193)

**Resultado:** Compilación exitosa pero con errores de runtime (NullPointerException)

**WAR generado:** `FEDIPortalWeb-18Feb2026-2131-QA-CON-AUTOREGISTRO.war`

### 2.3 Corrección: Fuente de Datos del Usuario

**Usuario identificó problema crítico:**
> "¿Cómo quedarían los registros? Porque al hacer el inicio de sesión el usuario solo pone su correo sin '@crt.gob.mx' y contraseña, ¿de dónde sacamos su nombre y apellido para registrarlo en nuestra tabla?"

**Análisis:**
- Login API `/autorizacion/login/v3.0/credencial/` retorna objeto `Credencial`
- Contiene `DatosUsuario` con `UsuarioDetalle`
- `UsuarioDetalle` tiene: `nombre`, `apPaterno`, `apMaterno`, `correo`
- Spring Security almacena este objeto `Usuario` en el contexto

**Solución:** Extraer datos de `Usuario.getUsuarioDetalle()` desde el contexto de autenticación

**WAR generado:** `FEDIPortalWeb-18Feb2026-2229-QA-AUTOREGISTRO-CON-NOMBRE-REAL.war`

### 2.4 Homogeneización de Formato

**Usuario solicitó:**
> "Creo que debemos guardar en cat_Usuarios todo en el campo NOMBRE, dejando NULL en los apellidos paterno y materno, ¿qué opinas de cuidar este detalle para que todo quede homogéneo?"

**Análisis de datos existentes** (`cat_Usuarios.txt`):
```
deid.ext33@crt.gob.mx    HECTOR MARTINEZ ESPINOSA    NULL    NULL
david.alvarez@ift.org.mx DAVID LEON ALVAREZ GOMEZ    NULL    NULL
```

**Patrón identificado:** Nombre completo en NOMBRE (UPPERCASE), apellidos NULL

**Cambios implementados:**
- Concatenar: `nombre + " " + apPaterno + " " + apMaterno`
- Convertir a UPPERCASE
- Almacenar en campo NOMBRE
- Apellidos: NULL

**WAR generado:** `FEDIPortalWeb-18Feb2026-2232-QA-FINAL-HOMOGENEO.war` ✅

---

## 3. Corrección de Errores en Auto-Registro

### 3.1 Error 1: NullPointerException

**Usuario reportó:** "Al iniciar sesión me mostró este mensaje de error"

**Logs mostraron:**
```
java.lang.NullPointerException
  at LoginMB.autoRegistrarUsuario(LoginMB.java:443)
```

**Causa:**
```java
// Líneas 443-444 (INCORRECTO)
nuevoUsuario.setApellidoPaterno(apellidoP.isEmpty() ? null : apellidoP);
nuevoUsuario.setApellidoMaterno(apellidoM.isEmpty() ? null : apellidoM);
```
Variables `apellidoP` y `apellidoM` eran `null`, causando `NullPointerException` al llamar `.isEmpty()`

**Fix:**
```java
// CORRECTO
nuevoUsuario.setApellidoPaterno(apellidoP);
nuevoUsuario.setApellidoMaterno(apellidoM);
```

### 3.2 Error 2: Solo se Guardó "HECTOR" sin Apellidos

**Usuario reportó:** "Con esta versión ya no guarda completo el nombre"

**Logs mostraron:**
```
>>> [AUTO-REGISTRO] [DIAG]   - Nombre: [Hector]
>>> [AUTO-REGISTRO] [DIAG]   - ApPaterno: [null]
>>> [AUTO-REGISTRO] [DIAG]   - ApMaterno: [null]
>>> [AUTO-REGISTRO] Nombre completo construido: HECTOR
```

**Análisis:**
- El API de WSO2 NO retorna apellidos en los campos separados
- RedirectMB usa `usuario.getUsuarioDetalle().getRfc()` como nombre (línea 84)
- El campo **RFC** contiene el nombre completo

**Investigación en RedirectMB.java:**
```java
// Línea 84
request.setNombre(usuario.getUsuarioDetalle().getRfc().toUpperCase());
```

**Logs confirmaron:**
```
>>> [AUTO-REGISTRO] [DIAG]   - RFC: [Hector Martinez Espinosa]
```

**Solución:** Usar `getRfc()` como fuente principal del nombre completo

**Código corregido (LoginMB.java líneas 386-389):**
```java
// El nombre completo está en el campo RFC (mismo que usa RedirectMB)
if (detalle.getRfc() != null && !detalle.getRfc().isEmpty()) {
    nombreCompleto = detalle.getRfc().toUpperCase();
    LOGGER.info(">>> [AUTO-REGISTRO] Nombre completo extraído de RFC: {}", nombreCompleto);
}
```

**WAR generado:** `FEDIPortalWeb-19Feb2026-0020-QA-AUTOREGISTRO-RFC-FIX.war` ✅

### 3.3 Error 3: Registro Duplicado en RedirectMB

**Usuario reportó:** "Ya está haciendo correctamente el autoregistro, pero al iniciar sesión se muestra una alerta"

**Logs mostraron:**
```
Línea 153: [ERROR] RedirectMB:88 - Error al registrar usuario: Hector Martinez Espinosa
Línea 187: [ERROR] RedirectMB:88 - Error al registrar usuario: Hector Martinez Espinosa
```

**Causa:** RedirectMB (líneas 71-90) estaba intentando auto-registrar **OTRA VEZ** al usuario que LoginMB ya había registrado

**Flujo incorrecto:**
1. LoginMB registra → ✅ Éxito
2. RedirectMB intenta registrar de nuevo → ❌ Error (violación constraint único)
3. Error se muestra al usuario

**Solución:** Eliminar completamente el código duplicado de auto-registro en RedirectMB

**Código eliminado:**
```java
// ANTES (líneas 71-90): Lógica duplicada eliminada
responseCatUsuarios = fediService.obtenerCatUsuarios();
if (existeBD == false) {
    fediService.registrarUsuario(request); // ← DUPLICADO
}
```

**Código nuevo:**
```java
// AHORA: Solo autenticar y redirigir
Authentication au = SecurityContextHolder.getContext().getAuthentication();
this.usuario = (Usuario) user.getPrincipal();
LOGGER.info(">>> [REDIRECT] Usuario autenticado: {}", usuario.getCorreo());
contextVista.getExternalContext().redirect(url);
```

**WAR generado:** `FEDIPortalWeb-19Feb2026-0028-QA-FINAL-AUTOREGISTRO-CLEAN.war`

---

## 4. Eliminación de Mensaje de Alerta "No se encontró el usuario"

### 4.1 Problema: Doble Redirect

**Usuario reportó:** "Sigue mostrando la misma alerta"

**Logs mostraron:**
```
Línea 122: >>> [REDIRECT] Usuario autenticado: deid.ext33@crt.gob.mx  ✅
Línea 124: >>> [REDIRECT] Usuario autenticado: deid.ext33@crt.gob.mx  ❌
Línea 125: Error en RedirectMB.init(): Cannot call sendRedirect() after the response has been committed
```

**Causa:** RedirectMB se estaba ejecutando **DOS VECES** durante el mismo request

**Solución:** Agregar bandera de control para prevenir doble ejecución

**RedirectMB.java - Cambios:**

1. **Nueva variable de instancia** (línea 41):
   ```java
   private boolean redirectExecuted = false;  // MIGRACIÓN FEDI 2.0: Prevenir doble redirect
   ```

2. **Validación al inicio** (líneas 63-66):
   ```java
   if (redirectExecuted) {
       LOGGER.info(">>> [REDIRECT] Ya ejecutado, saltando...");
       return;
   }
   ```

3. **Marcar como ejecutado** (línea 83):
   ```java
   redirectExecuted = true;
   contextVista.getExternalContext().redirect(url);
   ```

**Logs confirmaron fix:**
```
Línea 108: >>> [REDIRECT] Usuario autenticado: deid.ext33@crt.gob.mx  ✅
Línea 110: >>> [REDIRECT] Ya ejecutado, saltando...  ✅
```

**WAR generado:** `FEDIPortalWeb-19Feb2026-0037-QA-FINAL-NO-DOUBLE-REDIRECT.war`

### 4.2 Problema: Mensajes Antiguos en FacesContext

**Usuario reportó:** "Sigue mostrando la alerta"

**Análisis:** Mensajes de error quedaban almacenados en FacesContext de sesiones previas y se mostraban en `<p:growl>`

**Solución:** Limpiar mensajes antes del redirect

**RedirectMB.java (líneas 83-88):**
```java
// MIGRACIÓN FEDI 2.0 (19/Feb/2026): Limpiar mensajes de error previos antes del redirect
if (contextVista != null) {
    contextVista.getMessageList().clear();
    LOGGER.info(">>> [REDIRECT] Mensajes de FacesContext limpiados");
}
```

**WAR generado:** `FEDIPortalWeb-19Feb2026-0045-QA-FINAL-CLEAN-MESSAGES.war`

### 4.3 Problema: Alerta en Sección "Cargar Documentos y Asignar Firmas"

**Usuario identificó causa raíz:**
> "El mensaje de alerta se muestra cada vez que accedo a la sección 'cargar documentos y asignar firmas', tal vez el análisis de la causa raíz va por analizar lo que sucede al iniciar esta sección."

**¡Cambio de análisis!** El mensaje NO venía del login, sino de AdminRolMB al cargar esa sección específica.

**Logs mostraron:**
```
Línea 29: AdminRolMB:532 - >>> MIGRACIÓN 2.0: Obteniendo detalle de usuario desde lista local (CAT_USUARIOS), NO desde LDAP
```

**Flujo del problema:**
1. Usuario carga página "Cargar documentos y asignar firmas"
2. Componente JSF invoca `AdminRolMB.obtenerDetalleUsuario()`
3. Método busca en `usuariosEncontradosByNombre` (lista vacía hasta que se hace búsqueda explícita)
4. No encuentra nada → Muestra error (líneas 574-575):
   ```java
   mensajeSalida = "No se encontró el usuario seleccionado. Por favor, búsquelo nuevamente.";
   contextVista.addMessage(null, new FacesMessage(FacesMessage.SEVERITY_ERROR, mensajeSalida, "Validación"));
   ```

**Solución:** Retornar silenciosamente cuando la lista está vacía (es situación normal)

**AdminRolMB.java (líneas 534-539):**
```java
// MIGRACIÓN FEDI 2.0 (19/Feb/2026): Si la lista está vacía, no es un error - simplemente no hay búsqueda previa
// NO mostrar mensaje de error, solo retornar silenciosamente
if (this.usuariosEncontradosByNombre == null || this.usuariosEncontradosByNombre.isEmpty()) {
    LOGGER.info(">>> MIGRACIÓN 2.0: Lista de usuarios vacía - requiere búsqueda previa (retorno silencioso)");
    return;
}
```

**WAR FINAL generado:** `FEDIPortalWeb-19Feb2026-0002-QA-FINAL-SIN-ALERTA.war` ✅✅✅

---

## 5. Resumen de Archivos Modificados

### LoginMB.java
**Ruta:** `fedi-web/fedi-web/src/main/java/fedi/ift/org/mx/arq/core/exposition/LoginMB.java`

**Cambios principales:**
1. Nuevo método `autoRegistrarUsuario()` (líneas 337-460)
2. Llamada después de login exitoso (líneas 270-275)
3. Extracción de nombre completo desde `getRfc()` (líneas 386-389)
4. Manejo de duplicados con try-catch (líneas 434-444)

**Imports agregados:**
```java
import fedi.ift.org.mx.arq.core.model.Usuario;
import fedi.ift.org.mx.arq.core.model.UsuarioDetalle;
import fedi.ift.org.mx.service.FEDIService;
import fedi.ift.org.mx.model.CatUsuario;
import fedi.ift.org.mx.model.ResponseCatalogos;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
```

### FEDIService.java
**Ruta:** `fedi-web/fedi-web/src/main/java/fedi/ift/org/mx/service/FEDIService.java`

**Cambios:**
- Nueva firma de método (línea 24):
  ```java
  void insertarUsuario(CatUsuario usuario) throws Exception;
  ```

### FEDIServiceImpl.java
**Ruta:** `fedi-web/fedi-web/src/main/java/fedi/ift/org/mx/service/FEDIServiceImpl.java`

**Cambios:**
- Implementación `insertarUsuario()` (líneas 169-193)
- Llama al backend `/fedi/registrarUsuario`

### RedirectMB.java
**Ruta:** `fedi-web/fedi-web/src/main/java/fedi/ift/org/mx/exposition/RedirectMB.java`

**Cambios principales:**
1. **Eliminada lógica duplicada de auto-registro** (líneas 71-90 eliminadas)
2. **Bandera para prevenir doble redirect** (línea 41):
   ```java
   private boolean redirectExecuted = false;
   ```
3. **Validación de redirect ejecutado** (líneas 63-66)
4. **Limpieza de mensajes de FacesContext** (líneas 83-88)

### AdminRolMB.java
**Ruta:** `fedi-web/fedi-web/src/main/java/fedi/ift/org/mx/exposition/AdminRolMB.java`

**Cambios:**
- **Retorno silencioso cuando lista vacía** (líneas 534-539)
- Previene mensaje de error espurio al cargar página

---

## 6. Flujo Final del Auto-Registro

```
1. Usuario ingresa credenciales en login
   ↓
2. authenticationService.login() → Autentica con WSO2
   ↓
3. Login exitoso → Spring Security guarda Usuario en contexto
   ↓
4. LoginMB.autoRegistrarUsuario(username)
   ├─ Extrae correo de Usuario.getCorreo()
   ├─ Extrae nombre completo de Usuario.getUsuarioDetalle().getRfc()
   ├─ Construye: nombreCompleto.toUpperCase()
   ├─ Prepara: apellidoP = null, apellidoM = null
   └─ try {
       ├─ fediService.insertarUsuario(nuevoUsuario)
       └─ Si error de duplicado → OK (usuario ya existe)
     }
   ↓
5. RedirectMB.redirect()
   ├─ if (redirectExecuted) → return
   ├─ contextVista.getMessageList().clear()
   ├─ redirectExecuted = true
   └─ contextVista.getExternalContext().redirect(url)
   ↓
6. Página "documentos.jsf" se carga limpia (sin alertas)
```

---

## 7. Estructura de Datos en cat_Usuarios

**Tabla:** `cat_Usuarios`

**Campos:**
- `UsuarioID` (PK): Email completo con dominio (ej: `deid.ext33@crt.gob.mx`)
- `Nombre`: Nombre completo en UPPERCASE (ej: `HECTOR MARTINEZ ESPINOSA`)
- `ApellidoPaterno`: NULL (para homogeneidad)
- `ApellidoMaterno`: NULL (para homogeneidad)

**Ejemplo de registro auto-insertado:**
```sql
INSERT INTO cat_Usuarios (UsuarioID, Nombre, ApellidoPaterno, ApellidoMaterno)
VALUES ('deid.ext33@crt.gob.mx', 'HECTOR MARTINEZ ESPINOSA', NULL, NULL);
```

---

## 8. Modelo de Datos del Login API

**API:** `/autorizacion/login/v3.0/credencial/{sistema}/{usuario}/{password_encoded}`

**Estructura de respuesta:**
```java
Credencial {
    String error;
    Integer code;
    String usuario;
    Usuario datosUsuario {
        String correo;              // "deid.ext33@crt.gob.mx"
        UsuarioDetalle usuarioDetalle {
            String nombre;          // "Hector"
            String apPaterno;       // null (no viene del API)
            String apMaterno;       // null (no viene del API)
            String rfc;            // "Hector Martinez Espinosa" ← FUENTE DEL NOMBRE COMPLETO
            String correo;         // "deid.ext33@crt.gob.mx"
        }
    }
}
```

**Nota importante:** El nombre completo NO viene en campos separados, sino en el campo **`rfc`**

---

## 9. Problemas Resueltos

| # | Problema | Solución | WAR |
|---|----------|----------|-----|
| 1 | NullPointerException en línea 443 | Eliminar validación `.isEmpty()` en variables null | 0020 |
| 2 | Solo guarda "HECTOR" sin apellidos | Usar `getRfc()` como fuente del nombre completo | 0020 |
| 3 | Auto-registro duplicado en RedirectMB | Eliminar lógica duplicada de RedirectMB | 0028 |
| 4 | Doble redirect en RedirectMB | Agregar bandera `redirectExecuted` | 0037 |
| 5 | Mensajes antiguos en FacesContext | Limpiar mensajes antes del redirect | 0045 |
| 6 | Alerta al cargar "Asignar firmas" | Retorno silencioso cuando lista vacía | **0002** ✅ |

---

## 10. WAR Final

**Archivo:** `FEDIPortalWeb-19Feb2026-0002-QA-FINAL-SIN-ALERTA.war`

**Tamaño:** 95 MB

**Funcionalidades incluidas:**
- ✅ Auto-registro de usuarios en primer login
- ✅ Nombre completo extraído de campo RFC
- ✅ Formato homogéneo: NOMBRE completo en UPPERCASE, apellidos NULL
- ✅ Prevención de doble redirect
- ✅ Limpieza de mensajes de FacesContext
- ✅ Sin alertas espurias al cargar secciones
- ✅ Manejo de duplicados: inserta solo si no existe
- ✅ Login no bloqueante: continúa aunque falle auto-registro

---

## 11. Testing Recomendado

### Test 1: Primer Login de Usuario Nuevo
1. Usuario nuevo con cuenta CRT inicia sesión
2. ✅ Login exitoso
3. ✅ Usuario auto-registrado en cat_Usuarios
4. ✅ Formato: "NOMBRE APELLIDO1 APELLIDO2" en mayúsculas
5. ✅ Sin mensajes de error

### Test 2: Login de Usuario Existente
1. Usuario existente inicia sesión
2. ✅ Login exitoso
3. ✅ Auto-registro detecta duplicado (constraint violation)
4. ✅ Login continúa sin interrupciones

### Test 3: Navegación a "Cargar Documentos"
1. Acceder a sección "Cargar documentos y asignar firmas"
2. ✅ Página carga sin alertas
3. ✅ Componente de búsqueda de usuarios disponible
4. ✅ Botón "Agregar firmante" disponible

### Test 4: Asignación de Firmantes
1. Buscar usuario en campo de búsqueda
2. ✅ Lista de usuarios se llena
3. Agregar usuario como firmante
4. ✅ Usuario agregado correctamente
5. ✅ Sin mensajes de error

---

## 12. Notas de Migración

### Dependencias Eliminadas
- ✅ Hardcode de cuenta específica
- ✅ Dependencia de LDAP para búsqueda de usuarios
- ✅ Validación de campo "activo" de LDAP
- ✅ Registro manual de usuarios por DBA

### Comportamientos Nuevos
- ✅ Auto-registro automático en primer login
- ✅ Búsqueda de usuarios en cat_Usuarios (no LDAP)
- ✅ Todos los usuarios en cat_Usuarios son válidos (no validar estatus)

### Consideraciones Futuras
- Si se necesita control de usuarios activos/inactivos, agregar campo `Estatus` a `cat_Usuarios`
- El auto-registro es **no bloqueante**: si falla, el login continúa
- La lista `usuariosEncontradosByNombre` requiere búsqueda explícita antes de agregar firmantes

---

## 13. Comandos de Compilación

```bash
# Compilar para QA
cd D:\GIT\GITHUB\CRT2\FEDI2026\fedi-web\fedi-web
mvn clean package -Pqa-oracle1 -DskipTests

# Copiar WAR
cd target
cp FEDIPortalWeb-1.0.war D:\GIT\GITHUB\CRT2\FEDI2026\FEDIPortalWeb-19Feb2026-0002-QA-FINAL-SIN-ALERTA.war
```

---

## 14. Próximos Pasos

### Pendientes para Producción
1. ✅ Testing en QA con usuarios reales
2. ⏳ Validar que nombres completos se extraen correctamente del API WSO2
3. ⏳ Probar flujo completo: Login → Auto-registro → Buscar usuarios → Asignar firmantes
4. ⏳ Validar que NO aparecen alertas en ninguna sección
5. ⏳ Deployment en PROD

### Mejoras Futuras (Opcional)
- Agregar campo `FechaRegistro` a cat_Usuarios
- Agregar campo `Estatus` (Activo/Inactivo) si se requiere control
- Log de auditoría de auto-registros
- Dashboard con estadísticas de usuarios registrados

---

**Fin de sesión 18-19 Feb 2026**
