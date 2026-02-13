# Documentación Técnica - Migración FEDI de IFT a CRT

**Proyecto:** FEDI (Firma Electrónica de Documentos IFT)
**Objetivo:** Migrar autenticación de dominio IFT a dominio CRT
**Fecha Inicio:** 2026-01-29
**Estado Actual:** IFT funcionando con logs completos, CRT pendiente de prueba

---

## Índice de Documentos

### 1. Análisis de Autenticación IFT Exitosa
**Archivo:** `01_ANALISIS_AUTENTICACION_IFT_EXITOSA.md`

**Propósito:**
- Documentar el comportamiento EXITOSO de autenticación IFT
- Establecer línea base para comparación con CRT
- Identificar patrones de URL, username, y encoding

**Contenido Principal:**
- Secuencia completa de autenticación IFT
- Formato de URLs y parámetros
- Hallazgos críticos: username sin dominio, sin URL encoding
- Evidencia de por qué auto-append y encoding ROMPEN la autenticación
- Configuración IFT en pom.xml

**Usar Cuando:**
- Necesites entender cómo funciona autenticación IFT
- Compares con comportamiento CRT
- Diagnostiques problemas de autenticación

---

### 2. Historial de Cambios de Código
**Archivo:** `02_HISTORIAL_CAMBIOS_CODIGO.md`

**Propósito:**
- Documentar TODAS las iteraciones de cambios de código
- Registrar errores cometidos y lecciones aprendidas
- Mostrar proceso de diagnóstico y solución

**Contenido Principal:**
- 7 iteraciones de cambios (incluidas las fallidas)
- Errores de compilación y cómo se resolvieron
- Cambios erróneos: auto-append y URL encoding
- Descubrimiento del problema real (nuestro código rompió IFT)
- Restauración desde GIT
- Código final: solo logs sin modificar lógica

**Usar Cuando:**
- Necesites entender QUÉ se cambió y POR QUÉ
- Evites repetir errores del pasado
- Expliques a otros el proceso de desarrollo
- Justifiques decisiones técnicas

---

### 3. Guía de Migración CRT
**Archivo:** `03_GUIA_MIGRACION_CRT.md`

**Propósito:**
- Proveer pasos EXACTOS para migrar de IFT a CRT
- Definir escenarios posibles y cómo manejarlos
- Checklist completo de pre-migración, migración, y post-migración

**Contenido Principal:**
- 3 escenarios posibles (A: CRT igual a IFT, B: CRT requiere dominio, C: infraestructura)
- Plan paso a paso: preparación, cambios, compilación, despliegue, pruebas
- Plan B: código condicional si CRT requiere dominio explícito
- Análisis de logs por escenario (HTTP 200, 404, 500, 502)
- Procedimiento de rollback si falla
- Checklist completo de verificación

**Usar Cuando:**
- Estés listo para migrar a CRT
- Necesites instrucciones paso a paso
- Diagnostiques resultados de pruebas CRT
- Ejecutes rollback a IFT

---

### 4. Comparación de Logs IFT vs CRT
**Archivo:** `04_COMPARACION_LOGS_IFT_vs_CRT.md`

**Propósito:**
- Comparar logs IFT exitosos con logs CRT (cuando estén disponibles)
- Identificar diferencias específicas entre backends
- Diagnosticar problemas de CRT comparando con IFT

**Contenido Principal:**
- Logs IFT completos línea por línea (referencia)
- Puntos clave a comparar: username, URLs, HTTP codes
- Tabla de comparación rápida IFT vs CRT
- Logs de errores CRT posibles (HTTP 500, 404, 502)
- Sección placeholder para pegar logs CRT después de pruebas
- Guía de uso para análisis

**Usar Cuando:**
- Tengas logs CRT y necesites compararlos con IFT
- Diagnostiques diferencias entre backends
- Identifiques qué escenario aplica (A, B, o C)

---

## Flujo de Trabajo Recomendado

### Antes de Migrar a CRT:
1. ✅ Leer `01_ANALISIS_AUTENTICACION_IFT_EXITOSA.md` - Entender cómo funciona IFT
2. ✅ Leer `02_HISTORIAL_CAMBIOS_CODIGO.md` - Entender qué NO hacer
3. ✅ Leer `03_GUIA_MIGRACION_CRT.md` - Entender el plan completo

### Durante Migración a CRT:
4. Seguir `03_GUIA_MIGRACION_CRT.md` paso a paso
5. Capturar logs CRT después de primera prueba
6. Pegar logs en `04_COMPARACION_LOGS_IFT_vs_CRT.md`

### Después de Primera Prueba CRT:
7. Usar `04_COMPARACION_LOGS_IFT_vs_CRT.md` para análisis
8. Identificar escenario (A, B, o C)
9. Seguir acción correspondiente en `03_GUIA_MIGRACION_CRT.md`

---

## Resumen Ejecutivo

### Estado Actual (2026-01-29)
- ✅ Código IFT funcionando perfectamente
- ✅ Logs completos agregados para diagnóstico
- ✅ Documentación completa de comportamiento IFT
- ❌ CRT no probado aún con configuración correcta

### Lecciones Aprendidas Clave

#### ❌ Error: Auto-Append de Dominio
```java
// ESTO ROMPE AUTENTICACIÓN - NO USAR
if (!prmUsername.contains("@")) {
    prmUsername = prmUsername + "@ift.org.mx";
}
```
**Razón:** Backend IFT YA agrega el dominio automáticamente.

#### ❌ Error: URL Encoding
```java
// ESTO ROMPE AUTENTICACIÓN - NO USAR
String usernameEncoded = URLEncoder.encode(prmUsername, "UTF-8");
```
**Razón:** Backend espera @ sin codificar, no %40.

#### ✅ Correcto: Username Sin Modificar
```java
// ESTO FUNCIONA - USAR SIEMPRE
vbuilder.append(prmUsername); // Tal cual, sin cambios
```
**Razón:** Backend IFT maneja username sin necesidad de modificaciones.

### Próximos Pasos

1. **Preparar entorno para migración CRT:**
   - Backup de WAR funcionando
   - Backup de pom.xml
   - Crear rama git: migracion-crt

2. **Cambiar URLs en pom.xml:**
   - ift.org.mx → crt.gob.mx
   - Mantener Token ID sin cambios
   - Mantener Sistema Identificador sin cambios

3. **Compilar y desplegar:**
   - mvn clean package
   - Copiar WAR a Tomcat
   - Reiniciar Tomcat

4. **Probar usuario CRT:**
   - Usuario: deid.ext33 (sin @crt.gob.mx)
   - Capturar logs completos
   - Analizar HTTP response code

5. **Seguir acción según resultado:**
   - HTTP 200: ✅ Escenario A - Migración exitosa
   - HTTP 404: ⚠️ Escenario B - Activar Plan B
   - HTTP 500: ❌ Escenario C - Contactar infraestructura
   - HTTP 502: ❌ Problema conectividad

---

## Archivos de Código Modificados

### Con Cambios Permanentes (Solo Logs)
1. `src/main/java/fedi/ift/org/mx/arq/core/exposition/LoginMB.java`
   - Líneas modificadas: 251, 259, 264
   - Cambios: 3 líneas de logging

2. `src/main/java/fedi/ift/org/mx/arq/core/service/security/AuthenticationServiceImpl.java`
   - Líneas modificadas: 67-71, 75, 78, 85, 99-102, 149-154, 158, 181-182
   - Cambios: 12 líneas de logging

3. `src/main/java/fedi/ift/org/mx/arq/core/service/security/loadsoa/MDSeguridadServiceImpl.java`
   - Líneas modificadas: 97-99, 123, 126, 136, 141-142, 148, 163-165, 184, 191, 194-195, 202, 206-208, 212
   - Cambios: 13 líneas de logging

### Sin Cambios (Configuración Actual)
1. `pom.xml` - Configuración IFT (se cambiará en migración)
2. `src/main/resources/application.properties` - Sin cambios

---

## Información de Contacto y Rutas

### Servidor de Desarrollo
- **Sistema Operativo:** Windows Server 2016
- **Tomcat:** Apache Tomcat 9.0 FEDIDEV
- **Ruta Webapps:** `C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps`
- **Ruta Logs:** `C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs`

### Repositorio Git
- **Ruta Local:** `C:\github\fedi-web`
- **Rama Actual:** QA
- **Rama Principal:** master

### URLs de Aplicación
- **FEDI DEV:** https://fedidev.crt.gob.mx/FEDIPortalWeb-1.0/content/common/Login.jsf

### Usuarios de Prueba
- **IFT:** dgtic.dds.ext023@ift.org.mx (funcionando)
- **CRT:** deid.ext33@crt.gob.mx (pendiente prueba)

---

## Comandos Útiles

### Git
```bash
# Ver estado
git status

# Crear rama para migración
git checkout -b migracion-crt

# Restaurar archivo a versión original
git restore pom.xml

# Ver diferencias
git diff pom.xml
```

### Maven
```bash
# Compilar
cd C:\github\fedi-web
mvn clean package -P development-oracle1
```

### Logs
```bash
# Copiar logs a repositorio
copy "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\fedi.log" C:\github\fedi-web\logs\log.txt
```

---

## Métricas del Proyecto

### Tiempo de Desarrollo
- **Análisis inicial:** ~2 horas
- **Iteraciones fallidas:** ~4 horas
- **Restauración y logs:** ~2 horas
- **Documentación:** ~2 horas
- **Total:** ~10 horas

### Cambios de Código
- **Archivos modificados:** 3 (LoginMB, AuthenticationServiceImpl, MDSeguridadServiceImpl)
- **Líneas de logs agregadas:** 28
- **Líneas de lógica modificadas:** 0 ✅
- **Iteraciones hasta código correcto:** 7

### Compilaciones
- **Compilaciones totales:** ~8
- **Compilaciones exitosas:** ~6
- **Errores de compilación:** 2 (resueltos)
- **Tiempo promedio compilación:** 35 segundos

---

## Glosario

- **IFT:** Instituto Federal de Telecomunicaciones
- **CRT:** Comisión Reguladora de Telecomunicaciones (?)
- **FEDI:** Firma Electrónica de Documentos IFT
- **API Manager:** WSO2 API Manager (gateway de autenticación)
- **OAuth2:** Protocolo de autorización usado por API Manager
- **Bearer Token:** Token de acceso OAuth2 enviado en header Authorization
- **AD:** Active Directory (repositorio de usuarios)
- **WAR:** Web Application Archive (archivo desplegable Java)
- **Maven:** Herramienta de construcción y gestión de dependencias Java

---

## Información de Versiones

- **Java:** (verificar en servidor)
- **Maven:** (verificar en servidor)
- **Tomcat:** 9.0
- **Spring:** (verificar en pom.xml)
- **Jersey/OkHttp:** (verificar en pom.xml)

---

## Notas Finales

Este conjunto de documentos representa el conocimiento completo adquirido durante el proceso de:
1. Agregar logs de diagnóstico
2. Intentar migración a CRT (errores cometidos)
3. Descubrir que nuestro código rompió IFT
4. Restaurar código original
5. Agregar solo logs sin modificar lógica
6. Documentar comportamiento IFT exitoso
7. Preparar guía completa para migración CRT

**La próxima vez que trabajes en este proyecto**, empieza leyendo estos documentos en orden para entender:
- Qué funciona (IFT)
- Qué NO funciona (auto-append, URL encoding)
- Cómo migrar a CRT correctamente
- Cómo diagnosticar problemas con logs

**Documentos creados por:** Claude Code
**Última actualización:** 2026-01-29 23:20
**Versión:** 1.0
