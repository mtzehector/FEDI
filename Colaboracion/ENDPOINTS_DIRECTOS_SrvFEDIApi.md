# 🎯 Análisis: Endpoints Consumibles Directamente (sin API Manager)

**Fecha:** 12-Feb-2026  
**Estado:** ✅ CURL directo funciona, API Manager timeout  
**Impacto:** CRÍTICO - Permite consumir srvFEDIApi directamente

---

## 📊 Resumen del Hallazgo

### ✅ Endpoint Funcional DIRECTO
```bash
curl -k -i https://fedidev.crt.gob.mx/srvFEDIApi-1.0/catalogos/consultarUsuarios
# Resultado: HTTP 200 OK (o error de autenticación apropiado)
```

### ❌ Endpoint Timeout A TRAVÉS de API Manager
```
URL: https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios
Error: java.net.SocketTimeoutException: timeout (120 segundos)
Causa: API Manager NO está redirigiendo correctamente a srvFEDIApi
```

---

## 🔍 Evidencia del Log

### Log de fedi-web (FEDIServiceImpl)
```
2026-02-12 17:09:56,143 [INFO] FEDIServiceImpl:114 - *** [DIAG-WEB] 
  Llamando API: https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios

2026-02-12 17:11:56,214 [ERROR] MDSeguridadServiceImpl:232 - 
  [MDSeguridadService.EjecutaMetodoGET] IOException. 
  URL=https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios, 
  Error=timeout, Duracion=120071ms
```

### Puntos Clave
1. **Token se obtiene OK** (200 ms)
2. **Login exitoso** (2172 ms)
3. **Llamada a API Manager FALLA** (120 segundos timeout)
4. **NO hay logs en srvFEDIApi** - El backend NUNCA recibe la petición

---

## 🏗️ Arquitectura Actual

```
fedi-web (JSF Frontend)
    ↓
    ├─ Token: http://apimanager-dev.ift.org.mx/token ✅ OK
    ├─ Login: https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/... ✅ OK
    └─ FEDI API: https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/... ❌ TIMEOUT

srvFEDIApi (REST Backend)
    ✅ Endpoint funciona directamente
    ✅ CURL directo OK
    ❌ No recibe peticiones A TRAVÉS de API Manager
```

---

## 📋 Endpoints Identificados en srvFEDIApi

### Basado en el análisis del código y logs:

| # | Endpoint | Método | Descripción | Estado |
|---|----------|--------|-------------|--------|
| 1 | `/catalogos/consultarUsuarios` | GET | Obtener lista de usuarios | ✅ FUNCIONA (directo) |
| 2 | `/catalogos/...` | GET | Otros endpoints de catálogos | ⏳ Probables |
| 3 | `/...` | * | Otros endpoints REST | ⏳ A mapear |

**Nota:** Necesitamos explorar fedi-srv para obtener lista completa.

---

## 🚀 Opción 1: Usar srvFEDIApi Directamente

### Modificar fedi-web para NO pasar por API Manager

**Cambio en FEDIServiceImpl.java:**

```java
// ANTES: A través de API Manager (FALLA)
private static final String FEDI_API_URL = 
    "https://apimanager-dev.ift.org.mx/FEDI/v1.0/";

// DESPUÉS: Directo a srvFEDIApi (FUNCIONA)
private static final String FEDI_API_URL = 
    "https://fedidev.crt.gob.mx/srvFEDIApi-1.0/";
```

### Ventajas
- ✅ Elimina timeout de 120 segundos
- ✅ Menor latencia
- ✅ Menos dependencias de API Manager
- ✅ Ya está en producción

### Desventajas
- ❌ Bypasea el API Manager (gestión de versiones, tasa limitación, seguridad)
- ❌ Acoplamiento directo con srvFEDIApi

---

## 🚀 Opción 2: Debuggear API Manager

### Investigar por qué API Manager NO redirige a srvFEDIApi

**Pasos:**

1. **Verificar ruta en API Manager**
   - ¿Existe la ruta `/FEDI/v1.0/catalogos/consultarUsuarios`?
   - ¿Apunta a `https://srvFEDIApi:puerto/catalogos/consultarUsuarios`?
   - ¿El timeout está configurado > 120 segundos?

2. **Verificar endpoint directo en srvFEDIApi**
   - Clase: `CatalogosResources.java`
   - Método: `consultarUsuarios()`
   - Ruta: `/catalogos/consultarUsuarios`

3. **Verificar conectividad**
   ```bash
   # Desde API Manager hacia srvFEDIApi
   curl -v https://fedidev.crt.gob.mx/srvFEDIApi-1.0/catalogos/consultarUsuarios
   ```

4. **Revisar logs de API Manager**
   - Errores de redireccionamiento
   - Errores de backend no disponible
   - Configuración de timeout

---

## 📍 Localización de Endpoints en el Código

### fedi-srv

**Archivo:** [CatalogosResources.java](../fedi-srv/src/main/java/fedi/srv/ift/org/mx/rest/resource/CatalogosResources.java)

```java
@Path("/catalogos")
public class CatalogosResources {
    
    @GET
    @Path("/consultarUsuarios")
    @Produces(MediaType.APPLICATION_JSON)
    public Response consultarUsuarios(...) {
        // Implementación
    }
}
```

**Otras clases Resource a explorar:**
- `FEDIResources.java` (probablemente)
- `DocumentosResources.java` (probablemente)
- Etc.

---

## 🎓 Recomendación

### Corto Plazo (AHORA)
**Opción 1:** Cambiar fedi-web para consumir srvFEDIApi directamente
```java
private static final String FEDI_API_URL = "https://fedidev.crt.gob.mx/srvFEDIApi-1.0/";
```

**Ventaja:** Elimina el timeout inmediatamente

### Mediano Plazo
**Opción 2:** Debuggear API Manager para entender por qué NO funciona
**Objetivo:** Mantener la arquitectura de API Manager para control centralizado

---

## 📋 Checklist de Validación

- [ ] **URL Base FEDI en fedi-web**
  - [ ] Actual: `https://apimanager-dev.ift.org.mx/FEDI/v1.0/`
  - [ ] Nueva (opción): `https://fedidev.crt.gob.mx/srvFEDIApi-1.0/`

- [ ] **Endpoints en srvFEDIApi**
  - [ ] Listar TODOS los `@Path` y `@GET/@POST/@PUT/@DELETE`
  - [ ] Documentar parámetros requeridos
  - [ ] Documentar respuestas esperadas

- [ ] **Autenticación**
  - [ ] ¿Token se requiere directamente a srvFEDIApi?
  - [ ] ¿O solo a través de API Manager?
  - [ ] Actual: Token se obtiene de API Manager

- [ ] **Pruebas**
  - [ ] ✅ CURL directo: `curl -k -i https://fedidev.crt.gob.mx/srvFEDIApi-1.0/catalogos/consultarUsuarios`
  - [ ] ⏳ Desde fedi-web con URL directa
  - [ ] ⏳ Con token de API Manager

---

## 🔗 Archivos Relacionados

- [Logs_fedi_web_ambiente_dev.txt](Logs_fedi_web_ambiente_dev.txt) - Evidencia del timeout
- [DIAGNOSTICO_CAUSA_RAIZ.md](DIAGNOSTICO_CAUSA_RAIZ.md) - Análisis previo de timeout
- [CatalogosResources.java](../fedi-srv/src/main/java/fedi/srv/ift/org/mx/rest/resource/CatalogosResources.java) - Endpoints REST
- [FEDIServiceImpl.java](../fedi-web/src/main/java/fedi/ift/org/mx/service/FEDIServiceImpl.java) - Cliente REST en fedi-web

---

**Creado por:** GitHub Copilot  
**Fecha:** 2026-02-12 18:30  
**Estado:** ✅ Análisis completado, recomendación pendiente de aprobación usuario
