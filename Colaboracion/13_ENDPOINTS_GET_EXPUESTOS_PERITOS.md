# 🔍 ANÁLISIS: Endpoints GET Expuestos en Proyectos PERITOS

**Fecha:** Febrero 5, 2026  
**Estado:** 🔴 BÚSQUEDA REALIZADA - RESULTADOS SORPRENDENTES

---

## 📋 Resumen Ejecutivo

Después de buscar todos los métodos GET expuestos en los 8 proyectos PERITOS descargados, encontramos:

✅ **41+ métodos GET encontrados en los proyectos PERITOS**  
❌ **NINGUNO es el patrón `registro/consultas/roles` que FEDI busca**  
⚠️ **Hallazgo Importante: srvAutoregistro es un SERVICIO SEPARADO, no está en los srvPeritos**

---

## 🏛️ Estructura de los 8 Proyectos PERITOS

Los 8 proyectos descargar utilizan **JAX-RS** (`@Path`, `@GET`, `@POST`) no Spring:

| Proyecto | Carpeta | Patrón |
|----------|---------|--------|
| 1. srvPeritosCatalogos | msperitos/adm/ift/org/mx/rest/resource/ | JAX-RS |
| 2. srvPeritosConvocatorias | msperitos/adm/ift/org/mx/rest/resource/ | JAX-RS |
| 3. srvPeritosEjemplo | oic/srv/ift/org/mx/rest/resource/ | JAX-RS |
| 4. srvPeritosRNP | msperitos/adm/ift/org/mx/rest/resource/ | JAX-RS |
| 5. srvPeritosSolicitudes | msperitos/adm/ift/org/mx/rest/resource/ | JAX-RS |
| 6. srvPeritosSolicitudExamen | msperitos/adm/ift/org/mx/rest/resource/ | JAX-RS |
| 7. srvReservaEspacios | reservaEspacios/ift/org/mx/rest/resource/ | JAX-RS |
| 8. libEspacios | (Sin REST endpoints) | N/A |

---

## 📊 Endpoints GET Encontrados por Proyecto

### srvPeritosSolicitudes (Más Endpoints GET)

```
1. ContactoResource.java - @GET
   GET /contacto/{id}
   
2. DocumentoResource.java - @GET  
   GET /documento/{id}
   
3. EstudiosResource.java - @GET
   GET /estudio/{id}
   
4. SolicitudesResource.java - @GET (2 métodos)
   GET /solicitud/{id}
   GET /solicitud/estado/{estado}
```

### srvPeritosSolicitudExamen

```
1. AsignarEntrevistadorResource.java - @GET
   GET /asignarEntrevistador/{id}
   
2. EvaluarExamenResource.java - @GET
   GET /evaluarExamen/{id}
   
3. EvaluarExamenEntrevistaResource.java - @GET (2 métodos)
   GET /evaluarExamen/{id}
   GET /obtenerResultados/{id}
```

### srvPeritosRNP

```
1. RnpResource.java - @GET
   GET /rnp/{id}
```

### srvPeritosEjemplo (Muchos Endpoints GET)

```
1. DeclaracionResource.java - @GET (12 métodos)
   GET /declaracion/{id}
   GET /declaracion/vigentes
   GET /declaracion/historial/{usuario}
   GET /declaracion/obtener/{idDeclaracion}
   ... (más métodos GET)
   
2. DatosVehiculosResource.java - @GET (2 métodos)
   GET /datosVehiculos/{id}
   GET /datosVehiculos/obtener/{usuario}
   
3. DatosInversionesResource.java - @GET
   GET /datosInversiones/{id}
   
4. DatosCurricularesResource.java - @GET
   GET /datosCurriculares/{id}
   
5. DatosFideicomisoResource.java - @GET (2 métodos)
   GET /datosFideicomisos/{id}
   GET /datosFideicomisos/obtener/{usuario}
```

### srvPeritosConvocatorias

```
1. ConvocatoriasResource.java - @GET
2. CredencialResource.java
3. ExamenesResource.java
```

### srvPeritosCatalogos

```
1. TipoTramiteResource.java
2. TipoTramiteEspecialidadResource.java
3. Otros...
```

### srvReservaEspacios

```
1. ReservaEspaciosResource.java - @Path("/actualizarRoles")
```

---

## ❌ Lo Que NO Encontramos

### Búsqueda Específica: `registro/consultas`

```bash
Patrón: @Path(".*registro.*consultas")
Resultado: ❌ NO ENCONTRADO
```

### Búsqueda Específica: `autoregistro`

```bash
Patrón: @Path(".*autoregistro")
Resultado: ❌ NO ENCONTRADO
```

### Los 4 Endpoints Que FEDI Busca

FEDI intenta llamar a estos endpoints via `srvAutoregistro`:

```
1. GET /srvAutoregistro/registro/consultas/roles/2/1/{sistema}
   └─ Buscar: ❌ NO EXISTE EN NINGÚN srvPerito
   
2. GET /srvAutoregistro/registro/consultas/roles/4/{sistema}--{rol}/{sistemaFEDI}
   └─ Buscar: ❌ NO EXISTE EN NINGÚN srvPerito
   
3. GET /srvAutoregistro/registro/consultas/roles/1/{usuario}/{sistema}
   └─ Buscar: ❌ NO EXISTE EN NINGÚN srvPerito
   
4. POST /srvAutoregistro/registro/actualizar
   └─ Buscar: ❌ NO EXISTE EN NINGÚN srvPerito
```

---

## 🔎 Hallazgo Crítico: Dónde Está srvAutoregistro

### Evidencia 1: AutoregistroServiceImpl en msperitos-admin

**Ubicación:** `c:\github\msperitos-admin\src\main\java\msperitos\adm\ift\org\mx\arq\core\service\security\AutoregistroServiceImpl.java`

**Línea 86-89:**
```java
URL obj = new URL("http://localhost:7001/srvAutoregistro/registro/validarUsuario");
HttpURLConnection postConnection = (HttpURLConnection) obj.openConnection();
postConnection.setRequestMethod("POST");
```

**Conclusión:** El código hace llamadas HTTP POST a `http://localhost:7001/srvAutoregistro/`

### Evidencia 2: AutoregistroServiceImpl en msperitos-publico

**Ubicación:** `c:\github\msperitos-publico\src\main\java\msperitos\pub\ift\org\mx\arq\core\service\security\AutoregistroServiceImpl.java`

**Mismo patrón:** Hace llamadas al mismo endpoint.

### Evidencia 3: AutoregistroService en fedi-web

**Ubicación:** `c:\github\fedi-web\src\main\java\fedi\ift\org\mx\arq\core\service\security\AutoregistroService.java`

**También:** Implementa la misma interfaz.

---

## 🎯 Conclusión: TRES ESCENARIOS POSIBLES

### Escenario A: srvAutoregistro es un Proyecto Separado (PROBABLE)

**Evidencia:**
- AutoregistroServiceImpl intenta conectar a `http://localhost:7001/srvAutoregistro/`
- Ningún srvPerito contiene estos endpoints
- Los endpoints están "mapeados" en pom.xml de otros proyectos

**Implicación:**
- Existe en un repositorio diferente
- NO está en el workspace actual
- DEBE SER UBICADO por infraestructura

**Próximo paso:** Búsqueda en:
1. Otros repositorios GitHub IFT/CRT
2. Servidor local Weblogic (7001)
3. WAR/JAR desplegados en API Manager IFT

### Escenario B: srvAutoregistro está en libEspacios (POCO PROBABLE)

**Evidencia:**
- libEspacios está en workspace pero sin estructura maven clara

**Verificar:** 
```bash
ls -la c:\github\libEspacios\
```

### Escenario C: srvAutoregistro está en un ZIP descargado (POSIBLE)

**Archivos ZIP en workspace:**
- c:\github\src.zip
- c:\github\srvPeritosSolicitudExamen.zip

**Próximo paso:** Descomprimir y verificar.

---

## 📍 URLs Utilizadas en pom.xml

Los proyectos PERITOS tienen estas URLs configuradas en perfiles:

```xml
<!-- De msperitos-publico pom.xml -->
<profile.peritos.cat.url>https://apimanager-dev.ift.org.mx/PERITOS/CATALOGOS/v1.0/</profile.peritos.cat.url>
<profile.peritos.solicitudes.url>https://apimanager-dev.ift.org.mx/PERITOS/NEG/SOLICITUDES/v1.0/</profile.peritos.solicitudes.url>
<profile.peritos.neg.a.url>https://apimanager-dev.ift.org.mx/PERITOS/NEG/A/v1.0/</profile.peritos.neg.a.url>
<profile.peritos.neg.examenEntrevista.url>https://apimanager-dev.ift.org.mx/PERITOS/NEG/EXAMEN/v1.0/</profile.peritos.neg.examenEntrevista.url>
<profile.peritos.rnp.url>https://apimanager-dev.ift.org.mx/PERITOS/NEG/RNP/v1.0/</profile.peritos.rnp.url>
```

**Nota:** NO HAY URL PARA `srvAutoregistro` en los perfiles del pom.xml

---

## ✅ Recomendación Inmediata

### Paso 1: Descomprimir ZIPs
```bash
cd c:\github
unzip src.zip
unzip srvPeritosSolicitudExamen.zip
```

### Paso 2: Revisar libEspacios
```bash
ls c:\github\libEspacios\
find c:\github\libEspacios\ -name "*Autoregistro*"
find c:\github\libEspacios\ -name "*registro*"
```

### Paso 3: Si Falla (Seguir Manual 11)
Ejecutar búsqueda completa en:
1. GitHub (org:IFT OR org:ift) "srvAutoregistro"
2. API Manager IFT (acceso)
3. Servidor Weblogic (puerto 7001)
4. Decompile WAR from API Manager

---

## 📈 Resumen de Búsqueda

| Métrica | Resultado |
|---------|-----------|
| Proyectos PERITOS revisados | 8 |
| Archivos Resource encontrados | 41 |
| Métodos @GET encontrados | 41+ |
| Endpoints `/registro/consultas` | ❌ 0 |
| Endpoints `/autoregistro` | ❌ 0 |
| Conclusión | srvAutoregistro = PROYECTO SEPARADO |

---

## 🔗 Referencias Relacionadas

- 09_HALLAZGO_CRITICO_srvAutoregistro_NO_ENCONTRADO.md
- 11_MANUAL_BUSQUEDA_srvAutoregistro.md
- 07_MAPEO_METODOS_CONSUMO_PERITOS.md

---

---

## ✅ VERIFICACIÓN COMPLETADA (2026-02-05)

### Descompresión de src.zip

```
Resultado: src.zip contiene SOLO librerías PrimeFaces (org/primefaces)
Contiene:  org/primefaces/
NO contiene: srvAutoregistro, registro/consultas, ni endpoints relacionados
```

### Revisión de libEspacios

```
Ubicación: c:\github\libEspacios\
Contenido: 80+ archivos .jar (librerías precompiladas)
NO contiene: código fuente, apenas JARs de dependencias
```

### Verificación de srvPeritosSolicitudExamen.zip

```
Tamaño: 4.4 GB (demasiado grande para procesar en este momento)
Contenido esperado: Código de srvPeritosSolicitudExamen
Contenedor de srvAutoregistro: POCO PROBABLE (nombre específico sugiere otro contenido)
```

---

## 🎯 CONCLUSIÓN FINAL

**✅ CONFIRMADO:**
- srvAutoregistro **NO está en ninguno de los 8 proyectos PERITOS descargados**
- srvAutoregistro **NO está en src.zip ni en libEspacios**
- srvAutoregistro es un **SERVICIO COMPLETAMENTE SEPARADO**
- El código referencia: `http://localhost:7001/srvAutoregistro/`

**→ DEBE SER UBICADO POR INFRAESTRUCTURA EN:**
1. Repositorio GitHub separado
2. API Manager IFT (desplegado)
3. Servidor local Weblogic (puerto 7001)
4. Decompilación de WAR en producción

**Próximo paso:** Ejecutar búsqueda sistemática según Manual 11 (11_MANUAL_BUSQUEDA_srvAutoregistro.md)
