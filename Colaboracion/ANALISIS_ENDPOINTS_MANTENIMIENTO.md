# 📊 ANÁLISIS DE ENDPOINTS Y ESTADO DEL MANTENIMIENTO

**Fecha:** 12-Feb-2026  
**Estado:** Backend desplegado exitosamente ✅  
**Siguiente:** Identificar endpoints consumibles directamente desde fedi-srv

---

## 🎯 Contexto Actual

### ✅ Base de Datos
- **Sistema:** Microsoft SQL Server (NO Oracle)
- **Host:** 172.17.42.196
- **Puerto:** 1433
- **Base de Datos:** FEDI
- **Usuario:** usr_fedi
- **Driver:** com.microsoft.sqlserver.jdbc.SQLServerDriver
- **Ubicación Configuración:** `C:\github\Colaboracion\server.xml`
- **Estado en Tomcat:** ✅ Disponible (JNDI: jdbc/fedi)

### ✅ Despliegues
- **fedi-srv:** Desplegado exitosamente
  - Endpoint probado: `https://fedidev.crt.gob.mx/srvFEDIApi-1.0/catalogos/consultarUsuarios`
  - Resultado: ✅ **FUNCIONA** (HTTP 200)
  - CURL exitoso desde CMD

- **fedi-web:** Desplegado exitosamente
  - Estado: ✅ Operativo
  - Logs: `C:\github\Colaboracion\Logs_fedi_web_ambiente_dev.txt`

---

## 🔴 PROBLEMA IDENTIFICADO EN LOGS

### Timeout de 120 segundos en API Manager

**Línea 116-136 del log:**
```
2026-02-12 17:09:56,143 [INFO] FEDIServiceImpl:114 
  *** [DIAG-WEB] Llamando API: 
  https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios

2026-02-12 17:11:56,214 [ERROR] MDSeguridadServiceImpl:232
  [MDSeguridadService.EjecutaMetodoGET] IOException. 
  URL=https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios
  Error=timeout, Duracion=120071ms
```

### 🔍 Causa Raíz
`fedi-web` intenta conectar a `/FEDI/v1.0/catalogos/consultarUsuarios` a través de **API Manager**:
```
fedi-web → API Manager → fedi-srv (¿nunca llega?)
```

**Resultado:** Timeout de 120 segundos

### ✅ Pero el Endpoint Funciona Directamente
```
curl -k -i https://fedidev.crt.gob.mx/srvFEDIApi-1.0/catalogos/consultarUsuarios
→ HTTP 200 ✅
```

**Conclusión:** El endpoint existe y funciona. El problema es la **ruta en API Manager**.

---

## 🔗 Endpoints Disponibles en fedi-srv

Basado en el código fuente:

### 1. **CatalogosResources.java**
Ruta base: `/catalogos`

| Endpoint | Método | Parámetros | Descripción |
|----------|--------|-----------|-------------|
| `/catalogos/consultarUsuarios` | GET | Ninguno | ✅ **FUNCIONA** - Obtener catálogo de usuarios |
| `/catalogos/consultarSistema` | GET | `sistemaId` | ? Estado desconocido |
| `/catalogos/consultarXXX` | GET | Varía | Otros endpoints (revisar código) |

### 2. **Otros Endpoints REST**
(Revisar en `src/main/java/fedi/srv/ift/org/mx/rest/resource/`)

---

## 🚀 PLAN DE ACCIÓN INMEDIATO

### Objetivo
Cambiar `fedi-web` para consumir endpoints **directamente de fedi-srv** en lugar de a través de API Manager.

### Cambios Requeridos en fedi-web

**Archivo:** `fedi-web/pom.xml`

Cambiar la variable de perfil:

#### Perfil Actual (API Manager)
```xml
<profile.fedi.url>https://apimanager-dev.ift.org.mx/FEDI/v1.0/</profile.fedi.url>
```

#### Perfil Nuevo (Directo a fedi-srv)
```xml
<profile.fedi.url>https://fedidev.crt.gob.mx/srvFEDIApi-1.0/</profile.fedi.url>
```

### Validación Post-Cambio

1. Recompilar fedi-web:
   ```
   mvn clean install -P development-oracle1 -DskipTests
   ```

2. Desplegar en Tomcat (tú mismo)

3. Probar login desde navegador:
   ```
   https://fedidev.crt.gob.mx/FEDIPortalWeb-1.0/
   ```

4. Verificar que:
   - Login exitoso
   - Carga de catálogo de usuarios exitosa
   - ✅ Sin timeout

---

## 📋 Endpoints Pendientes de Validar

### Fase 1: Validar Endpoints Básicos

| # | Endpoint | URL Completa | Estado | Prioridad |
|---|----------|-------------|--------|-----------|
| 1 | `consultarUsuarios` | `https://fedidev.crt.gob.mx/srvFEDIApi-1.0/catalogos/consultarUsuarios` | ✅ FUNCIONA | 🔴 CRÍTICA |
| 2 | `obtenerDocumentos` | Por definir | ? | 🟡 ALTA |
| 3 | `firmarDocumentos` | Por definir | ? | 🟡 ALTA |
| 4 | Otros catálogos | Por definir | ? | 🟢 MEDIA |

### Fase 2: Endpoints del API Manager

Revisar cuáles endpoints del API Manager:
- Tienen backend funcional en fedi-srv
- Se pueden consumir directamente

---

## 📁 Archivos Relevantes Guardados

| Archivo | Ubicación | Contenido |
|---------|-----------|----------|
| Configuración BD | `C:\github\Colaboracion\server.xml` | JNDI, DataSource SQL Server |
| Logs fedi-web | `C:\github\Colaboracion\Logs_fedi_web_ambiente_dev.txt` | Detalles del timeout |
| Análisis JNDI | `C:\github\Colaboracion\RESOLUCION_ERROR_DESPLIEGUE_JNDI.md` | Explicación de la solución |
| Este documento | `C:\github\Colaboracion\ANALISIS_ENDPOINTS_MANTENIMIENTO.md` | Plan de endpoints |

---

## 🎯 Próximas Acciones (En Orden)

### ✅ PASO 1: Cambiar URL en pom.xml de fedi-web
**Cambio:** `apimanager-dev.ift.org.mx` → `fedidev.crt.gob.mx/srvFEDIApi-1.0/`

**Quién:** GitHub Copilot (ahora mismo)

**Validación:** Recompilación sin errores

### ✅ PASO 2: Compilar fedi-web con nuevo perfil
```
mvn clean install -P development-oracle1 -DskipTests
```

**Quién:** GitHub Copilot (ahora mismo)

### ⏳ PASO 3: Desplegar fedi-web en Tomcat
**Quién:** Tú (con cuenta de escritorio remoto)

**Ubicación WAR:** `C:\github\fedi-web\target\FEDIPortalWeb-1.0.war`

### ⏳ PASO 4: Prueba End-to-End
1. Acceder a: `https://fedidev.crt.gob.mx/FEDIPortalWeb-1.0/`
2. Login: `dgtic.dds.ext023` / `password`
3. Verificar:
   - Login exitoso
   - Catálogo de usuarios cargado
   - Sin timeout

---

## 📌 Recordatorios

1. ✅ Guardando todo en `C:\github\Colaboracion` para continuidad
2. ✅ BD es SQL Server, no Oracle (no necesita ojdbc)
3. ✅ fedi-srv está desplegado y funciona
4. ✅ Endpoint `/catalogos/consultarUsuarios` responde
5. ⏳ Falta cambiar fedi-web para consumir directamente

---

**Última actualización:** 2026-02-12 08:30  
**Siguiente paso:** Proceder con PASO 1 y PASO 2
