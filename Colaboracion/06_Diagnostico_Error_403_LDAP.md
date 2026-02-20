# Diagnóstico Error 403 LDAP

**Fecha:** 16/Feb/2026
**Problema:** Error 403 al consultar información de usuario en LDAP
**Usuario afectado:** deid.ext33@crt.gob.mx

---

## 1. SÍNTOMAS

### 1.1 Error Reportado
```
Error al obtener el detalle del usuario, AdminRolMB.obtenerDetalleUsuario:
AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario(): Failed : HTTP error code : 403
AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario(): Failed : HTTP error code : 403
```

### 1.2 Comportamiento Observado
- ✅ El usuario **SÍ puede iniciar sesión** con cuenta CRT
- ✅ El usuario **SÍ puede cargar archivos PDF**
- ❌ El usuario **NO puede ver búsqueda de usuarios**
- ❌ El sistema **NO puede obtener información detallada del usuario desde LDAP**

### 1.3 Análisis de Logs (fedi4.txt líneas 670-686)

**Token de acceso: ✅ EXITOSO**
```
2026-02-16 19:23:37,073 [INFO] MDSeguridadServiceImpl:147 -
[MDSeguridadService.ObtenTokenDeAcceso] exitoso. StatusCode=200, Duracion=16ms
```
- El token se obtiene correctamente del API Manager
- No hay problemas de autenticación básica

**Consulta LDAP: ❓ SIN RESPUESTA VISIBLE**
```
2026-02-16 19:23:37,073 [INFO] AdminUsuariosServiceImpl:299 -
AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario() -
Consultando info LDAP para usuario: deid.ext33 en:
https://apimanager-dev.crt.gob.mx/ldp.inf.ift.org.mx/v1.0/OBTENER_INFO
```
- La URL es correcta
- No vemos el log de respuesta (línea 301 no aparece en el log)
- Esto sugiere que la excepción se lanza en línea 300 (dentro del POST)

---

## 2. ANÁLISIS TÉCNICO

### 2.1 Flujo de Ejecución

```
1. Usuario accede a sección de carga de documentos
   ↓
2. DocumentoVistaFirmaMB.initListener() llama a obtenerDetalleUsuario()
   ↓
3. AdminRolMB.obtenerDetalleUsuario()
   ↓
4. AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario()
   ├─ ObtenTokenDeAcceso() → ✅ ÉXITO (200 OK)
   └─ mDSeguridadService.EjecutaMetodoPOST() → ❌ FALLA (403 Forbidden)
       URL: https://apimanager-dev.crt.gob.mx/ldp.inf.ift.org.mx/v1.0/OBTENER_INFO
       Body: HeaderBodyLDAP { user: "deid.ext33", ... }
       Token: Bearer [token_obtenido]
```

### 2.2 Posibles Causas del Error 403

#### Causa 1: **Scope del Token Insuficiente** (ALTA PROBABILIDAD)
El token obtenido de `http://apimanager-dev.crt.gob.mx/token` puede no tener los **scopes/permisos** necesarios para acceder al servicio LDAP.

**Evidencia:**
- Token se obtiene correctamente (200 OK)
- Pero el API Manager rechaza la petición LDAP con 403
- 403 = "Forbidden" = Token válido pero sin permisos

**Solución:**
- Verificar configuración de scopes en API Manager para el servicio `ldp.inf.ift.org.mx`
- Verificar que el cliente OAuth2 tenga acceso al recurso LDAP

#### Causa 2: **Usuario Externo Sin Permisos** (MEDIA PROBABILIDAD)
El usuario `deid.ext33@crt.gob.mx` es un usuario **externo** (sufijo `ext33`). Puede que:
- El servicio LDAP solo permita consultas de usuarios internos
- El usuario externo no tenga permisos para consultar información de otros usuarios

**Evidencia:**
- Usuario logueado: `deid.ext33@crt.gob.mx` (EXTERNO)
- Configuración en pom.xml muestra dos dominios LDAP:
  - `admin@msperitos-int.crt.gob.mx` (INTERNO)
  - `admin@msperitos-ext.crt.gob.mx` (EXTERNO)

**Preguntas:**
- ¿El código está usando el dominio correcto para usuarios externos?
- ¿El servicio LDAP permite a usuarios externos consultar su propia información?

#### Causa 3: **Configuración del API Manager** (MEDIA PROBABILIDAD)
El API Manager puede estar bloqueando el acceso por:
- IP/origen no autorizado
- Rate limiting excedido
- Políticas de seguridad del API Gateway

#### Causa 4: **Cambio de Dominio IFT → CRT** (BAJA PROBABILIDAD)
Después de la migración de dominios, puede haber:
- Configuraciones de CORS no actualizadas
- Certificados no reconocidos en el API Manager
- Políticas de seguridad que aún apuntan a dominios IFT

---

## 3. DIFERENCIA: ¿POR QUÉ LOGIN SÍ FUNCIONA Y LDAP NO?

| Operación | Servicio | Token Necesario | Estado |
|-----------|----------|-----------------|--------|
| **Login** | WSO2 Identity Server | No (usa credenciales directas) | ✅ Funciona |
| **Obtener Info LDAP** | API Manager → LDAP | Sí (Bearer token con scopes) | ❌ Error 403 |

**Explicación:**
- El **login** usa autenticación directa contra WSO2 Identity Server con usuario/password
- La **consulta LDAP** usa token OAuth2 que requiere permisos específicos en API Manager

---

## 4. CAMBIOS RECIENTES QUE PUEDEN AFECTAR

### 4.1 Migración SSL (16/Feb/2026)
- ✅ Se agregó soporte para certificados autofirmados en desarrollo
- ✅ Se migró `EjecutaMetodoPOST` de `HttpURLConnection` a `OkHttpClient`
- ✅ Esto **resuelve** problemas SSL, pero **NO afecta** errores 403 de autorización

### 4.2 Migración de Dominios IFT → CRT
- Se cambió `apimanager-dev.ift.org.mx` → `apimanager-dev.crt.gob.mx`
- Se cambió `identityserver-dev.ift.org.mx` → `identityserver-dev.crt.gob.mx`
- **Posible impacto:** Si el API Manager en CRT tiene configuraciones diferentes

---

## 5. INFORMACIÓN TÉCNICA CLAVE

### 5.1 URLs Involucradas
```properties
# Token OAuth2
mdsgd.token.url=http://apimanager-dev.crt.gob.mx/token
mdsgd.token.id=[CLIENT_ID_SECRET]

# Servicio LDAP (FALLA con 403)
ldp.url=https://apimanager-dev.crt.gob.mx/ldp.inf.ift.org.mx/v1.0/

# WSO2 Identity Server (LOGIN - FUNCIONA)
wso2.identity-server.url=https://identityserver-dev.crt.gob.mx
```

### 5.2 Credenciales LDAP (pom.xml líneas 834-837)
```xml
<profile.wso2.ldap.username>admin@msperitos-int.crt.gob.mx</profile.wso2.ldap.username>
<profile.wso2.ldap.password>admPeritos</profile.wso2.ldap.password>
<profile.wso2.ldap.username.ext>admin@msperitos-ext.crt.gob.mx</profile.wso2.ldap.username.ext>
<profile.wso2.ldap.password.ext>admPeritos</profile.wso2.ldap.password.ext>
```

**Observación:** Estas credenciales se usan para WSO2, **NO** para el API Manager. El API Manager usa token OAuth2.

### 5.3 Código Relevante (AdminUsuariosServiceImpl.java:298-300)
```java
this.ObtenTokenDeAcceso();  // ✅ ÉXITO
LOGGER.info("AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario() - Consultando info LDAP...");
respuestaServicioPost = mDSeguridadService.EjecutaMetodoPOST(
    this.tokenAcceso.getAccess_token(),  // Token Bearer
    this.ldpUrl + vMetodo,               // URL completa
    "",                                  // Sin metodo adicional
    lstParametros,                       // Vacío
    prmHeaderBodyLDAP                    // Body: { user: "deid.ext33", ... }
);  // ❌ FALLA CON 403
```

---

## 6. ACCIONES RECOMENDADAS (EN ORDEN DE PRIORIDAD)

### 6.1 INMEDIATO: Habilitar Logs Detallados
**Objetivo:** Ver el error completo del API Manager

**Modificar:** `MDSeguridadServiceImpl.java` línea 385-388

```java
} else {
    String msgerror = response.body().string();
    LOGGER.error("[MDSeguridadService.EjecutaMetodoPOST] error. StatusCode=" + response.code()
        + ", Message=" + response.message()
        + ", ErrorBody=" + msgerror  // ← ESTE LOG ES CRÍTICO
        + ", Duracion=" + duration + "ms");
    throw new RuntimeException("Failed : HTTP error code : " + response.code());
}
```

**Revisar:** El log debe mostrar el `ErrorBody` que contendrá el mensaje del API Manager explicando por qué rechaza la petición.

### 6.2 PRIORITARIO: Verificar Configuración del API Manager

**Preguntas para el equipo de infraestructura:**
1. ¿El token OAuth2 obtenido tiene scope para acceder a `ldp.inf.ift.org.mx`?
2. ¿El cliente OAuth2 tiene permisos para el recurso LDAP en el API Manager?
3. ¿Hubo cambios en políticas de seguridad al migrar de IFT a CRT?
4. ¿El usuario `deid.ext33` está en la lista de usuarios permitidos?

**Verificación manual con curl:**
```bash
# 1. Obtener token
TOKEN=$(curl -X POST "http://apimanager-dev.crt.gob.mx/token" \
  -H "authorization: [CLIENT_ID_SECRET]" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" | jq -r '.access_token')

# 2. Probar servicio LDAP
curl -X POST "https://apimanager-dev.crt.gob.mx/ldp.inf.ift.org.mx/v1.0/OBTENER_INFO" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user":"deid.ext33"}' \
  -v
```

Esto mostrará el error exacto del API Manager.

### 6.3 ALTERNATIVO: Verificar Usuario en Dominio Correcto

**Revisar:** ¿El código debería usar `admin@msperitos-ext.crt.gob.mx` para usuarios externos?

**Código actual:** No diferencia entre usuarios internos y externos al consultar LDAP.

**Posible mejora:** Detectar si el usuario tiene sufijo `.ext*` y usar credenciales/endpoints específicos para externos.

### 6.4 TEMPORAL: Workaround para Continuar Testing

Si el LDAP no es crítico para la funcionalidad principal:
1. Modificar `AdminRolMB.obtenerDetalleUsuario()` para capturar la excepción
2. Devolver datos por defecto o mostrar mensaje informativo
3. Permitir que el usuario continúe sin información LDAP completa

---

## 7. PRÓXIMOS PASOS

### Paso 1: Desplegar nuevo WAR
```bash
# WAR generado con corrección SSL
fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war
```

### Paso 2: Revisar logs después del despliegue
Buscar en logs de Tomcat:
```
[MDSeguridadService.EjecutaMetodoPOST] error. StatusCode=403, Message=..., ErrorBody=...
```

El `ErrorBody` contendrá la respuesta del API Manager explicando el motivo del rechazo.

### Paso 3: Contactar equipo de API Manager
Con el `ErrorBody` del log, contactar al equipo que administra el API Manager para:
- Verificar configuración de scopes del cliente OAuth2
- Verificar políticas de acceso al recurso LDAP
- Verificar si hay diferencias entre entorno IFT y CRT

---

## 8. CONCLUSIÓN

**Problema identificado:** Error 403 al consultar servicio LDAP a través del API Manager

**Causa más probable:** Token OAuth2 sin scopes suficientes para acceder al recurso LDAP

**Causa descartada:** NO es problema SSL (ya corregido en compilación actual)

**Próxima acción:** Desplegar nuevo WAR y revisar `ErrorBody` completo en logs para diagnóstico preciso

---

**Fin del documento**
