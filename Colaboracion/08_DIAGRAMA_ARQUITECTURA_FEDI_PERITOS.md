# Diagrama de Arquitectura: FEDI ↔ PERITOS ↔ API Manager

**Objetivo:** Visualizar la cadena completa de llamadas para migración a CRT

---

## 🔗 Cadena de Llamadas Completa

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          NAVEGADOR DEL USUARIO                             │
│                                                                             │
│  URL: https://fedidev.ift.org.mx/FEDIPortalWeb-1.0/login                  │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SERVIDOR TOMCAT - FEDI (Windows)                        │
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │ LoginMB.java (Managed Bean)                                            │ │
│  │                                                                        │ │
│  │  @PostConstruct init() {                                             │ │
│  │    adminUsuariosService.obtenerUsuarios()  ← INICIA CADENA          │ │
│  │  }                                                                    │ │
│  └──────────────────┬─────────────────────────────────────────────────────┘ │
│                     │                                                      │
│                     ▼                                                      │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │ AdminUsuariosServiceImpl.java (Service)                               │ │
│  │                                                                        │ │
│  │  @Override                                                            │ │
│  │  public ResponseUsuarios obtenerUsuarios() {                         │ │
│  │                                                                        │ │
│  │    1. ObtenTokenDeAcceso()                                           │ │
│  │       ├─→ URL: http://apimanager-qa.ift.org.mx/token               │ │
│  │       ├─→ Auth: Basic {TokenID}                                     │ │
│  │       └─→ Retorna: access_token                                     │ │
│  │                                                                        │ │
│  │    2. EjecutaMetodoGET(                                              │ │
│  │        token,                                                         │ │
│  │        "https://apimanager-qa.ift.org.mx/srvAutoregistroQA/v3.0/", │ │
│  │        "registro/consultas/roles/2/1/0015MSPERITOSDES-INT",        │ │
│  │        parametros                                                     │ │
│  │       )                                                               │ │
│  │       ├─→ GET URL completa                                          │ │
│  │       ├─→ Auth: Bearer {access_token}                               │ │
│  │       └─→ Retorna: ResponseRoles (JSON)                             │ │
│  │                                                                        │ │
│  │    3. Para cada rol obtenido:                                       │ │
│  │       ├─→ EjecutaMetodoGET(                                         │ │
│  │       │   "registro/consultas/roles/4/{sistema}--{rol}/0022FEDI"   │ │
│  │       │  )                                                            │ │
│  │       └─→ Retorna usuarios de ese rol                               │ │
│  │                                                                        │ │
│  │    4. Retorna ResponseUsuarios con lista completa                  │ │
│  │  }                                                                    │ │
│  └──────────────────┬─────────────────────────────────────────────────────┘ │
│                     │                                                      │
└─────────────────────┼──────────────────────────────────────────────────────┘
                      │
                      │ HTTP REQUEST
                      ▼
        ┌──────────────────────────────────────┐
        │   API Manager IFT (WSO2)            │
        │                                      │
        │  Broker de APIs que:                │
        │  1. Autentica con OAuth2            │
        │  2. Enruta a servicios backend      │
        │  3. Registra tráfico (bitácora)     │
        │  4. Aplica políticas de seguridad   │
        └──────────────────────────────────────┘
                      │
                      │ HTTP REQUEST (autenticado)
                      ▼
        ┌──────────────────────────────────────┐
        │  srvAutoregistro (Desconocido)      │
        │                                      │
        │  Servicio NO ENCONTRADO EN REPO    │
        │                                      │
        │  Debe:                              │
        │  - Recibir GET /registro/...       │
        │  - Consultar BD PERITOS            │
        │  - Retornar JSON ResponseRoles    │
        └──────────────────────────────────────┘
                      │
                      │ SQL QUERY
                      ▼
        ┌──────────────────────────────────────┐
        │    Base de Datos PERITOS (Oracle)    │
        │                                      │
        │  Tablas:                            │
        │  ├─ tbl_usuarios                    │
        │  ├─ tbl_roles                       │
        │  └─ tbl_usuario_rol                 │
        │                                      │
        │  Query:                             │
        │  SELECT * FROM tbl_usuario_rol      │
        │  WHERE rol_id = ? AND estado = 'A' │
        └──────────────────────────────────────┘
```

---

## 🌍 Comparación: IFT vs CRT

### AMBIENTE IFT (FUNCIONANDO ✅)

```
FEDI Login
    ↓
AdminUsuariosServiceImpl
    ↓
    ├─→ HTTP POST: http://apimanager-qa.ift.org.mx/token
    │                ↓
    │           API Manager IFT
    │                ↓
    │           Valida Basic Auth
    │                ↓
    │           Retorna: Bearer Token ✅
    │
    ├─→ HTTP GET: https://apimanager-qa.ift.org.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT
    │             Authorization: Bearer {token}
    │                ↓
    │           API Manager IFT
    │                ↓
    │           Enruta a srvAutoregistro ✅
    │                ↓
    │           srvAutoregistro Consulta BD PERITOS ✅
    │                ↓
    │           Retorna JSON con roles ✅
    │
    └─→ ResponseRoles parsea JSON
        └─→ Muestra usuarios disponibles
            └─→ Usuario selecciona firmante ✅
```

**Estado:** ✅ TODO FUNCIONA EN IFT

---

### AMBIENTE CRT (ROTO ❌)

```
FEDI Login
    ↓
AdminUsuariosServiceImpl
    ↓
    ├─→ HTTP POST: http://apimanager-qa.crt.gob.mx/token
    │                ↓
    │           API Manager CRT
    │                ↓
    │           Valida Basic Auth
    │                ↓
    │           Retorna: Bearer Token ✅
    │
    ├─→ HTTP GET: https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT
    │             Authorization: Bearer {token}
    │                ↓
    │           API Manager CRT
    │                ↓
    │           Busca ruta: /srvAutoregistroQA/v3.0/... ❌ NO ENCONTRADA
    │                ↓
    │           HTTP 404: Not Found
    │                ↓
    │           FEDI captura error
    │                ↓
    │           No muestra usuarios
    │                ↓
    │           Usuario no puede seleccionar firmantes ❌
```

**Estado:** ❌ NO FUNCIONA EN CRT PORQUE:
- srvAutoregistro NO ESTÁ PUBLICADO en API Manager CRT
- O el servicio backend NO EXISTE en CRT

---

## 🔍 Detalles de Cada Llamada HTTP

### LLAMADA 1: Obtener Token OAuth2

```http
POST http://apimanager-qa.ift.org.mx/token HTTP/1.1
Authorization: Basic VGZxc3BCYWVYZHhCNlF0SUJHV0EzZUxpMkw0YTpWTUdUVHhqUDVkMl91eFoxdW5uSVBSTGpmZ01h
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials

─────────────────────────────────────────────────────

RESPONSE (HTTP 200):

{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": "3600"
}
```

**Código Java:**
```java
// fedi-web/.../MDSeguridadServiceImpl.java línea 95-150
this.tokenAcceso = this.mDSeguridadService.ObtenTokenDeAcceso(
    mdsgdTokenUrl,      // http://apimanager-qa.ift.org.mx/token
    mdsgdTokenId        // Basic {encoded_credentials}
);
```

---

### LLAMADA 2: Obtener Roles de PERITOS

```http
GET https://apimanager-qa.ift.org.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

─────────────────────────────────────────────────────

RESPONSE (HTTP 200):

{
  "error": "false",
  "code": 0,
  "datosRoles": [
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/ROL_0015MSPERITOS_SOLICITANTES",
      "estado": "A"
    },
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/ROL_0015MSPERITOS_SUPERVISORES",
      "estado": "A"
    },
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/ROL_0015MSPERITOS_REVISORES",
      "estado": "A"
    }
  ]
}
```

**Código Java:**
```java
// fedi-web/.../AdminUsuariosServiceImpl.java línea 115-120
vMetodo = "registro/consultas/roles/2/1/0015MSPERITOSDES-INT";
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarios() - Consultando roles de PERITOS: " 
    + this.autoRegistroUrl + vMetodo);
vCadenaResultado = this.mDSeguridadService.EjecutaMetodoGET(
    this.tokenAcceso.getAccess_token(),
    this.autoRegistroUrl,  // https://apimanager-qa.ift.org.mx/srvAutoregistroQA/v3.0/
    vMetodo,
    lstParametros
);
```

---

### LLAMADA 3: Obtener Usuarios de un Rol

```http
GET https://apimanager-qa.ift.org.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/4/0015MSPERITOSDES-INT--ROL_0015MSPERITOS_SOLICITANTES/0022FEDI HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

─────────────────────────────────────────────────────

RESPONSE (HTTP 200):

{
  "error": "false",
  "code": 0,
  "datosRoles": [
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/juan.perez",
      "estado": "A"
    },
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/maria.garcia",
      "estado": "A"
    },
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/carlos.lopez",
      "estado": "A"
    }
  ]
}
```

**Código Java:**
```java
// fedi-web/.../AdminUsuariosServiceImpl.java línea 142-147
vMetodo = "registro/consultas/roles/4/" + nombreSistema + "--" + nombreRol + "/" 
          + this.sistemaIdentificadorInt;
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarios() - Consultando usuarios del rol: " 
    + nombreRol + " para sistema FEDI: " + this.sistemaIdentificadorInt);
vCadenaResultado = this.mDSeguridadService.EjecutaMetodoGET(
    this.tokenAcceso.getAccess_token(),
    this.autoRegistroUrl,
    vMetodo,
    lstParametros
);
```

---

### LLAMADA 4: Validar Usuari Específico

```http
GET https://apimanager-qa.ift.org.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/1/juan.perez/0015MSPERITOSDES-INT HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

─────────────────────────────────────────────────────

RESPONSE (HTTP 200):

{
  "error": "false",
  "code": 0,
  "datosRoles": [
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/juan.perez",
      "estado": "A"
    }
  ]
}

OU 

RESPONSE (HTTP 404):

{
  "error": "true",
  "code": 404,
  "datosRoles": null
}
```

**Código Java:**
```java
// fedi-web/.../AdminUsuariosServiceImpl.java línea 215-222
String vMetodo = "registro/consultas/roles/1/" + prmUsuario + "/0015MSPERITOSDES-INT";
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarioInterno() - Consultando usuario: " 
    + prmUsuario + " en sistema PERITOS");
vCadenaResultado = this.mDSeguridadService.EjecutaMetodoGET(
    this.tokenAcceso.getAccess_token(),
    this.autoRegistroUrl,
    vMetodo,
    lstParametros
);
```

---

## 📊 Matriz de Estado por Ambiente

| Componente | IFT | CRT | Observación |
|-----------|-----|-----|------------|
| **Token OAuth2** | ✅ | ✅ | Funciona en ambos |
| **API Manager** | ✅ | ✅ | Accesible en ambos |
| **srvAutoregistro Service** | ✅ | ❌ | **BLOQUEADOR** |
| **BD PERITOS** | ✅ | ❓ | Requiere validación |
| **Usuarios PERITOS** | ✅ | ❓ | Requiere validación |
| **Tabla tbl_usuario_rol** | ✅ | ❓ | Requiere validación |

---

## 🔧 Test Manual en CRT

### Test 1: ¿Responde API Manager CRT?

```bash
curl -X POST http://apimanager-qa.crt.gob.mx:8280/token \
  -H "Authorization: Basic V3FsMVBMdmpvZTh6U0RfNHFTRWIyNEhTOWZBYTpFeExrVEFsOEY0eEkxZ1BjaHh5Rk5TblFYQlFh" \
  -d "grant_type=client_credentials"

# Esperado: HTTP 200 + access_token
# Si falla: Problema de autenticación o API Manager no disponible
```

---

### Test 2: ¿Está publicado srvAutoregistro en CRT?

```bash
curl -X GET "https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT" \
  -H "Authorization: Bearer {access_token_aqui}"

# Esperado: HTTP 200 + JSON con roles
# Si 404: srvAutoregistro no publicado en API Manager CRT
# Si 401: Token inválido
# Si 502: Backend no disponible
```

---

### Test 3: ¿Responde Backend srvAutoregistro?

```bash
# Desde servidor con acceso interno
curl -X GET "http://srvAutoregistro.interno.crt.gob.mx:8080/srvAutoregistro/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT" \
  -H "Authorization: Bearer {access_token}"

# Esperado: HTTP 200 + JSON
# Si 404: Servicio no deployado
# Si 500: Servicio con error
# Si timeout: Servicio no respondiendo
```

---

## 📋 Checklist: Paso a Paso para CRT

### Pre-Migración
- [ ] Obtener código fuente de srvAutoregistro
- [ ] Obtener credenciales de API Manager CRT
- [ ] Obtener acceso a BD PERITOS en CRT
- [ ] Confirmar usuarios migrados en PERITOS

### Migración
- [ ] Compilar srvAutoregistro para CRT
- [ ] Configurar datasource BD PERITOS en CRT
- [ ] Cambiar URLs en pom.xml (apimanager-qa.crt.gob.mx)
- [ ] Desplegar FEDI-web con nuevas URLs

### Publicación en API Manager
- [ ] Crear API en API Manager CRT: /srvAutoregistroQA/v3.0/
- [ ] Publicar srvAutoregistro backend
- [ ] Configurar OAuth2
- [ ] Configurar policies de seguridad
- [ ] Probar endpoints antes y después

### Validación
- [ ] Prueba de token en CRT ✅
- [ ] Prueba GET /registro/consultas/roles/2/1/... ✅
- [ ] Prueba GET /registro/consultas/roles/4/... ✅
- [ ] Prueba GET /registro/consultas/roles/1/... ✅
- [ ] Prueba POST /registro/actualizar ✅
- [ ] Test de carga con múltiples usuarios ✅

---

**Versión:** 1.0
**Fecha:** 2026-02-05
**Estado:** Documentación Completa
**Próximo:** Localizar y obtener srvAutoregistro
