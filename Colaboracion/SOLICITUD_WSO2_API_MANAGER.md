# SOLICITUD: Suscripciones API Manager para FEDI Portal Web

**Fecha:** 16/Febrero/2026
**Solicitante:** Equipo de Desarrollo FEDI - CRT
**Prioridad:** ALTA - Blocker para funcionalidad principal
**Contexto:** Migración IFT → CRT (Instituto extinto, documentación limitada)

---

## 📋 RESUMEN EJECUTIVO

En el proceso de migración del dominio IFT a CRT, la aplicación **FEDI Portal Web** requiere suscripciones a APIs en el API Manager de WSO2 para funcionar correctamente en los tres ambientes (Desarrollo, QA, Producción).

Actualmente, la aplicación **puede autenticarse correctamente** pero **no puede acceder a recursos protegidos** debido a falta de suscripciones API, generando error **900908 "API Subscription validation failed"**.

---

## 🎯 OBJETIVO

Configurar todas las suscripciones necesarias para que el cliente OAuth2 de **FEDI Portal Web** pueda acceder a las APIs requeridas en los tres ambientes.

---

## 🔐 CLIENTES OAUTH2

### DESARROLLO (apimanager-dev.crt.gob.mx)
```
Aplicación: FEDI Portal Web - DEV
Client ID: TfqspBaeXdxB6QtIBGWA3eLi2L4a
Token (Base64): Basic VGZxc3BCYWVYZHhCNlF0SUJHV0EzZUxpMkw0YTpWTUdUVHhqUDVkMl91eFoxdW5uSVBSTGpmZ01h
Grant Type: client_credentials
```

### QA (apimanager-qa.crt.gob.mx)
```
Aplicación: FEDI Portal Web - QA
Client ID: Wql1PLvjoe8zSD_4qSEb24HS9fAa
Token (Base64): Basic V3FsMVBMdmpvZTh6U0RfNHFTRWIyNEhTOWZBYTpFeExrVEFsOEY0eEkxZ1BjaHh5Rk5TblFYQlFh
Grant Type: client_credentials
```

### PRODUCCIÓN (apimanager.crt.gob.mx)
```
Aplicación: FEDI Portal Web - PROD
Client ID: MJ9fuGNxCykvoDNJQ8WnjNh5kKYa
Token (Base64): Basic TUo5ZnVHTnhDeWt2b0ROSlE4V25qTmg1a0tZYTpLWndCUXFHNHNibmRqVEI2RnpraEdnUzdNcnNh
Grant Type: client_credentials
```

---

## 📡 APIS REQUERIDAS

### 1. **LDAP - Directorio de Usuarios** ⚠️ **CRÍTICO - BLOCKER ACTUAL**

| Ambiente | URL Base | Versión |
|----------|----------|---------|
| **DEV** | `https://apimanager-dev.crt.gob.mx/ldp.inf.ift.org.mx` | `v1.0` |
| **QA** | `https://apimanager-qa.crt.gob.mx/ldp.inf.ift.org.mx` | `v3.0` |
| **PROD** | `https://apimanager.crt.gob.mx/ldp.inf.ift.org.mx` | `v2.0` |

**Endpoints críticos:**
- `POST /OBTENER_INFO` - Obtener información detallada de usuario

**Error actual (DEV):**
```json
{
  "code": "900908",
  "message": "Resource forbidden",
  "description": "User is NOT authorized to access the Resource. API Subscription validation failed."
}
```

**Impacto:**
- ❌ No se puede obtener información del usuario (nombre, email, puesto)
- ❌ Funcionalidad de carga de documentos afectada
- ✅ Login funciona (usa endpoint diferente)

**Justificación:**
La aplicación necesita consultar información detallada de usuarios desde el directorio LDAP para:
- Mostrar datos del usuario en la interfaz
- Validar permisos de acceso a documentos
- Auditoría de acciones (nombre completo en logs)
- Notificaciones por email

---

### 2. **Autenticación/Login**

| Ambiente | URL Base | Versión |
|----------|----------|---------|
| **DEV** | `https://apimanager-dev.crt.gob.mx/autorizacion/login` | `v1.0` |
| **QA** | `https://apimanager-qa.crt.gob.mx/autorizacion/login` | `v3.0` |
| **PROD** | `https://apimanager.crt.gob.mx/autorizacion/login` | sin versión |

**Endpoints:**
- `GET /credencial/{sistema}/{usuario}/{password}` - Autenticación de usuario

**Estado:** ✅ **FUNCIONA** (suscripción existente)

---

### 3. **Bitácora de Eventos**

| Ambiente | URL Base | Versión |
|----------|----------|---------|
| **DEV** | `https://apimanager-dev.crt.gob.mx/bit.reg.ift.org.mx` | sin versión |
| **QA** | `https://apimanager-qa.crt.gob.mx/bit.reg.ift.org.mx` | sin versión |
| **PROD** | `https://apimanager.crt.gob.mx/bit.reg.ift.org.mx` | sin versión |

**Endpoints:**
- `POST /registroBitacora/` - Registro de eventos de auditoría

**Justificación:**
Cumplimiento normativo - auditoría de accesos y operaciones

---

### 4. **FEDI API - Backend (fedi-srv)**

**Nota:** Esta API **NO pasa por API Manager** en DEV, se consume directamente.

| Ambiente | URL Base | Observaciones |
|----------|----------|---------------|
| **DEV** | `https://fedidev.crt.gob.mx/srvFEDIApi-1.0/` | Directo (sin API Manager) |
| **QA** | `https://apimanager-qa.crt.gob.mx/FEDI` | v3.0 (vía API Manager) |
| **PROD** | `https://apimanager.crt.gob.mx/FEDI` | v2.0 (vía API Manager) |

**Endpoints principales:**
- `GET /catalogos/consultarUsuarios` - Catálogo de usuarios FEDI
- `POST /registrarUsuario` - Registro de nuevos usuarios
- `POST /documento/firmar` - Firma electrónica de documentos

**Estado DEV:** ✅ **FUNCIONA** (sin API Manager, SSL configurado)
**Estado QA/PROD:** Requiere suscripción cuando se despliegue

---

### 5. **Notificaciones por Email**

| Ambiente | URL Base | Versión |
|----------|----------|---------|
| **DEV** | `https://apimanager-dev.crt.gob.mx/REGISTRO/CORREOS/FEDI` | `v1.0` |
| **QA** | `https://apimanager-qa.crt.gob.mx/REGISTRO/CORREOS/FEDI` | `v3.0` |
| **PROD** | `https://apimanager.crt.gob.mx/REGISTRO/CORREOS/FEDI` | `v2.0` |

**Endpoints:**
- `POST /firmaUsuarios/` - Envío de notificaciones de firma

**Justificación:**
Notificar a usuarios sobre documentos pendientes de firma

---

## 🔧 RESPUESTA A PREGUNTA 1: ¿Podemos usar fedi-srv directamente?

### Análisis realizado:

**SÍ, parcialmente.** El backend `fedi-srv` tiene algunas capacidades LDAP pero **NO reemplaza completamente** el servicio LDAP del API Manager.

**Lo que fedi-srv SÍ tiene:**
- ✅ `/validarUsuario` - Validación de credenciales (usuario + contraseña)
- ✅ Conexión propia a LDAP: `http://172.17.42.47:9001/mx.org.ift.srv.rst.ldap/LDP/`

**Lo que fedi-srv NO tiene:**
- ❌ Endpoint para obtener información detallada del usuario (nombre, email, puesto)
- ❌ Endpoint equivalente a `/OBTENER_INFO` del API Manager

**Conclusión:**
No es posible eliminar completamente la dependencia del servicio LDAP del API Manager. El endpoint `/validarUsuario` de fedi-srv solo sirve para autenticación básica, pero **fedi-web necesita información adicional** del usuario que solo proporciona el servicio LDAP completo.

**Opción alternativa (NO recomendada):**
Podríamos modificar fedi-srv para agregar un endpoint que consulte información del usuario, pero esto:
- Duplicaría funcionalidad existente
- Requeriría desarrollo adicional
- No resuelve el problema de fondo (falta de suscripciones)
- Solo movería el problema de fedi-web a fedi-srv

**Recomendación:**
Proceder con la solicitud de suscripciones al API Manager, que es la solución correcta y arquitectónicamente apropiada.

---

## 📊 TABLA RESUMEN DE SUSCRIPCIONES REQUERIDAS

| API | DEV | QA | PROD | Prioridad | Estado |
|-----|-----|----|----|-----------|--------|
| **LDAP** | ✅ Requerida | ✅ Requerida | ✅ Requerida | **CRÍTICA** | ❌ Falta |
| **Login** | ✅ Existe | ✅ Requerida | ✅ Requerida | Alta | ⚠️ Solo DEV |
| **Bitácora** | ✅ Requerida | ✅ Requerida | ✅ Requerida | Media | ❓ No verificado |
| **FEDI API** | N/A (directo) | ✅ Requerida | ✅ Requerida | Alta | ❓ Cuando se despliegue |
| **Notificaciones** | ✅ Requerida | ✅ Requerida | ✅ Requerida | Media | ❓ No verificado |

---

## 🚨 SITUACIÓN ACTUAL (DESARROLLO)

### ✅ Lo que FUNCIONA:
1. Login de usuarios con credenciales CRT
2. Obtención de token OAuth2
3. Consulta de catálogo de usuarios (fedi-srv directo)
4. Consulta de documentos en base de datos
5. Llamadas HTTPS con certificados autofirmados (configurado en código)

### ❌ Lo que NO FUNCIONA:
1. **Obtención de información detallada del usuario desde LDAP** → Error 403
2. Sección de carga de documentos (depende de info LDAP)
3. Visualización de datos del usuario en interfaz

### 📝 Evidencia del error:

**Log de producción (16/Feb/2026 20:22:03):**
```
[ERROR] [MDSeguridadService.EjecutaMetodoPOST] error.
StatusCode=403, Message=,
ErrorBody={"code":"900908",
           "message":"Resource forbidden",
           "description":"User is NOT authorized to access the Resource. API Subscription validation failed."},
Duracion=234ms
```

**Request:**
```
POST https://apimanager-dev.crt.gob.mx/ldp.inf.ift.org.mx/v1.0/OBTENER_INFO
Authorization: Bearer [token_valido]
Content-Type: application/json
Body: {"user":"deid.ext33"}
```

**Response:** HTTP 403 Forbidden

---

## 📅 CONTEXTO DE MIGRACIÓN IFT → CRT

### Situación especial:
- El **Instituto Federal de Telecomunicaciones (IFT) se extinguió**
- La **Comisión Reguladora de Telecomunicaciones (CRT)** asumió funciones
- Proceso de migración de **todos los sistemas** del dominio IFT al CRT
- **Documentación técnica limitada o inexistente** en muchos proyectos
- Equipo de desarrollo debe **reconstruir configuraciones** basándose en análisis de código

### Desafío actual:
No tenemos acceso a:
- ❌ Documentación de configuración del API Manager IFT
- ❌ Listado de suscripciones que tenía FEDI en IFT
- ❌ Manuales de operación del API Manager original
- ❌ Memorias técnicas del proyecto

### Por qué este documento es importante:
Este es un **esfuerzo de recuperación de conocimiento** basado en:
- ✅ Análisis de código fuente (pom.xml, application.properties)
- ✅ Logs de aplicación en ejecución
- ✅ Pruebas funcionales identificando qué funciona y qué no
- ✅ Ingeniería reversa de URLs y endpoints

---

## 🎯 SOLICITUD ESPECÍFICA

### Para el equipo de WSO2/API Manager:

**Acción requerida:**
Configurar suscripciones a las APIs listadas en este documento para los tres clientes OAuth2 de FEDI Portal Web (DEV, QA, PROD).

**Prioridad inmediata:**
1. **API LDAP en DESARROLLO** (blocker actual)
2. Verificar/configurar API Login en QA y PROD
3. Configurar resto de APIs para completar migración

**Información adicional disponible:**
- Código fuente completo de fedi-web y fedi-srv
- Logs detallados de errores
- Pruebas funcionales documentadas
- Equipo de desarrollo disponible para aclaraciones

---

## 🤝 CONTACTO

**Equipo de desarrollo FEDI - CRT**
Disponible para:
- Aclaraciones técnicas
- Pruebas de conectividad
- Validación de configuraciones
- Documentación adicional si se requiere

---

## 📎 ANEXOS

### A. Logs de error completos
Ver archivo: `Colaboracion/fedi4.txt` (líneas 115-127)

### B. Configuración de URLs por ambiente
Ver archivo: `fedi-web/fedi-web/pom.xml` (líneas 815-949)

### C. Análisis de dependencias
Ver documentos:
- `Colaboracion/01_Resumen_Migracion_FEDI.md`
- `Colaboracion/03_Dependencias_Eliminadas.md`
- `Colaboracion/06_Diagnostico_Error_403_LDAP.md`

### D. Código de implementación SSL
Ver archivo: `fedi-web/fedi-web/src/main/java/.../MDSeguridadServiceImpl.java`

---

## ✅ CHECKLIST DE VALIDACIÓN

Una vez configuradas las suscripciones, validaremos:

- [ ] Login funciona en DEV, QA, PROD
- [ ] Consulta LDAP devuelve 200 OK (no 403)
- [ ] Información de usuario se muestra correctamente
- [ ] Carga de documentos funciona sin errores
- [ ] Bitácora registra eventos correctamente
- [ ] Notificaciones se envían correctamente

---

**Fin del documento**

---

## 📌 NOTAS ADICIONALES

### Sobre fedi-srv como alternativa:
El análisis técnico demuestra que **NO es viable** usar fedi-srv para reemplazar el servicio LDAP del API Manager porque:
1. fedi-srv solo tiene `/validarUsuario` (autenticación básica)
2. No tiene endpoint para obtener información detallada del usuario
3. Requeriría desarrollo adicional (tiempo + riesgo)
4. Solo movería el problema de lugar (fedi-srv también necesitaría suscripción LDAP)

### Arquitectura correcta:
```
fedi-web → API Manager (WSO2) → Servicios backend
          ↓ (OAuth2)
          - LDAP (info usuarios)
          - Login (autenticación)
          - Bitácora (auditoría)
          - Notificaciones
```

### Por qué no bypasear el API Manager:
El API Manager proporciona:
- 🔐 Seguridad (OAuth2, rate limiting)
- 📊 Monitoreo y analytics
- 🔄 Versionado de APIs
- 🛡️ Protección contra abuso
- 📝 Auditoría centralizada

Bypasearlo sería **contra-productivo** y **degradaría la seguridad** del sistema.
