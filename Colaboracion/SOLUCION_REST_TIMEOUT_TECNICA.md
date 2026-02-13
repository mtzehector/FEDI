# Soluciones Técnicas - REST Timeout en FEDI

## 📌 Resumen Ejecutivo

El problema está identificado: El endpoint `https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios` tarda más de 10 segundos en responder, causando que el cliente OkHttpClient de FEDI exceda su timeout por defecto.

**Solución a implementar:** Aumentar el timeout del cliente HTTP de 10s a 30s (o más) mientras se investiga el backend.

---

## 🛠️ SOLUCIÓN 1: Aumentar Timeout en OkHttpClient (RECOMENDADO)

### Implementación en MDSeguridadServiceImpl.java

**Cambio:** Configurar OkHttpClient con timeouts explícitos en lugar de los defaults.

```java
// En MDSeguridadServiceImpl.java, método EjecutaMetodoGET()

@Override
public String EjecutaMetodoGET(String prmTokenAcceso, String prmUrl, String prmMetodo, List<ParametrosWS> prmLstParametros) throws Exception{
    String correlationId = UUID.randomUUID().toString();
    MDC.put("correlationId", correlationId);
    long startTime = System.currentTimeMillis();
    
    // ✨ NUEVO: Configurar OkHttpClient con timeouts aumentados
    OkHttpClient client = new OkHttpClient.Builder()
        .connectTimeout(30, java.util.concurrent.TimeUnit.SECONDS)  // Esperar 30s para conectar
        .readTimeout(60, java.util.concurrent.TimeUnit.SECONDS)     // Esperar 60s para recibir respuesta
        .writeTimeout(30, java.util.concurrent.TimeUnit.SECONDS)    // Esperar 30s para enviar
        .build();
    
    String vURLconMetodo=prmUrl.concat(prmMetodo);
    String vURLCompleto="";
    String vResultado = "FAIL";

    try {
        // ... resto del código sin cambios
        HttpUrl.Builder urlBuilder = HttpUrl.parse(vURLconMetodo).newBuilder();
        if (prmLstParametros != null){
            if (prmLstParametros.size()>0){
                for (Iterator iter = prmLstParametros.iterator(); iter.hasNext();) {
                    ParametrosWS elementParametro = (ParametrosWS) iter.next();
                    urlBuilder.addQueryParameter(elementParametro.getNombreDelParametro(),elementParametro.getValorDelParametro());
                }
            }
        }
        vURLCompleto = urlBuilder.build().toString();
        Request request = new Request.Builder()
                .header("Authorization", "Bearer " + prmTokenAcceso)
                .url(vURLCompleto)                
                .build();
        
        LOGGER.info("[MDSeguridadService.EjecutaMetodoGET] iniciando GET request. URL=" + vURLCompleto);
        Response response = client.newCall(request).execute();
        long duration = System.currentTimeMillis() - startTime;
        // ... resto sin cambios
    }
    // ... resto del método
}
```

### Agregar Import Necesario

```java
import java.util.concurrent.TimeUnit;
```

---

## 🔧 SOLUCIÓN 2: Configuración Externa via application.properties

Para hacer el timeout configurable sin recompilar:

### En application.properties:

```properties
# HTTP Client Configuration
http.client.connect.timeout=30000
http.client.read.timeout=60000
http.client.write.timeout=30000

# Descripción
# http.client.connect.timeout: Tiempo máximo para establecer conexión (ms)
# http.client.read.timeout: Tiempo máximo esperando respuesta del servidor (ms)
# http.client.write.timeout: Tiempo máximo para enviar datos al servidor (ms)
```

### Actualizar MDSeguridadServiceImpl.java para leer properties:

```java
@Service
public class MDSeguridadServiceImpl implements MDSeguridadService{
    // ... código existente
    
    @Autowired
    private Environment environment;
    
    @Override
    public String EjecutaMetodoGET(String prmTokenAcceso, String prmUrl, String prmMetodo, List<ParametrosWS> prmLstParametros) throws Exception{
        String correlationId = UUID.randomUUID().toString();
        MDC.put("correlationId", correlationId);
        long startTime = System.currentTimeMillis();
        
        // ✨ NUEVO: Leer timeouts desde configuration
        long connectTimeout = environment.getProperty("http.client.connect.timeout", Long.class, 30000L);
        long readTimeout = environment.getProperty("http.client.read.timeout", Long.class, 60000L);
        long writeTimeout = environment.getProperty("http.client.write.timeout", Long.class, 30000L);
        
        OkHttpClient client = new OkHttpClient.Builder()
            .connectTimeout(connectTimeout, java.util.concurrent.TimeUnit.MILLISECONDS)
            .readTimeout(readTimeout, java.util.concurrent.TimeUnit.MILLISECONDS)
            .writeTimeout(writeTimeout, java.util.concurrent.TimeUnit.MILLISECONDS)
            .build();
        
        // ... resto del método sin cambios
    }
}
```

---

## 📊 Valores Recomendados por Escenario

| Escenario | Connect | Read | Write | Justificación |
|-----------|---------|------|-------|---------------|
| **DEV (Actual)** | 30s | 60s | 30s | Servidor lento, dar más margen |
| **QA (Normal)** | 15s | 30s | 15s | Servidor más rápido |
| **PROD** | 10s | 20s | 10s | Servidor optimizado, baja latencia |

---

## 🧪 Testing de la Solución

### 1. Compilar y Buildear

```bash
cd C:\github\fedi-web
mvn clean install -P development-oracle1 -DskipTests
```

### 2. Desplegar a Tomcat

```bash
# Copiar WAR generado
Copy-Item -Path "C:\github\fedi-web\target\FEDIPortalWeb-1.0.war" `
          -Destination "C:\Tomcat\webapps\FEDIPortalWeb.war" -Force

# Reiniciar Tomcat
Stop-Service -Name "Tomcat"
Start-Service -Name "Tomcat"
```

### 3. Reproducir el Problema

```
1. Acceder a: https://fedi-dev.ift.org.mx
2. Login con credenciales válidas
3. Esperar caché inicial (catalogos/consultarUsuarios)
4. Intentar guardar un documento
5. Monitorear logs en tiempo real:
   tail -f C:\Tomcat\logs\catalina.out | Select-String "MDSeguridadService"
```

### 4. Validar Éxito

Esperar a que las llamadas completen sin timeout:
```
[correlationId] 20:51:50 - [MDSeguridadService.EjecutaMetodoGET] iniciando GET request. URL=...
[correlationId] 20:52:00 - [MDSeguridadService.EjecutaMetodoGET] exitoso. StatusCode=200, BodySize=X, Duracion=15000ms
```

✅ Si ves "exitoso" después de 30+ segundos, la solución funciona.

---

## 📈 Mejoras Futuras (Largo Plazo)

### 1. **Implementar Caché**
```java
@Cacheable(value="catalogo_usuarios", cacheManager="cacheManager")
public List<Usuario> consultarUsuarios() {
    return mdSecurityService.EjecutaMetodoGET(...);
}
```

### 2. **Implementar Circuit Breaker**
```xml
<!-- Agregar Hystrix a pom.xml -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-hystrix</artifactId>
    <version>1.4.7.RELEASE</version>
</dependency>
```

### 3. **Paginación en API**
```
Endpoint actual:
GET /FEDI/v1.0/catalogos/consultarUsuarios

Propuesta:
GET /FEDI/v1.0/catalogos/consultarUsuarios?page=1&size=100&cache=true
```

---

## ⚠️ Consideraciones Importantes

### Riesgos de Aumentar Timeout Demasiado

```
⚠️ Timeout 60s: 
   - VENTAJA: Tolera endpoints lentos
   - DESVENTAJA: El usuario espera mucho si hay problema real

✅ RECOMENDACIÓN: 
   - Corto plazo: 60s para dev
   - Mediano plazo: Investigar backend
   - Largo plazo: Reducir a 10-20s una vez optimizado
```

### Monitoreo

Agregar alerta si duración > 20 segundos:

```java
long duration = System.currentTimeMillis() - startTime;
if (duration > 20000) {
    LOGGER.warn("[MDSeguridadService.EjecutaMetodoGET] SLOW REQUEST WARNING. " +
                "URL=" + vURLCompleto + ", Duration=" + duration + "ms");
}
```

---

## ✅ Checklist de Implementación

- [ ] Agregar `import java.util.concurrent.TimeUnit;`
- [ ] Actualizar `EjecutaMetodoGET()` con OkHttpClient configurado
- [ ] Agregar propiedades en `application.properties`
- [ ] (Opcional) Hacer timeouts configurables via `Environment`
- [ ] Compilar con `mvn clean install -P development-oracle1 -DskipTests`
- [ ] Desplegar WAR a Tomcat
- [ ] Reiniciar Tomcat
- [ ] Probar con usuario real
- [ ] Revisar logs para validar duraciones
- [ ] Contactar a infra/API Manager sobre investigación del backend

---

## 📞 Información para Compartir con Infraestructura

```
TICKET: Investigación de Timeout en APIManager DEV
COMPONENT: FEDI Portal Web

PROBLEMA:
Endpoint: https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios
Status: Timeout después de 10+ segundos
Frecuencia: ~50% de los intentos
Impacto: Usuario no puede guardar documentos

EVIDENCIA:
1. Login al API Manager funciona bien (1.4s)
2. Otras consultas LDAP funcionan bien (125ms)
3. Solo "catalogos/consultarUsuarios" falla con timeout
4. Logs adjuntos: Logs_ambiente_dev.txt

SOLICITUD:
¿Pueden investigar:
1. Logs del backend para ese endpoint
2. Tiempo de respuesta de la consulta DB
3. ¿Hay queries sin índices?
4. ¿Estado de la base de datos?
5. ¿Hay rate limiting?
6. ¿Hay cambios recientes en DEV?
```

---

## 📎 Archivos Relacionados

- [MDSeguridadServiceImpl.java](c:\github\fedi-web\src\main\java\fedi\ift\org\mx\arq\core\service\security\loadsoa\MDSeguridadServiceImpl.java)
- [application.properties](c:\github\fedi-web\src\main\resources\application.properties)
- [Logs de Error](c:\github\Colaboracion\Logs_ambiente_dev.txt)
- [Análisis Inicial](c:\github\Colaboracion\ANALISIS_DIAGNOSTICO_REST_TIMEOUT.md)
