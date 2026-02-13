# 🔀 ARQUITECTURA HÍBRIDA: API Manager + URL Directa

## Concepto

**Rutas inteligentes por endpoint:**
- ✅ Endpoints que **funcionan bien** → API Manager (sin cambios)
- ⚡ Endpoints **problemáticos** (timeout/lento) → URL directa a fedi-srv

Esta estrategia **minimiza riesgo** y maximiza **performance sin breaking changes**.

---

## 🏗️ Arquitectura Actual

```
ANTES (Problema):
fedi-web → API Manager (timeout 120s) → fedi-srv ❌

AHORA (Solución):
fedi-web ─┬─→ API Manager (consultas que funcionan bien) → fedi-srv ✅
          │
          └─→ URL Directa (consultarUsuarios problema) → fedi-srv ✅
```

---

## ⚙️ Implementación Técnica

### 1. Configuración en pom.xml

Se agregó **propiedad de URL directa** en todos los profiles:

```xml
<!-- Profile DEV (línea ~810) -->
<profile.fedi.url>https://apimanager-dev.ift.org.mx/FEDI/v1.0/</profile.fedi.url>
<!-- URL DIRECTA para endpoints problemáticos -->
<profile.fedi.direct.url>http://localhost:8080/srvFEDIApi/</profile.fedi.direct.url>

<!-- Profile QA (línea ~869) -->
<profile.fedi.url>https://apimanager-qa.crt.gob.mx/FEDI/v3.0/</profile.fedi.url>
<profile.fedi.direct.url>http://localhost:8080/srvFEDIApi/</profile.fedi.direct.url>

<!-- Profile PRODUCTION (línea ~918) -->
<profile.fedi.url>https://apimanager.crt.gob.mx/FEDI/v2.0/</profile.fedi.url>
<profile.fedi.direct.url>http://localhost:8080/srvFEDIApi/</profile.fedi.direct.url>
```

### 2. Lógica de Routing en FEDIServiceImpl

```java
/**
 * Método para decidir qué URL usar (API Manager o directo)
 * Endpoints problemáticos (lentos/timeout) usan URL directa
 */
private String obtenerUrlBase(String metodo) {
    // Endpoints con TIMEOUT/LENTO → URL DIRECTA
    if ("catalogos/consultarUsuarios".equals(metodo) && this.fediDirectUrl != null) {
        LOGGER.info("*** [DIAG-WEB] Usando URL DIRECTA (sin API Manager) para endpoint: " + metodo);
        return this.fediDirectUrl;
    }
    
    // Endpoints que funcionan bien → API MANAGER
    LOGGER.info("*** [DIAG-WEB] Usando API Manager para endpoint: " + metodo);
    return this.fediUrl;
}
```

### 3. Uso en obtenerCatUsuarios()

```java
String vMetodo = "catalogos/consultarUsuarios";
String urlBase = obtenerUrlBase(vMetodo);  // Elige URL automáticamente
String urlCompleta = urlBase + vMetodo;
respuestaServicioCat = mDSeguridadService.EjecutaMetodoGET(
    this.tokenAcceso.getAccess_token(),
    urlCompleta,  // Usa la URL inteligente
    "", 
    lstParametros
);
```

---

## 📊 Comparativa de Comportamiento

| Endpoint | Antes | Ahora | Ruta |
|----------|-------|-------|------|
| `obtenerTipoFirma` | ✅ Funciona (rápido) | ✅ Funciona | API Manager |
| `consultarUsuarios` | ❌ Timeout 120s | ⚡ ~2-5 segundos | URL Directa |
| `registrarUsuario` | ✅ Funciona | ✅ Funciona | API Manager |
| `cargarDocumento` | ✅ Funciona | ✅ Funciona | API Manager |

---

## 🔧 Configuración de URLs

### Para DEV (localhost)

Si **fedi-web y fedi-srv están en mismo servidor**:

```xml
<profile.fedi.direct.url>http://localhost:8080/srvFEDIApi/</profile.fedi.direct.url>
```

### Para QA/PRODUCTION (remoto)

Si **fedi-srv está en otro servidor**, edita la URL:

```xml
<!-- Opción 1: Por IP -->
<profile.fedi.direct.url>http://192.168.1.100:8080/srvFEDIApi/</profile.fedi.direct.url>

<!-- Opción 2: Por hostname -->
<profile.fedi.direct.url>http://srv-fedi-backend.dominio.mx:8080/srvFEDIApi/</profile.fedi.direct.url>

<!-- Opción 3: Con HTTPS -->
<profile.fedi.direct.url>https://srv-fedi-backend.dominio.mx:8443/srvFEDIApi/</profile.fedi.direct.url>
```

---

## 📝 Agregar Más Endpoints a URL Directa

Si otros endpoints también tienen timeout, **es trivial agregarlos**:

### Paso 1: Identificar el endpoint problemático

Por ejemplo, si `fedi/cargarDocumentos` también tiene timeout:

### Paso 2: Editr el método `obtenerUrlBase()` en FEDIServiceImpl

```java
private String obtenerUrlBase(String metodo) {
    // Endpoints con TIMEOUT/LENTO → URL DIRECTA
    if ("catalogos/consultarUsuarios".equals(metodo) && this.fediDirectUrl != null) {
        LOGGER.info("*** [DIAG-WEB] Usando URL DIRECTA para: " + metodo);
        return this.fediDirectUrl;
    }
    
    // AGREGAR NUEVO ENDPOINT AQUÍ
    if ("fedi/cargarDocumentos".equals(metodo) && this.fediDirectUrl != null) {
        LOGGER.info("*** [DIAG-WEB] Usando URL DIRECTA para: " + metodo);
        return this.fediDirectUrl;
    }
    
    // Endpoints que funcionan bien → API MANAGER
    LOGGER.info("*** [DIAG-WEB] Usando API Manager para: " + metodo);
    return this.fediUrl;
}
```

### Paso 3: Actualizar el método que llama

```java
// En cargarDocumentos()
String vMetodo = "fedi/cargarDocumentos";
String urlBase = obtenerUrlBase(vMetodo);  // Automáticamente usa URL directa
String urlCompleta = urlBase + vMetodo;
```

### Paso 4: Compilar y desplegar

```powershell
cd C:\github\fedi-web
mvn clean install -P dev
# Desplegar nuevo WAR
```

---

## 🔍 Verificación en Logs

### Log esperado SIN problemas (API Manager)

```
[INFO] *** [DIAG-WEB] Llamando API: https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarTipoFirma
[INFO] *** [DIAG-WEB] Respuesta recibida. Duracion: 1234ms
```

### Log esperado CON URL Directa (consultarUsuarios)

```
[INFO] *** [DIAG-WEB] Usando URL DIRECTA (sin API Manager) para endpoint: catalogos/consultarUsuarios
[INFO] *** [DIAG-WEB] Llamando API: http://localhost:8080/srvFEDIApi/catalogos/consultarUsuarios
[INFO] *** [DIAG-WEB] Respuesta recibida. Duracion: 2345ms
```

---

## ✅ Ventajas de Arquitectura Híbrida

| Ventaja | Descripción |
|---------|------------|
| **Bajo Riesgo** | Solo cambia lo que falla, resto sin cambios |
| **Gradual** | Agregar endpoints directos conforme se detecten problemas |
| **Monitoreable** | Logs claros dicen qué ruta se usa |
| **Reversible** | Si hay problema con URL directa, simplemente NO se usa |
| **Performance** | Endpoints problemáticos mejoran radicalmente |
| **Continuidad** | Endpoints que funcionan siguen funcionando |

---

## 🚀 Pasos de Implementación

### PASO 1: Ya hecho ✅
- Agregadas propiedades `fedi.direct.url` en todos los profiles del pom.xml
- Implementado método `obtenerUrlBase()` en FEDIServiceImpl
- Actualizado `obtenerCatUsuarios()` para usar routing inteligente

### PASO 2: Configurar URL correcta en pom.xml

**IMPORTANTE:** Editar la URL según tu ambiente:

```xml
<!-- Para DEV (si está en localhost) -->
<profile.fedi.direct.url>http://localhost:8080/srvFEDIApi/</profile.fedi.direct.url>

<!-- Para QA/PROD (editar con IP/hostname correcto) -->
<profile.fedi.direct.url>http://[IP-O-HOSTNAME-FEDI-SRV]:8080/srvFEDIApi/</profile.fedi.direct.url>
```

### PASO 3: Compilar

```powershell
cd C:\github\fedi-web
mvn clean install -P dev
# Esperado: BUILD SUCCESS
```

### PASO 4: Desplegar

```powershell
# Detener Tomcat
Stop-Service Tomcat9 -Force

# Limpiar cache
Remove-Item "C:\tomcat\webapps\FEDIPortalWeb-1.0" -Recurse -Force
Remove-Item "C:\tomcat\work\Catalina\localhost\*" -Recurse -Force

# Copiar WAR
Copy-Item "C:\github\fedi-web\target\FEDIPortalWeb-1.0.war" -Destination "C:\tomcat\webapps\"

# Iniciar
Start-Service Tomcat9
Start-Sleep -Seconds 45

# Verificar
Get-Content "C:\tomcat\logs\catalina.out" -Tail 50 | Select-String "FEDIPortalWeb|ERROR|started"
```

### PASO 5: Probar

```powershell
# Ir a aplicación y intentar guardar documento
# Esperado: Se completa rápidamente (2-5 segundos en lugar de 120s)

# Verificar logs en tiempo real
Get-Content "C:\tomcat\logs\catalina.out" -Wait -Tail 50 | Select-String "[DIAG-WEB]"
```

---

## 📋 Checklist

- [ ] ¿Editaste las URLs directas en todos los profiles de pom.xml?
- [ ] ¿Compiló sin errores? (`BUILD SUCCESS`)
- [ ] ¿Desplegaste el nuevo WAR?
- [ ] ¿Puedes acceder a la aplicación?
- [ ] ¿Intentaste guardar un documento?
- [ ] ¿Ver en logs que usa URL DIRECTA para `consultarUsuarios`?
- [ ] ¿Ver en logs que usa API Manager para otros endpoints?
- [ ] ¿Tiempo total ahora < 10 segundos (antes era > 120s)?

---

## 🎯 Próximas Optimizaciones

Una vez que esto funcione, puedes:

1. **Medir performance real** comparando tiempos en logs
2. **Agregar más endpoints a URL directa** si encuentras otros con timeout
3. **Implementar fallback** (si URL directa falla, intentar API Manager)
4. **Benchmarking completo** con SQL DIRECTO (FEDI_DIRECT.xml) activado

---

## 💡 Notas

- Si `fedi.direct.url` no está en properties, el código usa `fedi.url` (API Manager)
- El cambio es **100% transparente** - código elige automáticamente
- Puedes tener ambas URLs activas simultáneamente para testing

