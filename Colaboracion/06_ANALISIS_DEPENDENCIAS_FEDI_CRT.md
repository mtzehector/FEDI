# Análisis Completo de Dependencias FEDI para Migración CRT

**Fecha:** 2026-01-30
**Objetivo:** Identificar todas las dependencias externas de FEDI para validación con soporte de sistemas
**Estado Actual:** Login CRT ✅ | Firmantes PERITOS ❌

---

## Resumen Ejecutivo

FEDI tiene **5 tipos de dependencias críticas** que deben estar operativas en el entorno CRT:

1. **API Manager CRT** - Autenticación y APIs de negocio ✅ FUNCIONAL
2. **Sistema PERITOS** - Catálogo de firmantes ❌ NO DISPONIBLE
3. **Servicio LDAP** - Información de usuarios ⚠️ POR CONFIRMAR
4. **Base de Datos Oracle** - Almacenamiento de documentos ⚠️ POR CONFIRMAR
5. **Servidor SMTP** - Notificaciones por correo ⚠️ POR CONFIRMAR

---

## 1. API Manager CRT (WSO2)

### Estado: ✅ FUNCIONAL

### Endpoints Configurados (Profile QA):

#### 1.1 Token de Acceso OAuth2
```
URL: http://apimanager-qa.crt.gob.mx:8280/token
Método: POST
Autenticación: Basic V3FsMVBMdmpvZTh6U0RfNHFTRWIyNEhTOWZBYTpFeExrVEFsOEY0eEkxZ1BjaHh5Rk5TblFYQlFh
Estado: ✅ FUNCIONAL
```

#### 1.2 Login/Autenticación
```
URL: https://apimanager-qa.crt.gob.mx/autorizacion/login/v3.0/credencial/{sistema}/{usuario}/{password}
Sistema: 0022FEDI
Estado: ✅ FUNCIONAL (confirmado con pruebas)
```

#### 1.3 API FEDI (Negocio)
```
URL Base: https://apimanager-qa.crt.gob.mx/FEDI/v3.0/
Endpoints:
  - catalogos/consultarTipoFirma
  - operaciones/cargarDocumento
  - operaciones/solicitarFirma
  - operaciones/eliminarDocumento
  - consultas/obtenerDocumentosSinFirma
  - consultas/obtenerDocumentosFirmados
  - notificacion/recordatorioEliminacion
Estado: ⚠️ POR CONFIRMAR (depende de backend FEDI)
```

#### 1.4 Servicio de Bitácora
```
URL: https://apimanager-qa.crt.gob.mx/bit.reg.crt.gob.mx/registroBitacora/
Propósito: Registro de auditoría de operaciones
Estado: ⚠️ POR CONFIRMAR
```

#### 1.5 Servicio de Notificaciones
```
URL: https://apimanager-qa.crt.gob.mx/REGISTRO/CORREOS/FEDI/v3.0/t/fedi.ift.org.mx/firmaUsuarios/
Propósito: Envío de notificaciones por email
Estado: ⚠️ POR CONFIRMAR
Nota: URL contiene "fedi.ift.org.mx" - validar si debe ser "fedi.crt.gob.mx"
```

### Archivo de Configuración:
- `pom.xml` líneas 799-810 (profile qa-oracle1)
- `src/main/resources/application.properties` líneas 77-95

---

## 2. Sistema PERITOS (0015MSPERITOSDES-INT)

### Estado: ❌ NO DISPONIBLE EN CRT

### Descripción:
FEDI depende del sistema PERITOS para obtener el catálogo de usuarios que pueden ser asignados como firmantes de documentos.

### Endpoints Requeridos:

#### 2.1 Consulta de Roles de PERITOS
```
URL: https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT
Método: GET
Propósito: Obtener lista de roles del sistema PERITOS
Usado en: AdminUsuariosServiceImpl.obtenerUsuarios() línea 112
Estado: ❌ HTTP 401 (sistema no registrado en API Manager CRT)
```

#### 2.2 Consulta de Usuarios por Rol
```
URL: https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/4/{sistema}--{rol}/0022FEDI
Método: GET
Propósito: Obtener usuarios que tienen un rol específico
Usado en: AdminUsuariosServiceImpl.obtenerUsuarios() línea 144
Estado: ❌ Depende de 2.1
```

#### 2.3 Consulta de Usuario Interno
```
URL: https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/1/{usuario}/0015MSPERITOSDES-INT
Método: GET
Propósito: Buscar un usuario específico en PERITOS
Usado en: AdminUsuariosServiceImpl.obtenerUsuarioInterno() línea 239
Estado: ❌ Depende de 2.1
```

### Código Afectado:
- `src/main/java/fedi/ift/org/mx/arq/core/service/security/AdminUsuariosServiceImpl.java`
  - Línea 112: Consulta roles PERITOS
  - Línea 138: Valida exclusión de rol interno
  - Línea 239: Busca usuario en PERITOS

### Funcionalidad Bloqueada:
- ❌ Cargar documento y asignar firma
- ❌ Gestión de firmantes en documentos
- ❌ Asignación de roles de firma

### Acción Requerida:
**URGENTE:** Registrar sistema PERITOS (0015MSPERITOSDES-INT) en API Manager CRT y configurar permisos para que FEDI pueda consultarlo.

---

## 3. Servicio LDAP (Directorio de Usuarios)

### Estado: ⚠️ POR CONFIRMAR

### Configuración:
```
URL: https://apimanager-qa.crt.gob.mx/ldp.inf.crt.gob.mx/v3.0/
Endpoint: OBTENER_INFO
Método: POST
Propósito: Consultar información detallada de usuarios (nombre, email, status)
```

### Endpoints:

#### 3.1 Obtener Información de Usuario
```
URL: https://apimanager-qa.crt.gob.mx/ldp.inf.crt.gob.mx/v3.0/OBTENER_INFO
Método: POST
Payload: {"user": "usuario"}
Propósito: Obtener datos del usuario desde Active Directory
Usado en: AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario() línea 320
```

#### 3.2 Búsqueda de Usuarios por Nombre
```
URL: https://apimanager-qa.crt.gob.mx/ldp.inf.crt.gob.mx/v3.0/Obtener_Por_Nombre_usuarioID/{texto}
Método: GET
Propósito: Buscar usuarios por nombre o ID
Usado en: AdminUsuariosServiceImpl.obtenerListaBusqueda() línea 345
```

### Nota Importante:
- URL migrada de `ldp.inf.ift.org.mx` a `ldp.inf.crt.gob.mx`
- Validar que el servicio LDAP esté publicado en API Manager CRT
- Verificar conectividad con Active Directory CRT

### Código Afectado:
- `src/main/java/fedi/ift/org/mx/arq/core/service/security/AdminUsuariosServiceImpl.java`
  - Línea 314-322: Obtener info LDAP de usuario

---

## 4. Base de Datos Oracle

### Estado: ⚠️ POR CONFIRMAR

### Configuración (Profile QA):
```
Driver: oracle.jdbc.OracleDriver
JNDI: jdbc/fedi
Conexión: Configurada en servidor de aplicaciones (Tomcat/WebLogic)
```

### Propósito:
- Almacenamiento de documentos y metadata
- Registro de firmas electrónicas
- Historial de operaciones
- Configuración del sistema
- Gestión de usuarios y permisos

### Tablas Críticas (Estimadas):
- Documentos
- Firmas
- Usuarios
- Configuración
- Bitácora de operaciones

### Validación Requerida:
1. **Conectividad:** ¿El servidor de aplicaciones puede conectar a la BD Oracle CRT?
2. **Credenciales:** ¿Las credenciales configuradas tienen permisos correctos?
3. **JNDI:** ¿El datasource `jdbc/fedi` está configurado en el servidor?
4. **Esquema:** ¿Las tablas existen y están migradas desde IFT?
5. **Permisos:** ¿El usuario tiene permisos SELECT, INSERT, UPDATE, DELETE?

### Configuración:
- `pom.xml` líneas 775-779 (profile qa-oracle1)
- `src/main/resources/application.properties` líneas 1-8
- Servidor: Configuración JNDI en Tomcat/WebLogic

### Nota:
Las credenciales están encriptadas con JASYPT. El valor real está en:
```
pom.xml:
  <profile.jdbc.url>CADENA</profile.jdbc.url>
  <profile.jdbc.username>CADENA</profile.jdbc.username>
  <profile.jdbc.password>AAAAAAAAAAAAAAAAAAAA</profile.jdbc.password>
```

---

## 5. Servidor SMTP (Relay de Correo)

### Estado: ⚠️ POR CONFIRMAR

### Configuración Actual (application.properties):
```properties
mail.active=false  # ⚠️ DESACTIVADO
mail.host=smtp.gmail.com
mail.port=465
mail.protocol=smtps
mail.starttls.enable=true
mail.smtp.auth=true
mail.from=test@metasoft.com.mx
mail.username=test@metasoft.com.mx
mail.password=ENC(0Iu7iZ+juxRrIKcl2Q4XA5FMrTobqqwM)
```

### Propósito:
- Notificaciones de firma de documentos
- Recordatorios de documentos pendientes
- Alertas de vencimiento
- Confirmaciones de operaciones

### Validación Requerida:
1. **¿CRT tiene servidor SMTP interno?**
   - Si SÍ: Actualizar configuración con host/puerto CRT
   - Si NO: Mantener Gmail o usar servicio externo

2. **Activación del Servicio:**
   - Cambiar `mail.active=true` cuando esté listo
   - Validar credenciales de SMTP

3. **Configuración CRT:**
   ```properties
   mail.host=smtp.crt.gob.mx (?)
   mail.port=587 o 465 (?)
   mail.from=noreply@crt.gob.mx (?)
   mail.username=usuario_smtp_crt
   mail.password=ENC(password_encriptado)
   ```

### Código Afectado:
- `src/main/java/fedi/ift/org/mx/arq/core/service/mail/NotificationServiceImpl.java`
- `src/main/resources/spring/applicationContext-mail.xml`

---

## Checklist de Validación para Soporte de Sistemas

### 1. API Manager CRT ✅
- [x] Token de acceso OAuth2 funcional
- [x] Endpoint de login/autenticación operativo
- [ ] API FEDI de negocio publicada
- [ ] Servicio de bitácora configurado
- [ ] Servicio de notificaciones configurado
- [ ] URL de notificaciones corregida (ift → crt)

### 2. Sistema PERITOS ❌
- [ ] Sistema PERITOS registrado en API Manager CRT
- [ ] Identificador: 0015MSPERITOSDES-INT
- [ ] Permisos configurados para consulta desde FEDI (0022FEDI)
- [ ] Endpoint `/registro/consultas/roles/` operativo
- [ ] Usuarios/roles de PERITOS migrados a CRT

### 3. Servicio LDAP ⚠️
- [ ] Servicio LDAP publicado en API Manager CRT
- [ ] URL `ldp.inf.crt.gob.mx` operativa
- [ ] Endpoint OBTENER_INFO funcional
- [ ] Conectividad con Active Directory CRT
- [ ] Permisos de lectura de AD configurados

### 4. Base de Datos Oracle ⚠️
- [ ] Servidor BD Oracle CRT disponible
- [ ] Datasource JNDI `jdbc/fedi` configurado en servidor aplicaciones
- [ ] Credenciales de BD actualizadas en pom.xml
- [ ] Conectividad desde servidor de aplicaciones a BD
- [ ] Esquema de BD migrado desde IFT
- [ ] Permisos de usuario BD configurados (SELECT, INSERT, UPDATE, DELETE)
- [ ] Prueba de conexión exitosa

### 5. Servidor SMTP ⚠️
- [ ] Determinar si CRT tiene servidor SMTP interno
- [ ] Actualizar configuración SMTP en application.properties
- [ ] Configurar credenciales de cuenta de correo
- [ ] Activar servicio: `mail.active=true`
- [ ] Prueba de envío de correo exitosa

---

## Prioridad de Implementación

### CRÍTICO - Bloqueante (Resolver Inmediatamente):
1. **Sistema PERITOS** ❌
   - Sin esto, no se pueden asignar firmantes a documentos
   - Bloquea funcionalidad principal de FEDI

### ALTA - Necesario para Operación:
2. **Base de Datos Oracle** ⚠️
   - Sin BD no se pueden guardar documentos
   - Funcionalidad completamente bloqueada

3. **Servicio LDAP** ⚠️
   - Necesario para validar usuarios firmantes
   - Bloquea validación de existencia de usuarios

### MEDIA - Importante pero no Bloqueante:
4. **API FEDI de Negocio** ⚠️
   - Depende de backend FEDI estar desplegado
   - Se puede validar después de resolver BD

5. **Servidor SMTP** ⚠️
   - Notificaciones son importantes pero no bloquean operación
   - Se puede activar después

---

## Logs de Diagnóstico Agregados

### Ubicación: AdminUsuariosServiceImpl.java

#### LOG 1 - Consulta PERITOS (Línea 115):
```java
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarios() - Consultando roles de PERITOS: " + this.autoRegistroUrl + vMetodo);
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarios() - Respuesta recibida, tamaño: " + (vCadenaResultado != null ? vCadenaResultado.length() : "null"));
```

#### LOG 2 - Consulta Usuarios por Rol (Línea 145):
```java
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarios() - Consultando usuarios del rol: " + nombreRol + " para sistema FEDI: " + this.sistemaIdentificadorInt);
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarios() - Usuarios obtenidos para rol: " + nombreRol);
```

#### LOG 3 - Consulta Usuario Interno (Línea 246):
```java
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarioInterno() - Consultando usuario: " + prmUsuario + " en sistema PERITOS");
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarioInterno() - Usuario encontrado: " + (vCadenaResultado != null && !vCadenaResultado.equals("FAIL")));
```

#### LOG 4 - Consulta LDAP (Línea 320):
```java
LOGGER.info("AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario() - Consultando info LDAP para usuario: " + prmHeaderBodyLDAP.getUser() + " en: " + this.ldpUrl + vMetodo);
LOGGER.info("AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario() - Respuesta LDAP recibida: " + (respuestaServicioPost != null && !respuestaServicioPost.equals("FAIL") ? "SUCCESS" : "FAIL"));
```

### Logs Pendientes de Agregar:
1. **Base de Datos:** Conexión y consultas
2. **SMTP:** Inicialización y envío de correos
3. **API FEDI:** Llamadas a endpoints de negocio

---

## Comandos de Verificación Manual

### 1. Verificar Token API Manager:
```bash
curl -X POST http://apimanager-qa.crt.gob.mx:8280/token \
  -H "Authorization: Basic V3FsMVBMdmpvZTh6U0RfNHFTRWIyNEhTOWZBYTpFeExrVEFsOEY0eEkxZ1BjaHh5Rk5TblFYQlFh" \
  -d "grant_type=client_credentials"
```

### 2. Verificar Endpoint PERITOS:
```bash
curl -X GET "https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT" \
  -H "Authorization: Bearer {token}"
```

### 3. Verificar Servicio LDAP:
```bash
curl -X POST "https://apimanager-qa.crt.gob.mx/ldp.inf.crt.gob.mx/v3.0/OBTENER_INFO" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"user":"usuario_test"}'
```

### 4. Verificar Conexión BD (desde servidor):
```bash
sqlplus usuario/password@host:puerto/servicio
```

### 5. Verificar SMTP (desde servidor):
```bash
telnet smtp.crt.gob.mx 587
# o
telnet smtp.crt.gob.mx 465
```

---

## Próximos Pasos

### Para Desarrollo:
1. ✅ Agregar logs de diagnóstico (completado)
2. ⏳ Compilar y desplegar versión con logs
3. ⏳ Probar en QA y capturar logs
4. ⏳ Documentar resultados de cada dependencia

### Para Soporte de Sistemas:
1. ❌ Registrar sistema PERITOS en API Manager CRT
2. ⏳ Configurar datasource JNDI `jdbc/fedi`
3. ⏳ Validar servicio LDAP publicado
4. ⏳ Proporcionar configuración SMTP CRT
5. ⏳ Migrar esquema de BD Oracle desde IFT

---

**Creado por:** Claude Code
**Fecha:** 2026-01-30
**Última actualización:** 2026-01-30
**Versión:** 1.0
**Estado:** Análisis completo - Pendiente validación con soporte
