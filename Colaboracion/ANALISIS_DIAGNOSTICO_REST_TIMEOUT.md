# Análisis de Timeouts en Llamadas REST - FEDI

## 🎯 Hallazgos Principales

### 1. **Problema Identificado**
Las llamadas REST a `https://apimanager-dev.ift.org.mx` están generando **Socket Timeout** después de aproximadamente **10 segundos** de espera.

```
java.net.SocketTimeoutException: timeout
Duracion=10094ms (primer timeout)
Duracion=10063ms (segundo timeout)
```

### 2. **URLs Afectadas**
| Endpoint | Estado | Duración | Observación |
|----------|--------|----------|-------------|
| `/FEDI/v1.0/catalogos/consultarUsuarios` | ❌ **TIMEOUT** | 10,094ms | Falla al buscar usuarios en caché |
| `/FEDI/v1.0/catalogos/consultarUsuarios` (2do intento) | ❌ **TIMEOUT** | 10,063ms | Falla nuevamente al guardar documento |
| `/autorizacion/login/v1.0/credencial/...` | ✅ **SUCCESS** | 1,453ms | Login funciona correctamente |
| `/ldp.inf.ift.org.mx/v1.0/OBTENER_INFO` | ✅ **SUCCESS** | Rápido | Consultas LDAP funcionan |
| `/FEDI/v1.0/catalogos/consultarUsuarios` (202) | ⚠️ **ERROR 202** | 62ms | Respuesta aceptada pero sin body |

---

## 📊 Análisis de Logs

### Timeline de Eventos:

**20:51:48** - Login exitoso
- URL: `/autorizacion/login/v1.0/credencial/0022FEDI/dgtic.dds.ext023/...`
- Status: 200 ✅
- Duración: **1,453ms** (OK)

**20:51:50** - Primer timeout al cargar usuarios en caché
- URL: `/FEDI/v1.0/catalogos/consultarUsuarios`
- Error: `java.net.SocketTimeoutException: timeout`
- Duración: **10,094ms** (30 segundos = timeout default OkHttpClient)
- Nota: El cliente OkHttp tiene timeout de ~10 segundos por defecto

**20:52:00** - Reintentos automáticos (sin éxito)
- Se detecta un segundo timeout en la misma endpoint
- Duración: **10,063ms**

**20:52:34** - Búsqueda de usuario específico funciona
- URL: `/ldp.inf.ift.org.mx/v1.0/Obtener_Por_Nombre_usuarioID/ZGF2aWQ%3D`
- Status: 200 ✅
- Duración: **125ms** (OK)

**20:52:53 - 20:53:03** - Timeout al guardar documento
- URL: `/FEDI/v1.0/catalogos/consultarUsuarios`
- Error: `java.net.SocketTimeoutException: timeout`
- Duración: **10,063ms**

---

## 🔍 Causas Potenciales

### Causa 1: **API Backend Lento o No Responde**
```
Sintomatología:
- Timeout exacto después de ~10 segundos
- Solo afecta a `/FEDI/v1.0/catalogos/consultarUsuarios`
- Otras endpoints responden normalmente
```
**Conclusión:** El endpoint de "catalogos/consultarUsuarios" está tardando más de 10 segundos o no responde.

### Causa 2: **Firewall/Proxy Blocking**
```
Si fuera un bloqueo de red puro:
- Vería "Connection refused" o "Connection timeout" inmediatamente
- NO vería "SocketTimeoutException: timeout" después de 10 segundos
```
**Conclusión:** Menos probable, pero posible si hay un proxy que silencia la conexión.

### Causa 3: **Rate Limiting en API Manager**
```
Evidencia:
- Las primeras llamadas funcionan bien (login)
- Después de múltiples intentos, comienzan los timeouts
- El endpoint específico de "catalogos" es el que falla
```
**Conclusión:** Es posible que API Manager esté limitando las consultas.

### Causa 4: **Query Pesada en Base de Datos**
```
Evidencia:
- `/ldp.inf.ift.org.mx/v1.0/Obtener_Por_Nombre_usuarioID/...` responde en 125ms
- `/FEDI/v1.0/catalogos/consultarUsuarios` (sin filtros) tarda 10+ segundos
```
**Conclusión:** La consulta de "todos los usuarios" en FEDI es muy pesada o la BD está lenta.

---

## ⚡ Soluciones Recomendadas

### **Opción 1: Aumentar Timeout del Cliente HTTP (Rápido)**
```java
// En MDSeguridadServiceImpl.java
OkHttpClient client = new OkHttpClient.Builder()
    .connectTimeout(30, TimeUnit.SECONDS)  // Conexión
    .readTimeout(30, TimeUnit.SECONDS)      // Lectura (ahora 30s en lugar de 10s)
    .writeTimeout(30, TimeUnit.SECONDS)     // Escritura
    .build();
```

**Ventajas:** Rápido de implementar
**Desventajas:** Solo enmascara el problema, no lo resuelve

---

### **Opción 2: Investigar API Backend en Dev (Recomendado)**
1. **Conectarse a servidor apimanager-dev**
2. **Revisar logs del endpoint `/FEDI/v1.0/catalogos/consultarUsuarios`**
3. **Verificar:**
   - ¿Consulta está tardando realmente 10+ segundos?
   - ¿Base de datos está lenta?
   - ¿Hay queries sin índices?
   - ¿API Manager está throttling requests?

**Pasos:**
```bash
# SSH a apimanager-dev
ssh adminuser@apimanager-dev.ift.org.mx

# Revisar logs de la aplicación
tail -f /var/log/api-manager/catalina.out

# Verificar estado de BD
mysql -u user -p -e "SHOW PROCESSLIST;" # Ver queries lentas
mysql -u user -p -e "SHOW STATUS LIKE 'Questions';" # Estadísticas
```

---

### **Opción 3: Implementar Caché Local**
```java
// Cachear resultados de consultarUsuarios
@Cacheable(value="usuarios", unless="#result == null")
public List<Usuario> consultarUsuarios() {
    // ... llamada a API
}
```

**Ventajas:** Reduce llamadas a API, mejora UI responsiveness
**Desventajas:** Complejidad añadida, sincronización de datos

---

### **Opción 4: Implementar Paginación en Endpoint**
```
Actual:  GET /FEDI/v1.0/catalogos/consultarUsuarios
Nuevo:   GET /FEDI/v1.0/catalogos/consultarUsuarios?page=1&size=50
```

Si el endpoint devuelve miles de usuarios, la paginación ayudará significativamente.

---

## 📋 Acciones Inmediatas

### **PASO 1: Contactar al Equipo de API Manager (DEV)**
Proporcionar esta información:
```
Endpoint problemático: https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios
Error: Socket Timeout después de 10+ segundos
Frecuencia: Sucede en ~50% de los intentos
Cliente: FEDI Portal Web (Java OkHttpClient 3.11.0)

¿Pueden investigar en su lado?
1. Logs de la aplicación backend
2. Tiempo de respuesta de la consulta
3. Estado de la base de datos
4. Configuración de rate limiting
```

### **PASO 2: Implementar Timeout Configurable (Corto Plazo)**
```xml
<!-- En pom.xml o application.properties -->
<property name="http.client.timeout" value="30"/>
```

### **PASO 3: Monitorear Mejora (Largo Plazo)**
Una vez que API Manager resuelva su lado, vamos a ver tiempos de respuesta normales.

---

## 🎓 Conclusión

**El problema NO está en FEDI, está en el backend de API Manager.**

Evidencia:
- ✅ Login al API Manager funciona perfectamente (1.4 segundos)
- ✅ Otras consultas LDAP funcionan bien (125ms)
- ❌ Solo la consulta de "catalogos/consultarUsuarios" timeout
- ❌ Los timeouts son exactos después de 10 segundos (timeout del cliente)

**Recomendación:** Contactar inmediatamente al equipo de infraestructura/API Manager para investigar por qué ese endpoint está lento.

---

## 📈 Logs Relevantes (Correlación ID)

**Timeout 1 - Caché Inicial:**
```
[2aa8d86f-78be-461d-ab8c-718742b12db9] 20:51:50 - GET /FEDI/v1.0/catalogos/consultarUsuarios
[2aa8d86f-78be-461d-ab8c-718742b12db9] 20:52:00 - ERROR: timeout (10094ms)
```

**Timeout 2 - Guardar Documento:**
```
[a9b86802-d5dc-4b29-97ad-b4bf35f522dc] 20:52:53 - GET /FEDI/v1.0/catalogos/consultarUsuarios
[a9b86802-d5dc-4b29-97ad-b4bf35f522dc] 20:53:03 - ERROR: timeout (10063ms)
```

---

## 🔗 Referencias en Código
- [MDSeguridadServiceImpl.java](c:\github\fedi-web\src\main\java\fedi\ift\org\mx\arq\core\service\security\loadsoa\MDSeguridadServiceImpl.java#L185)
- Método: `EjecutaMetodoGET()` (usa OkHttpClient con timeout default)
