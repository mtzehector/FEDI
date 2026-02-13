# 📋 SOLICITUD TÉCNICA AL EQUIPO DE BASE DE DATOS

**Asunto:** CRÍTICO - Investigación de Performance: Endpoint `/FEDI/v1.0/catalogos/consultarUsuarios` Lento en DEV

**Fecha:** 2026-02-08  
**Sistema Afectado:** FEDI Portal Web  
**Impacto:** Usuarios no pueden guardar documentos (timeout tras 60 segundos)  
**Prioridad:** ALTA

---

## 📌 RESUMEN EJECUTIVO

El endpoint `/FEDI/v1.0/catalogos/consultarUsuarios` en API Manager DEV está tardando **60+ segundos** en responder, lo que resulta en timeout del cliente y usuarios sin poder guardar documentos. Necesitamos investigación del lado de BD para identificar si el problema está en la query, índices o volumen de datos.

---

## 🔍 PROBLEMA TÉCNICO IDENTIFICADO

### Síntomas
```
Endpoint: https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios
Comportamiento: Espera ~60 segundos sin respuesta, luego falla
Frecuencia: ~80% de los intentos
Impacto: Aplicación cuelga esperando datos
Timeout: 60,079 ms (cliente agota espera)
```

### Contexto Comparativo
```
✅ Login endpoint:        1,157 ms (responde bien)
✅ LDAP queries:          94 - 812 ms (responde bien)
❌ catalogos/usuarios:    60,079 ms (PROBLEMA)
```

### Lo que funciona bien
- Login al WSO2: rápido
- Consultas LDAP individuales: rápido
- Otros endpoints: rápidos
- **Solo este endpoint falla**

---

## 📊 DATOS TÉCNICOS PARA INVESTIGACIÓN

### Logs Capturados
```
Timestamp: 2026-02-08 22:39:01
Inicio:    22:39:01,178
Fin:       22:40:01,257
Duración:  60,079 ms

Usuario:     dgtic.dds.ext023
Correlación: dfd2aff8-4547-462c-8b22-6df0002010b2

Cliente:    Java OkHttpClient 3.11.0
Request:    GET /FEDI/v1.0/catalogos/consultarUsuarios
Response:   NINGUNA (timeout)
```

### Patrones Observados en Logs
```
Intentos exitosos (pero RAROS):
- 22:45:57,067 → Duracion=656ms ✅
- 22:45:57,129 → Duracion=47ms ✅

Intentos fallidos (MAYORÍA):
- 22:39:01 → Duracion=60,079ms ❌
- 22:40:01 → Duracion=60,064ms ❌
- 22:41:01 → Duracion=60,064ms ❌
- 22:45:47 → Duracion=60,064ms ❌
- 22:46:47 → Duracion=60,063ms ❌
- 22:48:08 → Duracion=60,079ms ❌
- 22:49:16 → Duracion=60,079ms ❌

CONCLUSIÓN: Inconsistencia en respuesta
```

---

## ❓ PREGUNTAS ESPECÍFICAS PARA BD

### 1. **¿CUÁL ES LA QUERY?**
```
a) ¿Qué tabla/stored procedure ejecuta el endpoint?
b) ¿Cuál es el SQL exacto?
c) ¿Trae todos los usuarios o hay filtros?
d) ¿Hay uniones (JOINs) a otras tablas?
e) ¿Hay subqueries?
```

### 2. **PERFORMANCE BASELINE**
```
a) Ejecutar directamente en BD:
   SELECT COUNT(*) FROM usuarios_table;
   → ¿Cuántos registros hay?
   
b) Ejecutar la query del endpoint:
   [QUERY COMPLETA]
   → ¿Cuánto tarda?
   
c) ¿Es < 1 segundo o también lenta?
```

### 3. **ÍNDICES Y EJECUCIÓN**
```
a) Mostrar índices de la tabla/tablas:
   SHOW INDEXES FROM usuarios_table;
   
b) Analizar plan de ejecución:
   EXPLAIN [QUERY DEL ENDPOINT];
   
c) ¿Hay table scans completos?
¿Hay índices sin usar?
d) ¿Última vez que se ejecutó ANALYZE TABLE?
```

### 4. **BLOQUEOS Y LOCKS**
```
a) ¿Hay algún LOCK en la tabla usuarios en estos momentos?
b) ¿Hay procesos lentos ejecutándose?
c) Mostrar:
   SHOW PROCESSLIST;
   SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST 
   WHERE TIME > 30;
```

### 5. **RECURSOS**
```
a) ¿CPU está al máximo?
b) ¿Hay suficiente memoria?
c) ¿Hay I/O disk contention?
d) Estado actual del servidor BD:
   SHOW STATUS LIKE '%slow%';
   SHOW VARIABLES LIKE 'slow_query%';
```

### 6. **VOLUMEN DE DATOS**
```
a) ¿Cuántos usuarios hay en total?
b) ¿Cuántos usuarios activos hay?
c) ¿Hay usuarios duplicados o registros huérfanos?
d) ¿El endpoint debería traer TODOS o hay paginación?
e) ¿Hay un stored procedure que toma largo?
```

### 7. **COMPORTAMIENTO INTERMITENTE**
```
a) ¿Por qué a veces responde rápido (47ms) y a veces lento (60s)?
b) ¿Hay un caché que se limpia a intervalos?
c) ¿Hay tabla temporal que se crea y se borra?
d) ¿Hay proceso background que interfiere?
```

---

## 📋 ACCIONES SOLICITADAS

### INMEDIATAS (Hoy/Mañana)
- [ ] Revisar logs del servidor BD entre 22:30 y 22:50 del 2026-02-08
- [ ] Ejecutar la query manualmente y medir tiempo
- [ ] Verificar estado actual: SHOW PROCESSLIST;
- [ ] Verificar índices están siendo usados

### CORTO PLAZO (Esta Semana)
- [ ] Análisis completo del plan de ejecución (EXPLAIN)
- [ ] Revisar si hay tabla temporal intermedia
- [ ] Verificar si hay triggers que ejecutan queries adicionales
- [ ] Optimizar índices si es necesario
- [ ] Establecer baseline de performance esperada

### RECOMENDACIONES
- [ ] Implementar paginación en el endpoint (traer 100 usuarios a la vez en lugar de todos)
- [ ] Implementar caché de corta duración (5-15 minutos)
- [ ] Crear índices compuestos si es necesario
- [ ] Considerar materialized view si la query es muy compleja

---

## 📎 INFORMACIÓN DE CONTACTO

**Sistema:** FEDI Portal Web  
**Ambiente:** DEV  
**Equipo Contacto:** Equipo de Desarrollo FEDI  
**Logs Adjuntos:** Logs_ambiente_dev.txt (ver correlación dfd2aff8-4547-462c-8b22-6df0002010b2)

---

## ✅ CHECKLIST PARA BD

Confirmar cuando se complete cada punto:

- [ ] Logs del servidor BD revisados
- [ ] Query manual ejecutada y testeada
- [ ] Plan de ejecución analizado
- [ ] Índices verificados
- [ ] Causas posibles identificadas
- [ ] Plan de acción propuesto
- [ ] Timeline de resolución estimado

---

**¿Cuándo podemos esperar feedback?** Nos gustaría tener un análisis preliminar en 24-48 horas.

