# 📋 SOLICITUD TÉCNICA AL EQUIPO DE WSO2 API MANAGER

**Asunto:** CRÍTICO - Investigación de Performance: API Endpoint Lento `/FEDI/v1.0/catalogos/consultarUsuarios`

**Fecha:** 2026-02-08  
**Sistema Afectado:** FEDI Portal Web (Cliente del API Manager)  
**Impacto:** Usuarios no pueden guardar documentos (timeout tras 60 segundos de espera)  
**Prioridad:** ALTA

---

## 📌 RESUMEN EJECUTIVO

El endpoint `/FEDI/v1.0/catalogos/consultarUsuarios` en API Manager DEV está generando comportamiento inconsistente: ocasionalmente responde en < 1 segundo, pero la mayoría de veces espera 60+ segundos sin responder. Necesitamos investigación de API Manager para identificar si el problema está en throttling, timeout interno, backend lento o configuración del proxy.

---

## 🔍 PROBLEMA TÉCNICO IDENTIFICADO

### Síntomas Principales
```
Endpoint:    /FEDI/v1.0/catalogos/consultarUsuarios
URL:         https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios
Método:      GET
Comportamiento: 
  - Ocasionalmente responde en 47-812 ms ✅
  - Mayoría de veces espera 60+ segundos sin respuesta ❌
  - Luego timeout del cliente: java.net.SocketTimeoutException
Frecuencia:  ~80% de intentos fallan
Impacto:     Cliente agota timeout de 60 segundos
```

### Contexto de Funcionamiento
```
✅ FUNCIONAN BIEN:
   - Endpoint: /autorizacion/login/v1.0/credencial/...
     Duración: 1,157 ms (consistente)
     
   - Endpoint: /ldp.inf.ift.org.mx/v1.0/OBTENER_INFO
     Duración: 94 - 812 ms (consistente)

❌ PROBLEMA:
   - Endpoint: /FEDI/v1.0/catalogos/consultarUsuarios
     Duración: Varía entre 47ms y 60,079ms
     Patrón: 80% falla, 20% éxito
```

### Timeline de Fallas
```
2026-02-08 22:39:01 → GET /FEDI/catalogos/consultarUsuarios
2026-02-08 22:40:01 → TIMEOUT after 60,079ms ❌

2026-02-08 22:40:01 → GET /FEDI/catalogos/consultarUsuarios
2026-02-08 22:41:01 → TIMEOUT after 60,064ms ❌

2026-02-08 22:45:47 → GET /FEDI/catalogos/consultarUsuarios
2026-02-08 22:46:47 → TIMEOUT after 60,064ms ❌

2026-02-08 22:45:57 → GET /FEDI/catalogos/consultarUsuarios
2026-02-08 22:45:57 → SUCCESS after 656ms ✅  ← RARO

2026-02-08 22:45:57 → GET /FEDI/catalogos/consultarUsuarios
2026-02-08 22:45:57 → SUCCESS after 47ms ✅   ← RARO
```

---

## 📊 DATOS TÉCNICOS PARA INVESTIGACIÓN

### Detalles de Request
```
Método HTTP:    GET
Endpoint:       /FEDI/v1.0/catalogos/consultarUsuarios
URL Completa:   https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios
Cliente:        Java OkHttpClient 3.11.0
User Agent:     OkHttpClient
Timeout Cliente: 60 segundos (configurable)

Headers Esperados:
  Authorization: Bearer [token]
  Content-Type: application/json

Response Esperado:
  Status: 200 OK
  Body: JSON array de usuarios
  Size Típico: 869 bytes
```

### Información de Correlación (para logs)
```
Correlación ID:  dfd2aff8-4547-462c-8b22-6df0002010b2
Timestamp:       2026-02-08 22:39:01.178
Usuario:         dgtic.dds.ext023 (cuenta de servicio FEDI)
Aplicación:      FEDI Portal Web
IP Cliente:      [desde logs si está disponible]
```

### Error Capturado
```
Exception:  java.net.SocketTimeoutException: timeout
Causa:      Cliente esperó 60 segundos y no recibió respuesta
Stack:      okhttp3.internal.http2.Http2Stream$StreamTimeout
            okhttp3.RealCall.execute() line 77
```

---

## ❓ PREGUNTAS ESPECÍFICAS PARA WSO2

### 1. **¿DÓNDE ESTÁ EL PROBLEMA?**
```
a) ¿El retraso está en API Manager o en el backend?
b) Ejecutar test manual del endpoint desde servidor WSO2:
   curl -v https://localhost:8243/FEDI/v1.0/catalogos/consultarUsuarios \
        -H "Authorization: Bearer [token]"
   
c) ¿Responde rápido desde el servidor o también es lento?
```

### 2. **LOGS DE API MANAGER**
```
a) Logs del período 22:30 - 23:00 del 2026-02-08
   - Buscar: /FEDI/v1.0/catalogos/consultarUsuarios
   - Extraer: Tiempo de procesamiento
   - Mostrar: Request → Response timeline

b) ¿Hay errores en los logs?
c) ¿Hay warnings sobre timeout o backend unavailable?
d) ¿Hay INFO sobre throttling o rate limiting?
```

### 3. **CONFIGURACIÓN DE THROTTLING**
```
a) ¿Existe rate limiting configurado para este endpoint?
   - ¿Límite de requests por segundo/minuto?
   - ¿Límite por usuario?
   - ¿Está actualmente activo?

b) ¿Hay circuit breaker configurado?
   - ¿Qué threshold dispara el circuit breaker?
   - ¿Está en estado OPEN en estos momentos?

c) ¿Hay timeout configurado en API Manager?
   - ¿Cuál es el timeout backend?
   - ¿Está configurado correctamente?
```

### 4. **BACKEND DEL ENDPOINT**
```
a) ¿Cuál es la aplicación backend de este endpoint?
   - ¿WSO2 DSS (Data Services)?
   - ¿Servicio REST externo?
   - ¿Base de datos directa?

b) ¿Cuál es la URL del backend?
   - http://[server]:[port]/[path]

c) ¿El backend está disponible?
   - Hacer health check del backend
   - ¿Responde rápido?
   - ¿Hay conexión a la BD desde el backend?
```

### 5. **COMPORTAMIENTO INTERMITENTE**
```
a) ¿Por qué a veces responde en 47ms y a veces en 60+ segundos?
b) ¿Hay un comportamiento de "warm-up" o "cold start"?
c) ¿Hay caché intermedio que se limpia?
d) ¿Hay balanceador de carga que distribuye a diferentes backends?
e) ¿Un backend es rápido y otro lento?
```

### 6. **MONITOREO Y ESTADÍSTICAS**
```
a) Datos de los últimos 7 días:
   - ¿Cuál es el tiempo de respuesta promedio?
   - ¿Cuál es el percentil 95 y 99?
   - ¿Hay variación por hora?

b) ¿Cuántos requests por segundo recibe este endpoint?
c) ¿Hay correlación entre volumen y tiempo de respuesta?
d) ¿Hay algún cambio reciente que explique el degradation?
```

### 7. **CONFIGURACIÓN DE TIMEOUT**
```
a) ¿Cuál es el timeout configurado en el API Gateway?
   - Connection timeout
   - Socket timeout
   - Request timeout
   
b) El cliente espera 60 segundos máximo
   - ¿API Manager espera menos que eso?
   - ¿Hay timeout intermediate que sale antes?
   
c) Si el timeout de API Manager es 30 segundos:
   - ¿Por qué el cliente espera los 60?
   - ¿El error se propaga desde el backend?
```

---

## 📋 ACCIONES SOLICITADAS

### INMEDIATAS (Hoy/Mañana)
- [ ] Revisar logs de API Manager del período problema (22:30-23:00 del 2026-02-08)
- [ ] Ejecutar health check del backend
- [ ] Verificar estado de throttling/rate limiting
- [ ] Confirmar si el retraso está en API Manager o backend

### CORTO PLAZO (Esta Semana)
- [ ] Análisis de performance: metrics de tiempo de respuesta
- [ ] Investigar comportamiento intermitente
- [ ] Revisar circuit breaker status
- [ ] Revisar configuración de timeouts
- [ ] Identificar si hay cambios recientes

### RECOMENDACIONES
- [ ] Implementar endpoint versión "lite" que traiga solo usuarios activos
- [ ] Implementar paginación (evitar traer todos los usuarios)
- [ ] Implementar caché de corta duración si es aplicable
- [ ] Considerar hacer este endpoint asíncrono (request → polling)
- [ ] Aumentar timeout si el retraso es aceptable
- [ ] Alertas si endpoint tarda > 10 segundos

---

## 📎 INFORMACIÓN DE CONTACTO

**Sistema:** FEDI Portal Web  
**Ambiente:** DEV  
**Equipo Contacto:** Equipo de Desarrollo FEDI  
**Logs Adjuntos:** 
  - Logs_ambiente_dev.txt (con correlación ID para búsqueda)
  - ANALISIS_DIAGNOSTICO_REST_TIMEOUT.md (análisis técnico)

---

## ✅ CHECKLIST PARA WSO2

Confirmar cuando se complete cada punto:

- [ ] Logs de API Manager revisados
- [ ] Health check del backend ejecutado
- [ ] Throttling/rate limiting verificado
- [ ] Ubicación del problema identificada (API Manager vs Backend)
- [ ] Causa raíz preliminar reportada
- [ ] Plan de acción propuesto
- [ ] Timeline de resolución estimado

---

## 🎯 INFORMACIÓN DE CONTEXTO PARA WSO2

### ¿Por qué es crítico?
FEDI es una aplicación de firma digital. Los usuarios necesitan:
1. Cargar un documento
2. Sistema obtiene datos de usuarios del endpoint
3. Guardar documento con metadatos
4. Si el paso 2 tarda 60+ segundos, el usuario cancela la operación

### Solución temporal implementada en FEDI
Aumentamos el timeout del cliente de 10 segundos a 60 segundos. Esto permite que:
- El usuario ESPERA 60 segundos (tolerable pero malo)
- El endpoint responde eventualmente (en ~1 segundo si hay suerte)
- O timeout después de 60 segundos si el backend está muy lento

Pero esta es una solución temporal, no una solución real.

---

**¿Cuándo podemos esperar feedback?** Nos gustaría tener un análisis preliminar en 24-48 horas.

