# Guía de Migración de Dominio IFT a CRT

**Fecha:** 2026-01-29
**Estado:** PENDIENTE
**Última Prueba Exitosa:** IFT funcionando con logs

## 1. Contexto

### Situación Actual
- ✅ IFT funcionando: Usuario dgtic.dds.ext023@ift.org.mx entra sin problemas
- ❌ CRT no probado aún: Usuario deid.ext33@crt.gob.mx sin probar con configuración correcta
- ✅ Logs completos agregados para diagnóstico

### Objetivo
Permitir que usuarios CRT (deid.ext33@crt.gob.mx) se autentiquen en FEDI cambiando URLs de IFT a CRT.

### Restricciones
- Usuarios IFT y CRT están registrados en Active Directory correspondiente (confirmado por infraestructura)
- Token ID es el mismo para IFT y CRT (confirmado)
- Backend IFT agrega automáticamente @ift.org.mx al username
- **Hipótesis:** Backend CRT probablemente funciona igual que IFT

---

## 2. Escenarios Posibles

### Escenario A: CRT Igual que IFT (PROBABILIDAD: ALTA)
**Características:**
- Backend CRT agrega automáticamente @crt.gob.mx
- Usuario ingresa solo: "deid.ext33"
- URL generada: `.../0022FEDI/deid.ext33/...`
- Backend transforma a: `deid.ext33@crt.gob.mx`

**Evidencia a Favor:**
- IFT funciona de esta manera
- Mismo sistema de API Manager (WSO2)
- Token ID compartido sugiere misma arquitectura

**Cambios Requeridos:**
- ✅ Solo cambiar URLs en pom.xml
- ❌ NO cambiar código Java

**Probabilidad:** 80%

---

### Escenario B: CRT Requiere Dominio Explícito (PROBABILIDAD: BAJA)
**Características:**
- Backend CRT NO agrega dominio automáticamente
- Usuario debe ingresar: "deid.ext33@crt.gob.mx"
- O código debe agregarlo: `prmUsername + "@crt.gob.mx"`

**Evidencia a Favor:**
- Ninguna (solo precaución)

**Cambios Requeridos:**
- ✅ Cambiar URLs en pom.xml
- ✅ Agregar lógica condicional en AuthenticationServiceImpl.java
- ❌ NO agregar URL encoding (backend espera @ sin codificar)

**Probabilidad:** 20%

---

### Escenario C: Usuarios CRT No Existen en AD (PROBABILIDAD: BAJA)
**Características:**
- Problema de infraestructura, no de código
- Usuarios CRT no registrados en Active Directory CRT
- HTTP 500: "validación en el repositorio central"

**Evidencia a Favor:**
- Infraestructura confirmó que usuarios están registrados

**Solución:**
- Contactar equipo de infraestructura
- Verificar registro en AD
- Verificar permisos de acceso

**Probabilidad:** 10% (ya descartado por infraestructura)

---

## 3. Plan de Migración Paso a Paso

### Fase 1: Preparación (15 minutos)

#### 1.1. Backup de Configuración Actual
```bash
# En servidor Windows con git
cd C:\github\fedi-web

# Crear rama para trabajo de migración
git checkout -b migracion-crt

# Verificar estado limpio
git status
```

#### 1.2. Backup de WAR Funcionando
```
Origen: C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\FEDIPortalWeb-1.0.war
Destino: C:\github\Colaboracion\backups\FEDIPortalWeb-1.0-IFT-FUNCIONANDO.war

Fecha: Antes de hacer cambios
```

#### 1.3. Documentar Configuración IFT
Guardar copia de `pom.xml` actual (líneas 751-764):
```xml
<profile.mdsgd.token.url>http://apimanager-dev.ift.org.mx/token</profile.mdsgd.token.url>
<profile.lgn.api.url>https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/</profile.lgn.api.url>
<profile.fedi.url>https://apimanager-dev.ift.org.mx/FEDI/v1.0/</profile.fedi.url>
<!-- ... resto de URLs IFT ... -->
```

---

### Fase 2: Cambios en pom.xml (10 minutos)

#### 2.1. Modificar URLs de IFT a CRT
**Archivo:** `pom.xml` líneas 751-764

**Cambios:**
```xml
<!-- ANTES (IFT) -->
<profile.mdsgd.token.url>http://apimanager-dev.ift.org.mx/token</profile.mdsgd.token.url>
<profile.mdsgd.token.id>Basic VGZxc3BCYWVYZHhCNlF0SUJHV0EzZUxpMkw0YTpWTUdUVHhqUDVkMl91eFoxdW5uSVBSTGpmZ01h</profile.mdsgd.token.id>
<profile.mdsgd.api.url>https://apimanager-dev.ift.org.mx/</profile.mdsgd.api.url>
<profile.lgn.api.url>https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/</profile.lgn.api.url>
<profile.mdsgd.bit.url>https://apimanager-dev.ift.org.mx/LogEventos/v1.0/bitacora</profile.mdsgd.bit.url>
<profile.sistema.identificador>0022FEDI</profile.sistema.identificador>
<profile.sistema.identif.ext>0022FEDI</profile.sistema.identif.ext>
<profile.autoregistro.url>http://apimanager-dev.ift.org.mx/AutoRegistro/v1.0/autoregistro/</profile.autoregistro.url>
<profile.ldp.url>http://fwldp-dev.ift.org.mx/pruebasPlataformaDigital/api/</profile.ldp.url>
<profile.fedi.url>https://apimanager-dev.ift.org.mx/FEDI/v1.0/</profile.fedi.url>
<profile.fedi.notificaciones.url>https://apimanager-dev.ift.org.mx/Notificaciones/v1.0/</profile.fedi.notificaciones.url>

<!-- DESPUÉS (CRT) -->
<profile.mdsgd.token.url>http://apimanager-dev.crt.gob.mx/token</profile.mdsgd.token.url>
<profile.mdsgd.token.id>Basic VGZxc3BCYWVYZHhCNlF0SUJHV0EzZUxpMkw0YTpWTUdUVHhqUDVkMl91eFoxdW5uSVBSTGpmZ01h</profile.mdsgd.token.id>
<profile.mdsgd.api.url>https://apimanager-dev.crt.gob.mx/</profile.mdsgd.api.url>
<profile.lgn.api.url>https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/</profile.lgn.api.url>
<profile.mdsgd.bit.url>https://apimanager-dev.crt.gob.mx/LogEventos/v1.0/bitacora</profile.mdsgd.bit.url>
<profile.sistema.identificador>0022FEDI</profile.sistema.identificador>
<profile.sistema.identif.ext>0022FEDI</profile.sistema.identif.ext>
<profile.autoregistro.url>http://apimanager-dev.crt.gob.mx/AutoRegistro/v1.0/autoregistro/</profile.autoregistro.url>
<profile.ldp.url>http://fwldp-dev.crt.gob.mx/pruebasPlataformaDigital/api/</profile.ldp.url>
<profile.fedi.url>https://apimanager-dev.crt.gob.mx/FEDI/v1.0/</profile.fedi.url>
<profile.fedi.notificaciones.url>https://apimanager-dev.crt.gob.mx/Notificaciones/v1.0/</profile.fedi.notificaciones.url>
```

**Resumen de Cambios:**
- `ift.org.mx` → `crt.gob.mx`
- Token ID: SIN CAMBIOS (mismo para ambos)
- Sistema Identificador: SIN CAMBIOS (0022FEDI para ambos)

#### 2.2. Verificar Cambios
```bash
# Ver diferencias
git diff pom.xml

# Confirmar que solo cambiaron URLs
```

---

### Fase 3: Compilación (5 minutos)

```bash
cd C:\github\fedi-web
mvn clean package -P development-oracle1
```

**Verificación Exitosa:**
```
[INFO] BUILD SUCCESS
[INFO] Total time: ~35 segundos
[INFO] WAR: C:\github\fedi-web\target\FEDIPortalWeb-1.0.war
```

---

### Fase 4: Despliegue en Tomcat (10 minutos)

#### 4.1. Detener Tomcat
```
Servicios → Apache Tomcat 9.0 FEDIDEV → Detener
```

#### 4.2. Backup del WAR Anterior
```
Origen: C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\FEDIPortalWeb-1.0.war
Destino: C:\github\Colaboracion\backups\FEDIPortalWeb-1.0-PRE-CRT.war
```

#### 4.3. Desplegar Nuevo WAR
```
Origen: C:\github\fedi-web\target\FEDIPortalWeb-1.0.war
Destino: C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\FEDIPortalWeb-1.0.war

Método: Copia manual vía escritorio remoto
```

#### 4.4. Iniciar Tomcat
```
Servicios → Apache Tomcat 9.0 FEDIDEV → Iniciar
```

#### 4.5. Verificar Inicio
```
Logs: C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\catalina.out
Buscar: "Server startup in [XXXX] milliseconds"
```

---

### Fase 5: Pruebas de Autenticación (20 minutos)

#### 5.1. Prueba 1: Usuario CRT Sin Dominio (Escenario A)
**URL:** https://fedidev.crt.gob.mx/FEDIPortalWeb-1.0/content/common/Login.jsf

**Credenciales:**
- Usuario: `deid.ext33` (sin @crt.gob.mx)
- Contraseña: (contraseña del usuario)
- ✅ Externo: (marcar si aplica)

**Logs a Capturar:**
```
C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\fedi.log
```

**Buscar en Logs:**
```
=== INICIO LOGIN === Usuario: deid.ext33, EsExterno: false
>>> Token URL: http://apimanager-dev.crt.gob.mx/token
>>> Login API URL: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/
>>> Username: deid.ext33
>>> URL completa: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/0022FEDI/deid.ext33/...
@@@@@@ Respuesta recibida - Codigo HTTP: ???
```

**Resultados Esperados por Escenario:**

| HTTP Code | Escenario | Diagnóstico | Acción |
|-----------|-----------|-------------|--------|
| 200 | A | ✅ CRT igual que IFT | Migración exitosa |
| 500 "validación..." | C | ❌ Usuario no existe en AD | Contactar infraestructura |
| 404 | B | ⚠️ CRT requiere dominio explícito | Ir a Fase 6 (Plan B) |
| 502 | - | ❌ Backend CRT no disponible | Verificar conectividad |

#### 5.2. Prueba 2: Usuario CRT Con Dominio (Si Prueba 1 Falla)
**Credenciales:**
- Usuario: `deid.ext33@crt.gob.mx` (con dominio completo)
- Contraseña: (contraseña del usuario)

**Solo si Prueba 1 da HTTP 404 o 500**

#### 5.3. Guardar Logs Completos
```bash
# Copiar logs a carpeta de colaboración
copy "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\fedi.log" C:\github\fedi-web\logs\log-crt-prueba1.txt
```

---

### Fase 6: Plan B - Lógica Condicional (SOLO SI ESCENARIO B)

**Condición:** Solo ejecutar si Prueba 1 dio HTTP 404 y Prueba 2 fue exitosa.

#### 6.1. Modificar AuthenticationServiceImpl.java

**Ubicación:** Líneas 139-155 (después de loginUsuario() inicio)

**Código a Agregar:**
```java
private UserDetails loginUsuario(String prmSistema, String prmUsername, String prmClave, Boolean prmEsExterno) throws Exception{
    String vCadenaResultado="";
    StringBuilder vbuilder = new StringBuilder();
    String vMetodo="";
    Credencial credencial= new Credencial();
    Usuario usrio= new Usuario();
    Gson gson = new Gson();
    List<ParametrosWS> lstParametros = new ArrayList();
    String vTipoUsuario="";
    try{
        LOGGER.info(">>> loginUsuario() - INICIO");
        LOGGER.info(">>> Sistema: {}", prmSistema);
        LOGGER.info(">>> Username: {}", prmUsername);
        LOGGER.info(">>> EsExterno: {}", prmEsExterno);
        LOGGER.info(">>> Token URL: {}", mdsgdTokenUrl);
        LOGGER.info(">>> Login API URL: {}", lgnApiUrl);

        // ===== NUEVO CÓDIGO - PLAN B =====
        // Determinar si backend requiere dominio explícito
        // Backend CRT requiere dominio, IFT NO
        if (!prmUsername.contains("@")) {
            if (lgnApiUrl.contains("crt.gob.mx")) {
                // Backend CRT requiere dominio explícito
                prmUsername = prmUsername + "@crt.gob.mx";
                LOGGER.info(">>> Username con dominio CRT agregado: {}", prmUsername);
            }
            // IFT no requiere dominio, backend lo agrega automáticamente
            // NO agregar nada para IFT
        }
        // ===== FIN NUEVO CÓDIGO =====

        //Paso 1. Obtención del Token
        this.ObtenTokenDeAcceso();
        LOGGER.info(">>> Token obtenido exitosamente");

        // ... resto del código sin cambios
```

**IMPORTANTE:**
- NO usar URLEncoder - backend espera @ sin codificar
- Verificar con `lgnApiUrl.contains("crt.gob.mx")` para detectar backend CRT
- IFT no necesita cambios (backend agrega dominio automáticamente)

#### 6.2. Recompilar y Redesplegar
Repetir Fase 3 y Fase 4.

#### 6.3. Probar Nuevamente Usuario CRT Sin Dominio
Repetir Prueba 1 - ahora código agrega @crt.gob.mx automáticamente.

---

## 4. Análisis de Logs Post-Migración

### Logs de Éxito (HTTP 200)
```
2026-01-XX XX:XX:XX INFO  LoginMB:251 - === INICIO LOGIN === Usuario: deid.ext33, EsExterno: false
2026-01-XX XX:XX:XX INFO  AuthenticationServiceImpl:67 - ====== AuthenticationServiceImpl.login() INICIO ======
2026-01-XX XX:XX:XX INFO  AuthenticationServiceImpl:68 - Usuario: deid.ext33
2026-01-XX XX:XX:XX INFO  AuthenticationServiceImpl:78 - Autenticando como USUARIO INTERNO con sistema: 0022FEDI
2026-01-XX XX:XX:XX INFO  AuthenticationServiceImpl:154 - >>> Login API URL: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:126 - ****** Respuesta recibida - Codigo HTTP: 200
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:136 - ****** Token obtenido exitosamente
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:194 - @@@@@@ Respuesta recibida - Codigo HTTP: 200
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:202 - @@@@@@ Autenticacion EXITOSA - respuesta recibida
2026-01-XX XX:XX:XX INFO  AuthenticationServiceImpl:85 - ====== AUTENTICACION EXITOSA para usuario: deid.ext33 ======
2026-01-XX XX:XX:XX INFO  LoginMB:259 - === LOGIN EXITOSO === Usuario: deid.ext33
```

**Diagnóstico:** ✅ Escenario A confirmado - CRT funciona igual que IFT

---

### Logs de Error HTTP 500 (Usuario No Existe)
```
2026-01-XX XX:XX:XX INFO  LoginMB:251 - === INICIO LOGIN === Usuario: deid.ext33, EsExterno: false
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:126 - ****** Respuesta recibida - Codigo HTTP: 200
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:136 - ****** Token obtenido exitosamente
2026-01-XX XX:XX:XX ERROR MDSeguridadServiceImpl:206 - @@@@@@ Error credenciales de usuario: 500 - Internal Server Error
2026-01-XX XX:XX:XX ERROR MDSeguridadServiceImpl:208 - @@@@@@ Detalle del error: {"code":"500","message":"La autenticación del usuario deid.ext33 no es correcta, validación en el repositorio central"}
2026-01-XX XX:XX:XX ERROR AuthenticationServiceImpl:99 - ====== ERROR AuthenticationServiceImpl.login() ======
2026-01-XX XX:XX:XX ERROR AuthenticationServiceImpl:101 - Codigo Error: 500, Mensaje: La autenticación del usuario deid.ext33 no es correcta
```

**Diagnóstico:** ❌ Escenario C - Usuario no existe en Active Directory CRT

**Acción:** Contactar equipo de infraestructura para verificar:
1. Usuario registrado en AD CRT
2. Permisos de acceso correctos
3. Grupo de seguridad asignado

---

### Logs de Error HTTP 404 (Backend Requiere Dominio)
```
2026-01-XX XX:XX:XX INFO  LoginMB:251 - === INICIO LOGIN === Usuario: deid.ext33, EsExterno: false
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:126 - ****** Respuesta recibida - Codigo HTTP: 200
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:136 - ****** Token obtenido exitosamente
2026-01-XX XX:XX:XX INFO  AuthenticationServiceImpl:182 - >>> URL completa: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/0022FEDI/deid.ext33/...
2026-01-XX XX:XX:XX ERROR MDSeguridadServiceImpl:206 - @@@@@@ Error credenciales de usuario: 404 - Not Found
2026-01-XX XX:XX:XX ERROR MDSeguridadServiceImpl:208 - @@@@@@ Detalle del error: {"code":"404","message":"No matching resource found for given API Request"}
```

**Diagnóstico:** ⚠️ Escenario B - Backend CRT requiere dominio explícito

**Acción:** Implementar Fase 6 (Plan B) - Agregar lógica condicional para CRT

---

### Logs de Error HTTP 502 (Backend No Disponible)
```
2026-01-XX XX:XX:XX INFO  LoginMB:251 - === INICIO LOGIN === Usuario: deid.ext33, EsExterno: false
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:126 - ****** Respuesta recibida - Codigo HTTP: 200
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:136 - ****** Token obtenido exitosamente
2026-01-XX XX:XX:XX ERROR MDSeguridadServiceImpl:212 - @@@@@@ Error IOException en EjecutaMetodoGET: timeout
```

**Diagnóstico:** ❌ Backend CRT no disponible o problema de red

**Acción:** Verificar:
1. Conectividad desde servidor a apimanager-dev.crt.gob.mx
2. Backend CRT operativo (contactar infraestructura)
3. Firewall permitiendo conexiones salientes a CRT

---

## 5. Rollback (Si Migración Falla)

### Opción 1: Restaurar pom.xml de GIT
```bash
cd C:\github\fedi-web
git checkout pom.xml
```

### Opción 2: Revertir Cambios Manualmente
Editar `pom.xml` líneas 751-764 y cambiar todas las URLs de `crt.gob.mx` a `ift.org.mx`.

### Opción 3: Desplegar WAR de Backup
```
Origen: C:\github\Colaboracion\backups\FEDIPortalWeb-1.0-IFT-FUNCIONANDO.war
Destino: C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\FEDIPortalWeb-1.0.war
```

### Verificación Post-Rollback
Probar usuario IFT: dgtic.dds.ext023 (sin dominio) - debe funcionar.

---

## 6. Checklist de Migración

### Pre-Migración
- [ ] Backup de WAR funcionando (IFT)
- [ ] Backup de pom.xml actual
- [ ] Crear rama git: migracion-crt
- [ ] Verificar usuarios CRT registrados en AD (confirmar con infraestructura)
- [ ] Verificar conectividad servidor → apimanager-dev.crt.gob.mx

### Migración
- [ ] Cambiar URLs en pom.xml (ift.org.mx → crt.gob.mx)
- [ ] Verificar Token ID sin cambios
- [ ] Compilar: mvn clean package
- [ ] Desplegar WAR en Tomcat
- [ ] Reiniciar Tomcat
- [ ] Verificar inicio exitoso

### Pruebas
- [ ] Prueba 1: Usuario CRT sin dominio (deid.ext33)
- [ ] Capturar logs completos
- [ ] Analizar HTTP response code
- [ ] Si HTTP 404: Prueba 2 con dominio completo (deid.ext33@crt.gob.mx)
- [ ] Si HTTP 500: Verificar con infraestructura
- [ ] Si HTTP 200: ✅ Migración exitosa

### Post-Migración (Si Exitosa)
- [ ] Commit cambios en git
- [ ] Merge a rama principal (QA o master según proceso)
- [ ] Documentar configuración CRT final
- [ ] Actualizar documentación de deployment
- [ ] Notificar a usuarios disponibilidad de CRT

### Rollback (Si Falla)
- [ ] Restaurar pom.xml de GIT o backup
- [ ] Recompilar con configuración IFT
- [ ] Redesplegar WAR
- [ ] Verificar IFT funcionando
- [ ] Analizar logs para diagnóstico
- [ ] Crear ticket con infraestructura si es problema de AD

---

## 7. Contactos y Escalamiento

### Si HTTP 500 (Usuario No Existe)
**Contacto:** Equipo de infraestructura / Active Directory
**Info a Proveer:**
- Usuario: deid.ext33@crt.gob.mx
- Mensaje error: "validación en el repositorio central"
- Solicitar verificación de registro en AD CRT

### Si HTTP 502 (Backend No Disponible)
**Contacto:** Equipo de infraestructura / Redes
**Info a Proveer:**
- URL: apimanager-dev.crt.gob.mx
- Puertos: 80 (HTTP), 443 (HTTPS)
- Solicitar verificación de disponibilidad del backend

### Si HTTP 404 (API No Encontrada)
**Contacto:** Equipo de API Manager / WSO2
**Info a Proveer:**
- URL completa de la llamada (de logs)
- API esperada: `/autorizacion/login/v1.0/credencial/`
- Solicitar verificación de configuración de rutas en WSO2

---

## 8. Notas Importantes

### ⚠️ NO Hacer
1. ❌ NO agregar URLEncoder al username
2. ❌ NO modificar Token ID (es el mismo para IFT y CRT)
3. ❌ NO cambiar Sistema Identificador (0022FEDI)
4. ❌ NO modificar password encoding (Encoder + Base64)

### ✅ Solo Hacer
1. ✅ Cambiar URLs de ift.org.mx a crt.gob.mx
2. ✅ Agregar lógica condicional SOLO si Escenario B se confirma
3. ✅ Capturar logs completos para análisis
4. ✅ Probar sin dominio primero (usuario solo: "deid.ext33")

---

**Última Actualización:** 2026-01-29 23:10
**Autor:** Claude Code
**Versión:** 1.0
**Estado:** LISTO PARA EJECUTAR
