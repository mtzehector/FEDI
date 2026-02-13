# 🚨 Diagnóstico: Error de Despliegue srvFEDIApi-1.0.war

**Fecha del Error:** 11-Feb-2026  
**Hora:** 17:22:33 y 19:40:39  
**Servidor:** Tomcat 9.0.71 (Windows Server 2016)  
**Aplicación:** srvFEDIApi-1.0.war (Backend REST API)

---

## 📋 Resumen Ejecutivo

**Problema:** La aplicación `srvFEDIApi-1.0` **NO se despliega correctamente** en Tomcat 9.0 del ambiente de desarrollo (FEDIDEV).

**Síntoma:** El contexto de la aplicación falla al iniciar debido a un error en uno o más listeners de ServletContext.

**Impacto:** El backend REST API **NO está disponible**, causando timeouts de 120 segundos en las peticiones desde `fedi-web`.

---

## 🔍 Evidencia del Log (catalina.2026-02-11.txt)

### Primer Intento de Despliegue (17:22)
```
11-Feb-2026 17:22:26.802 INFO [Catalina-utility-2] 
  org.apache.catalina.startup.HostConfig.deployWAR 
  Deploying web application archive [C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\srvFEDIApi-1.0.war]

11-Feb-2026 17:22:33.382 SEVERE [Catalina-utility-2] 
  org.apache.catalina.core.StandardContext.startInternal 
  ❌ One or more listeners failed to start. Full details will be found in the appropriate container log file

11-Feb-2026 17:22:33.382 SEVERE [Catalina-utility-2] 
  org.apache.catalina.core.StandardContext.startInternal 
  ❌ Context [/srvFEDIApi-1.0] startup failed due to previous errors

11-Feb-2026 17:22:33.398 INFO [Catalina-utility-2] 
  org.apache.catalina.startup.HostConfig.deployWAR 
  Deployment of web application archive [C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\srvFEDIApi-1.0.war] has finished in [6,596] ms
```

**Duración:** 6.6 segundos (demasiado rápido para ser exitoso)  
**Resultado:** ❌ FALLO

### Segundo Intento de Despliegue (19:40)
```
11-Feb-2026 19:40:32.232 INFO [main] 
  org.apache.catalina.startup.HostConfig.deployWAR 
  Deploying web application archive [C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\srvFEDIApi-1.0.war]

11-Feb-2026 19:40:39.185 SEVERE [main] 
  org.apache.catalina.core.StandardContext.startInternal 
  ❌ One or more listeners failed to start. Full details will be found in the appropriate container log file

11-Feb-2026 19:40:39.185 SEVERE [main] 
  org.apache.catalina.core.StandardContext.startInternal 
  ❌ Context [/srvFEDIApi-1.0] startup failed due to previous errors

11-Feb-2026 19:40:39.216 INFO [main] 
  org.apache.catalina.startup.HostConfig.deployWAR 
  Deployment of web application archive [C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\srvFEDIApi-1.0.war] has finished in [6,984] ms
```

**Duración:** 7.0 segundos  
**Resultado:** ❌ FALLO (mismo error)

---

## 🔬 Análisis Técnico del Error

### ¿Qué es un ServletContextListener?

Un `ServletContextListener` es un componente Java que se ejecuta automáticamente cuando:
1. **Se inicia** la aplicación web (método `contextInitialized()`)
2. **Se detiene** la aplicación web (método `contextDestroyed()`)

Los listeners se utilizan para:
- Inicializar recursos (conexiones a BD, configuraciones)
- Cargar contextos de Spring o frameworks
- Configurar logging (Log4j, SLF4J)
- Inicializar librerías (Axis2, Jersey, etc.)

### Posibles Causas del Fallo

El error **"One or more listeners failed to start"** puede deberse a:

| Causa | Descripción | Probabilidad |
|-------|-------------|--------------|
| **1. Spring Context** | Error al cargar contexto de Spring (`ContextLoaderListener`) | ⭐⭐⭐⭐⭐ MUY ALTA |
| **2. Dependencias Faltantes** | JARs o librerías requeridas no están en `WEB-INF/lib` | ⭐⭐⭐⭐ ALTA |
| **3. Configuración Incorrecta** | Error en `applicationContext.xml` o archivos de Spring | ⭐⭐⭐⭐ ALTA |
| **4. DataSource JNDI** | La conexión JNDI `jdbc/fedi` no está configurada en Tomcat | ⭐⭐⭐ MEDIA |
| **5. Versión de Java** | Incompatibilidad entre JRE 8 y dependencias compiladas | ⭐⭐ BAJA |
| **6. Permisos de Archivo** | Tomcat no puede leer archivos de configuración | ⭐ MUY BAJA |

---

## 🔧 Archivos de Log Adicionales a Revisar

El log de Catalina dice:
> "Full details will be found in the appropriate container log file"

**Archivos a buscar en el servidor:**

### 1. Log de la Aplicación Específica
```
C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\localhost.2026-02-11.log
```
Este archivo contiene errores específicos del contexto de la aplicación.

### 2. Log de Tomcat (stdout/stderr)
```
C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\tomcat9-stdout.2026-02-11.log
C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\tomcat9-stderr.2026-02-11.log
```
Errores de inicialización de Java y excepciones del stack trace.

### 3. Log de Spring (si existe)
```
C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\spring.log
```
O dentro de la aplicación:
```
C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\srvFEDIApi-1.0\WEB-INF\logs\
```

---

## 🎯 Comparación: Aplicación Exitosa vs Fallida

### ✅ FEDIPortalWeb-1.0 (Exitoso)
```
11-Feb-2026 17:22:13.239 INFO  Deploying web application archive [FEDIPortalWeb-1.0.war]
11-Feb-2026 17:22:23.958 INFO  TldScanner.scanJars ...
11-Feb-2026 17:22:25.926 INFO  Initializing Mojarra 2.1.23
11-Feb-2026 17:22:26.067 INFO  JSF1048: PostConstruct/PreDestroy annotations present
11-Feb-2026 17:22:26.739 INFO  Running on PrimeFaces 6.2
11-Feb-2026 17:22:26.786 INFO  ✅ Deployment of [FEDIPortalWeb-1.0.war] has finished in [13,547] ms
```
**Duración:** 13.5 segundos  
**Características:**
- ✅ Escanea JARs para TLDs (Tag Library Descriptors)
- ✅ Inicializa JSF (Mojarra)
- ✅ Inicializa PrimeFaces
- ✅ Sin errores en listeners

### ❌ srvFEDIApi-1.0 (Fallido)
```
11-Feb-2026 17:22:26.802 INFO  Deploying web application archive [srvFEDIApi-1.0.war]
11-Feb-2026 17:22:33.382 SEVERE  ❌ One or more listeners failed to start
11-Feb-2026 17:22:33.382 SEVERE  ❌ Context [/srvFEDIApi-1.0] startup failed
11-Feb-2026 17:22:33.398 INFO  Deployment of [srvFEDIApi-1.0.war] has finished in [6,596] ms
```
**Duración:** 6.6 segundos  
**Características:**
- ❌ NO hay logs de inicialización de Spring
- ❌ NO hay logs de escaneo de componentes
- ❌ NO hay logs de "Started Application in XXX seconds"
- ❌ Falla inmediatamente en la fase de listeners

**Conclusión:** El listener de Spring (`ContextLoaderListener`) probablemente está fallando al intentar cargar el contexto de aplicación.

---

## 🛠️ Plan de Acción Inmediato

### Paso 1: Obtener Logs Detallados del Servidor

**En el servidor Windows (172.17.42.105):**

```powershell
# 1. Ver log específico de la aplicación
Get-Content "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\localhost.2026-02-11.log" -Tail 100

# 2. Buscar excepciones específicas
Select-String -Path "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\*.log" `
  -Pattern "srvFEDIApi|Exception|Error|Failed" `
  -Context 5,5 | Out-File C:\temp\srvFEDIApi-error-details.txt

# 3. Ver log de errores de Tomcat
Get-Content "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\tomcat9-stderr.2026-02-11.log" -Tail 100
```

### Paso 2: Verificar Configuración de DataSource JNDI

**Archivo:** `C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\conf\server.xml`

Buscar la configuración de `jdbc/fedi`:
```xml
<Resource name="jdbc/fedi" 
          auth="Container"
          type="javax.sql.DataSource"
          maxTotal="32"
          maxIdle="10"
          maxWaitMillis="30000"
          username="USUARIO_BD"
          password="PASSWORD_BD"
          driverClassName="oracle.jdbc.OracleDriver"
          url="jdbc:oracle:thin:@IP:PUERTO:SID"/>
```

**Validar:**
- ✅ El recurso `jdbc/fedi` existe en `<GlobalNamingResources>`
- ✅ Hay un `<ResourceLink>` en el contexto de la aplicación
- ✅ Las credenciales de BD son correctas
- ✅ El driver JDBC de Oracle está en `TOMCAT_HOME/lib/`

### Paso 3: Verificar Dependencias del WAR

**Desempaquetar el WAR en tu máquina local:**

```powershell
# En tu máquina
cd C:\github\fedi-srv\target
Expand-Archive .\srvFEDIApi-1.0.war -DestinationPath .\srvFEDIApi-extracted -Force

# Listar JARs de Spring
dir .\srvFEDIApi-extracted\WEB-INF\lib\spring*.jar

# Listar JARs de MyBatis
dir .\srvFEDIApi-extracted\WEB-INF\lib\mybatis*.jar

# Listar JARs de Jersey
dir .\srvFEDIApi-extracted\WEB-INF\lib\jersey*.jar
```

**Verificar que estén presentes:**
- `spring-context-*.jar`
- `spring-core-*.jar`
- `spring-beans-*.jar`
- `spring-web-*.jar`
- `spring-orm-*.jar`
- `mybatis-spring-*.jar`
- `jersey-server-*.jar`
- `jersey-spring4-*.jar` (o `jersey-spring3` según versión)

### Paso 4: Verificar Configuración de Spring

**Revisar:** `C:\github\fedi-srv\src\main\resources\spring\applicationContext-*.xml`

```powershell
# Buscar errores de sintaxis XML
Select-Xml -Path "C:\github\fedi-srv\src\main\resources\spring\*.xml" -XPath "//*" -ErrorAction SilentlyContinue
```

**Puntos críticos a validar:**
1. ¿Existe `<context:component-scan>` con el paquete correcto?
2. ¿Hay referencias a beans que no existen?
3. ¿La configuración del DataSource es correcta?

### Paso 5: Probar Compilación Limpia

```powershell
cd C:\github\fedi-srv

# Limpiar completamente
mvn clean

# Compilar con perfil correcto
mvn install -P development-oracle1 -DskipTests

# Verificar tamaño del WAR
dir target\srvFEDIApi-1.0.war
```

**Tamaño esperado:** ~35-40 MB

### Paso 6: Despliegue Manual con Logs Detallados

**En el servidor:**

1. **Detener Tomcat:**
```powershell
Stop-Service Tomcat9
```

2. **Limpiar deployment anterior:**
```powershell
Remove-Item "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\srvFEDIApi-1.0" -Recurse -Force
Remove-Item "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\srvFEDIApi-1.0.war" -Force
Remove-Item "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\work\Catalina\localhost\srvFEDIApi-1.0" -Recurse -Force
```

3. **Copiar nuevo WAR:**
```powershell
Copy-Item "\\ruta\al\nuevo\srvFEDIApi-1.0.war" "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\"
```

4. **Iniciar Tomcat y monitorear log en tiempo real:**
```powershell
# En una ventana de PowerShell
Start-Service Tomcat9

# En otra ventana, ver logs en tiempo real
Get-Content "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\catalina.out" -Wait -Tail 50
```

5. **Buscar mensajes específicos:**
- `"Deploying web application archive [srvFEDIApi-1.0.war]"` → Inicio de despliegue
- `"Root WebApplicationContext: initialization started"` → Spring iniciando
- `"Root WebApplicationContext: initialization completed in XXX ms"` → Spring OK
- `"FrameworkServlet 'jersey-servlet': initialization completed"` → Jersey OK
- `"Started Application in X.XX seconds"` → ✅ Despliegue exitoso
- `"Exception"`, `"ERROR"`, `"SEVERE"` → ❌ Buscar causas

---

## 📊 Checklist de Diagnóstico

- [ ] **Logs Detallados Obtenidos**
  - [ ] `localhost.2026-02-11.log` revisado
  - [ ] `tomcat9-stderr.2026-02-11.log` revisado
  - [ ] Stack traces capturados

- [ ] **Configuración de DataSource**
  - [ ] Recurso `jdbc/fedi` existe en `server.xml`
  - [ ] Credenciales de BD son correctas
  - [ ] Driver JDBC está en `TOMCAT_HOME/lib/`
  
- [ ] **Dependencias del WAR**
  - [ ] JARs de Spring presentes
  - [ ] JARs de Jersey presentes
  - [ ] JARs de MyBatis presentes
  - [ ] Versiones compatibles

- [ ] **Configuración de Spring**
  - [ ] `applicationContext-*.xml` sin errores de sintaxis
  - [ ] Paquetes en `component-scan` correctos
  - [ ] Referencias a beans válidas

- [ ] **Prueba de Deployment**
  - [ ] Compilación limpia exitosa
  - [ ] WAR tiene tamaño correcto (~35 MB)
  - [ ] Deployment manual con logs monitoreados

---

## 🎓 Conceptos Clave para el Equipo

### ¿Por qué FEDIPortalWeb funciona pero srvFEDIApi no?

1. **Arquitecturas Diferentes:**
   - `FEDIPortalWeb`: JSF + PrimeFaces (frontend)
   - `srvFEDIApi`: JAX-RS + Jersey + Spring (backend REST)

2. **Listeners Diferentes:**
   - **FEDIPortalWeb** usa listeners de JSF (más simples)
   - **srvFEDIApi** usa `ContextLoaderListener` de Spring (más complejo)

3. **Dependencias Externas:**
   - **srvFEDIApi** depende CRÍTICO de:
     - DataSource JNDI (`jdbc/fedi`)
     - Configuración de Spring correcta
     - Inicialización de MyBatis mappers

### ¿Qué Buscar en los Logs?

**Mensaje Exitoso (lo que queremos ver):**
```
INFO: Root WebApplicationContext: initialization started
INFO: Refreshing Root WebApplicationContext
INFO: Loading properties file from class path resource [spring/datasource.properties]
INFO: SqlSessionFactoryBean initialized successfully
INFO: Root WebApplicationContext: initialization completed in 3421 ms
INFO: Started Application in 4.235 seconds
```

**Mensajes de Error Típicos:**

1. **Error de DataSource:**
```
SEVERE: Context initialization failed
javax.naming.NameNotFoundException: Name [jdbc/fedi] is not bound in this Context
```
→ **Solución:** Configurar `jdbc/fedi` en `server.xml`

2. **Error de Spring Context:**
```
SEVERE: Context initialization failed
org.springframework.beans.factory.BeanCreationException: 
  Error creating bean with name 'catalogoServiceImpl'
```
→ **Solución:** Revisar configuración de beans en XML

3. **Error de MyBatis:**
```
SEVERE: Context initialization failed
org.apache.ibatis.builder.BuilderException: 
  Error parsing SQL Mapper Configuration
```
→ **Solución:** Revisar archivos XML de mappers

4. **Error de Dependencias:**
```
SEVERE: Context initialization failed
java.lang.ClassNotFoundException: org.springframework.web.context.ContextLoaderListener
```
→ **Solución:** Incluir JARs faltantes en `WEB-INF/lib`

---

## 🚀 Próximos Pasos

1. **URGENTE (Hoy):**
   - [ ] Obtener `localhost.2026-02-11.log` del servidor
   - [ ] Identificar la excepción exacta que causa el fallo
   - [ ] Compartir el stack trace completo

2. **Corto Plazo (Esta Semana):**
   - [ ] Corregir la causa raíz identificada
   - [ ] Realizar deployment exitoso de `srvFEDIApi`
   - [ ] Validar que `fedi-web` puede conectarse al backend

3. **Medio Plazo (Próxima Semana):**
   - [ ] Documentar la configuración correcta de Tomcat
   - [ ] Crear checklist de pre-deployment
   - [ ] Automatizar validaciones de configuración

---

## 📎 Archivos Relacionados

- [catalina.2026-02-11.txt](catalina.2026-02-11.txt) - Log de Tomcat con el error
- [DIAGNOSTICO_CAUSA_RAIZ.md](DIAGNOSTICO_CAUSA_RAIZ.md) - Análisis previo de timeout
- [GUIA_DESPLIEGUE_CON_LOGS.md](GUIA_DESPLIEGUE_CON_LOGS.md) - Guía de despliegue mejorada

---

**Creado por:** GitHub Copilot  
**Fecha:** 2026-02-11  
**Versión:** 1.0
