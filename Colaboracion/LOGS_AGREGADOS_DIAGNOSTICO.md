# Logs de Diagnóstico Agregados para Validación de Dependencias

**Fecha:** 2026-01-30
**Objetivo:** Validar cada dependencia de FEDI en ambos dominios (IFT y CRT)
**Estado:** Listos para pruebas con IFT

---

## Resumen de Logs Agregados

Se agregaron logs en **3 archivos clave** para diagnosticar **5 dependencias críticas**:

### 1. AdminUsuariosServiceImpl.java
**Dependencias:** PERITOS, LDAP
**Total logs:** 8 líneas

### 2. FEDIServiceImpl.java
**Dependencia:** API FEDI (negocio)
**Total logs:** 3 líneas

### 3. NotificationServiceImpl.java
**Dependencia:** SMTP/Correo
**Total logs:** 6 líneas

---

## Detalle de Logs por Dependencia

### 🔴 DEPENDENCIA 1: Sistema PERITOS (0015MSPERITOSDES-INT)

#### Archivo: `src/main/java/fedi/ift/org/mx/arq/core/service/security/AdminUsuariosServiceImpl.java`

#### LOG 1.1 - Consulta de Roles PERITOS (Líneas 112-117)
```java
//IMPORTANTE: FEDI depende del sistema PERITOS (0015MSPERITOSDES-INT) para obtener el catálogo de usuarios firmantes
//Si este endpoint falla con 401, significa que el sistema PERITOS no está registrado en el API Manager
vMetodo = "registro/consultas/roles/2/1/"+"0015MSPERITOSDES-INT";
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarios() - Consultando roles de PERITOS: " + this.autoRegistroUrl + vMetodo);
vCadenaResultado = this.mDSeguridadService.EjecutaMetodoGET(this.tokenAcceso.getAccess_token(),this.autoRegistroUrl, vMetodo, lstParametros);
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarios() - Respuesta recibida, tamaño: " + (vCadenaResultado != null ? vCadenaResultado.length() : "null"));
```

**¿Qué valida?**
- ✅ URL completa del endpoint PERITOS
- ✅ Si el sistema PERITOS responde
- ✅ Tamaño de respuesta (indica si hay datos)

**Log Esperado en IFT:**
```
AdminUsuariosServiceImpl.obtenerUsuarios() - Consultando roles de PERITOS: https://apimanager-dev.ift.org.mx/srvAutoregistroQA/v1.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT
AdminUsuariosServiceImpl.obtenerUsuarios() - Respuesta recibida, tamaño: 1234
```

**Log Esperado en CRT (actual - FALLA):**
```
AdminUsuariosServiceImpl.obtenerUsuarios() - Consultando roles de PERITOS: https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT
AdminUsuariosServiceImpl.obtenerUsuarios() - Respuesta recibida, tamaño: null
[ERROR con HTTP 401]
```

---

#### LOG 1.2 - Consulta Usuarios por Rol (Líneas 145-147)
```java
vMetodo = "registro/consultas/roles/4/"+nombreSistema+"--"+nombreRol+"/"+this.sistemaIdentificadorInt;
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarios() - Consultando usuarios del rol: " + nombreRol + " para sistema FEDI: " + this.sistemaIdentificadorInt);
vCadenaResultado = this.mDSeguridadService.EjecutaMetodoGET(this.tokenAcceso.getAccess_token(),this.autoRegistroUrl, vMetodo, lstParametros);
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarios() - Usuarios obtenidos para rol: " + nombreRol);
```

**¿Qué valida?**
- ✅ Cada rol de PERITOS consultado
- ✅ Si se obtienen usuarios para ese rol
- ✅ Integración PERITOS → FEDI

---

#### LOG 1.3 - Búsqueda de Usuario Interno (Líneas 246-248)
```java
String vMetodo = "registro/consultas/roles/1/"+prmUsuario+"/"+"0015MSPERITOSDES-INT";
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarioInterno() - Consultando usuario: " + prmUsuario + " en sistema PERITOS");
vCadenaResultado = this.mDSeguridadService.EjecutaMetodoGET(this.tokenAcceso.getAccess_token(),this.autoRegistroUrl, vMetodo, lstParametros);
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarioInterno() - Usuario encontrado: " + (vCadenaResultado != null && !vCadenaResultado.equals("FAIL")));
```

**¿Qué valida?**
- ✅ Búsqueda de usuario específico en PERITOS
- ✅ Si el usuario existe

---

### 🟡 DEPENDENCIA 2: Servicio LDAP

#### Archivo: `src/main/java/fedi/ift/org/mx/arq/core/service/security/AdminUsuariosServiceImpl.java`

#### LOG 2.1 - Consulta Información LDAP (Líneas 320-322)
```java
LOGGER.info("AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario() - Consultando info LDAP para usuario: " + prmHeaderBodyLDAP.getUser() + " en: " + this.ldpUrl + vMetodo);
respuestaServicioPost=mDSeguridadService.EjecutaMetodoPOST(this.tokenAcceso.getAccess_token(), this.ldpUrl+vMetodo, "", lstParametros, prmHeaderBodyLDAP);
LOGGER.info("AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario() - Respuesta LDAP recibida: " + (respuestaServicioPost != null && !respuestaServicioPost.equals("FAIL") ? "SUCCESS" : "FAIL"));
```

**¿Qué valida?**
- ✅ URL del servicio LDAP
- ✅ Usuario consultado
- ✅ Si el servicio LDAP responde

**Log Esperado en IFT:**
```
AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario() - Consultando info LDAP para usuario: usuario.test en: https://apimanager-dev.ift.org.mx/ldp.inf.ift.org.mx/v1.0/OBTENER_INFO
AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario() - Respuesta LDAP recibida: SUCCESS
```

**Log Esperado en CRT:**
```
AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario() - Consultando info LDAP para usuario: usuario.test en: https://apimanager-qa.crt.gob.mx/ldp.inf.crt.gob.mx/v3.0/OBTENER_INFO
AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario() - Respuesta LDAP recibida: ? (por confirmar)
```

---

### 🟢 DEPENDENCIA 3: API FEDI (Negocio)

#### Archivo: `src/main/java/fedi/ift/org/mx/service/FEDIServiceImpl.java`

#### LOG 3.1 - Consulta Catálogo Tipo Firma (Líneas 82-86)
```java
this.ObtenTokenDeAcceso();
LOGGER.info("========== DEPENDENCIA: API FEDI ==========");
LOGGER.info("FEDIServiceImpl.obtenerTipoFirma() - URL: " + this.fediUrl + vMetodo);
respuestaServicioCat = mDSeguridadService.EjecutaMetodoGET(this.tokenAcceso.getAccess_token(),
                        this.fediUrl + vMetodo, "", lstParametros);
LOGGER.info("FEDIServiceImpl.obtenerTipoFirma() - Respuesta: " + (respuestaServicioCat != null && !respuestaServicioCat.equals("FAIL") ? "SUCCESS" : "FAIL"));
```

**¿Qué valida?**
- ✅ URL base de API FEDI
- ✅ Endpoint específico: catalogos/consultarTipoFirma
- ✅ Si el backend FEDI responde

**Log Esperado en IFT:**
```
========== DEPENDENCIA: API FEDI ==========
FEDIServiceImpl.obtenerTipoFirma() - URL: https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarTipoFirma
FEDIServiceImpl.obtenerTipoFirma() - Respuesta: SUCCESS
```

**Log Esperado en CRT:**
```
========== DEPENDENCIA: API FEDI ==========
FEDIServiceImpl.obtenerTipoFirma() - URL: https://apimanager-qa.crt.gob.mx/FEDI/v3.0/catalogos/consultarTipoFirma
FEDIServiceImpl.obtenerTipoFirma() - Respuesta: ? (por confirmar)
```

---

### 🔵 DEPENDENCIA 4: Servidor SMTP (Correo)

#### Archivo: `src/main/java/fedi/ift/org/mx/arq/core/service/mail/NotificationServiceImpl.java`

#### LOG 4.1 - Inicialización Servicio SMTP (Líneas 94-106)
```java
LOGGER.info("========== DEPENDENCIA: SMTP/CORREO ==========");
LOGGER.info("NotificationServiceImpl.init() - Servicio activo: " + active);
LOGGER.info("NotificationServiceImpl.init() - Host SMTP: " + (mailSender != null ? mailSender.getHost() : "null"));
LOGGER.info("NotificationServiceImpl.init() - Puerto: " + (mailSender != null ? mailSender.getPort() : "null"));
LOGGER.info("NotificationServiceImpl.init() - From: " + (from != null ? from.getAddress() : "null"));
...
LOGGER.info("NotificationServiceImpl.init() - MailEngine configurado correctamente");
```

**¿Qué valida?**
- ✅ Si el servicio de correo está activo
- ✅ Host SMTP configurado
- ✅ Puerto SMTP
- ✅ Cuenta de correo FROM

**Log Esperado en IFT:**
```
========== DEPENDENCIA: SMTP/CORREO ==========
NotificationServiceImpl.init() - Servicio activo: false
NotificationServiceImpl.init() - Host SMTP: smtp.gmail.com
NotificationServiceImpl.init() - Puerto: 465
NotificationServiceImpl.init() - From: test@metasoft.com.mx
NotificationServiceImpl.init() - MailEngine configurado correctamente
```

**Nota:** En ambos ambientes el servicio estará desactivado (`active: false`) hasta que se configure correctamente.

---

### 🟠 DEPENDENCIA 5: Base de Datos Oracle

#### Estado: SIN LOGS ESPECÍFICOS AGREGADOS

**Razón:** La conexión a BD se establece automáticamente por el contenedor (Tomcat/WebLogic) via JNDI. Los errores de BD se reflejan en:
1. **Startup:** Si no puede conectar, la aplicación no inicia
2. **Runtime:** Errores en queries específicas

**Validación:**
- ✅ Si la aplicación inicia correctamente → BD conectada
- ✅ Si las operaciones de login/documentos funcionan → BD operativa
- ❌ Si hay errores de "Cannot get connection" → BD no disponible

**Logs existentes del framework:**
- Spring/MyBatis ya loggean errores de BD automáticamente
- Buscar en logs: "SQLException", "Cannot get connection", "ORA-"

---

## Plan de Pruebas

### FASE 1: Validar IFT (Línea Base) ✅ LISTO PARA PROBAR

#### Configuración Actual:
- **Profile:** development-oracle1 (activo)
- **Dominio:** IFT
- **URLs:** apimanager-dev.ift.org.mx

#### Pasos:
1. ✅ Logs ya agregados
2. ⏳ Compilar: `mvn clean package -P development-oracle1`
3. ⏳ Desplegar WAR en Tomcat
4. ⏳ Probar:
   - Login con usuario IFT
   - Click en "Cargar documento y asignar firma"
   - Buscar usuario para agregar como firmante
5. ⏳ Capturar logs: `C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\fedi.log`
6. ⏳ Guardar como: `C:\github\Colaboracion\logs\IFT_VALIDACION_DEPENDENCIAS.log`

#### Logs a Buscar (IFT):
```
========== DEPENDENCIA: SMTP/CORREO ==========
AdminUsuariosServiceImpl.obtenerUsuarios() - Consultando roles de PERITOS:
========== DEPENDENCIA: API FEDI ==========
AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario() - Consultando info LDAP
```

---

### FASE 2: Validar CRT (Comparación) ⏳ PENDIENTE

#### Configuración a Cambiar:
- **Profile:** qa-oracle1 (cambiar en pom.xml línea 769)
- **Dominio:** CRT
- **URLs:** apimanager-qa.crt.gob.mx

#### Cambios en pom.xml:
```xml
<!-- Línea 722 -->
<activeByDefault>false</activeByDefault>  <!-- development-oracle1 -->

<!-- Línea 769 -->
<activeByDefault>true</activeByDefault>   <!-- qa-oracle1 -->
```

#### Pasos:
1. ⏳ Cambiar profile activo en pom.xml
2. ⏳ Compilar: `mvn clean package -P qa-oracle1`
3. ⏳ Desplegar WAR en Tomcat
4. ⏳ Probar mismas operaciones que en IFT
5. ⏳ Capturar logs
6. ⏳ Guardar como: `C:\github\Colaboracion\logs\CRT_VALIDACION_DEPENDENCIAS.log`

#### Logs a Buscar (CRT):
- Mismos markers que IFT
- Comparar URLs (ift.org.mx vs crt.gob.mx)
- Identificar cuáles dependencias fallan

---

## Tabla de Comparación (Para completar después de pruebas)

| Dependencia | IFT Status | IFT URL | CRT Status | CRT URL | Problema CRT |
|-------------|-----------|---------|-----------|---------|--------------|
| **API Manager** | ✅ | apimanager-dev.ift.org.mx | ? | apimanager-qa.crt.gob.mx | ? |
| **Sistema PERITOS** | ✅ | .../srvAutoregistroQA/v1.0/... | ❌ | .../srvAutoregistroQA/v3.0/... | HTTP 401 |
| **Servicio LDAP** | ✅ | .../ldp.inf.ift.org.mx/v1.0/... | ? | .../ldp.inf.crt.gob.mx/v3.0/... | ? |
| **API FEDI** | ? | .../FEDI/v1.0/... | ? | .../FEDI/v3.0/... | ? |
| **Base de Datos** | ✅ | (JNDI interno) | ? | (JNDI interno) | ? |
| **SMTP** | ⚠️ Desactivado | smtp.gmail.com:465 | ⚠️ Desactivado | smtp.gmail.com:465 | No configurado |

---

## Cómo Interpretar los Logs

### ✅ Dependencia FUNCIONAL:
```
AdminUsuariosServiceImpl.obtenerUsuarios() - Consultando roles de PERITOS: https://...
AdminUsuariosServiceImpl.obtenerUsuarios() - Respuesta recibida, tamaño: 1234
```
- Tamaño > 0 indica que hay datos
- No hay errores HTTP después

### ❌ Dependencia FALLANDO:
```
AdminUsuariosServiceImpl.obtenerUsuarios() - Consultando roles de PERITOS: https://...
AdminUsuariosServiceImpl.obtenerUsuarios() - Respuesta recibida, tamaño: null
ERROR ... HTTP error code : 401
```
- Tamaño null indica sin respuesta
- Código HTTP 401/404/500 indica problema

### ⚠️ Dependencia DESACTIVADA:
```
NotificationServiceImpl.init() - Servicio activo: false
```
- No es un error, está intencionalmente desactivado

---

## Archivos Modificados

### 1. AdminUsuariosServiceImpl.java
- **Líneas modificadas:** 112-117, 145-147, 246-248, 320-322
- **Función:** Diagnóstico PERITOS y LDAP
- **Total cambios:** 8 líneas de logs

### 2. FEDIServiceImpl.java
- **Líneas modificadas:** 82-86
- **Función:** Diagnóstico API FEDI
- **Total cambios:** 3 líneas de logs

### 3. NotificationServiceImpl.java
- **Líneas modificadas:** 94-106
- **Función:** Diagnóstico SMTP
- **Total cambios:** 6 líneas de logs

---

## Comandos Útiles

### Compilar (perfil actual):
```bash
cd C:\github\fedi-web
mvn clean package
```

### Ver perfil activo:
```bash
# Buscar en pom.xml líneas 721-722 y 768-769
# El que tenga <activeByDefault>true</activeByDefault> es el activo
```

### Copiar logs:
```bash
copy "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\fedi.log" "C:\github\Colaboracion\logs\IFT_VALIDACION_DEPENDENCIAS.log"
```

### Buscar logs específicos:
```bash
# En PowerShell
Select-String -Path "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\fedi.log" -Pattern "DEPENDENCIA"
Select-String -Path "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\fedi.log" -Pattern "PERITOS"
Select-String -Path "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\fedi.log" -Pattern "LDAP"
```

---

## Próximos Pasos

### Inmediato (HOY):
1. ✅ Logs agregados
2. ⏳ Compilar con perfil IFT
3. ⏳ Desplegar y probar IFT
4. ⏳ Documentar resultados IFT

### Después (Siguiente sesión):
1. ⏳ Cambiar a perfil CRT
2. ⏳ Compilar y probar CRT
3. ⏳ Comparar logs IFT vs CRT
4. ⏳ Crear ticket para soporte con checklist

---

**Creado por:** Claude Code
**Fecha:** 2026-01-30
**Última actualización:** 2026-01-30 16:30
**Versión:** 1.0
**Estado:** Listo para pruebas con IFT
