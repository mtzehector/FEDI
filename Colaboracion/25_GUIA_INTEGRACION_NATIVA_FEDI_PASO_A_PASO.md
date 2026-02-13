# GUÍA OPERATIVA: Integración Nativa de srvAutoregistro en FEDI-WEB
**Versión:** 1.0  
**Fecha:** 2026-02-06  
**Estado:** Plan de Ejecución Week 1  
**Timeline:** 30 horas disponibles  
**Objetivo:** Llevar Option B (Integración Nativa) lo máximo posible en Week 1

---

## 📋 TABLA DE CONTENIDOS

1. [Visión General](#visión-general)
2. [Requisitos Técnicos](#requisitos-técnicos)
3. [Fase 1: Validación de Compatibilidad (Horas 1-5)](#fase-1-validación-de-compatibilidad-horas-1-5)
4. [Fase 2: Preparación de Codebase FEDI (Horas 6-10)](#fase-2-preparación-de-codebase-fedi-horas-6-10)
5. [Fase 3: Implementación de RolesServiceFEDI (Horas 11-20)](#fase-3-implementación-de-rolesservicefedi-horas-11-20)
6. [Fase 4: Integración con AdminUsuariosServiceImpl (Horas 21-25)](#fase-4-integración-con-adminusuariosserviceimpl-horas-21-25)
7. [Fase 5: Testing y Validación (Horas 26-30)](#fase-5-testing-y-validación-horas-26-30)
8. [Código Base Completo](#código-base-completo)
9. [Checklist de Validación](#checklist-de-validación)
10. [Troubleshooting y Plan B](#troubleshooting-y-plan-b)

---

## VISIÓN GENERAL

### Objetivo
Integrar la lógica de `srvAutoregistroPerito` (recuperación y actualización de roles) **directamente en FEDI-WEB** como servicio nativo, eliminando la dependencia externa.

### Arquitectura Actual (IFT)
```
FEDI-WEB (Spring 4.0.0)
    ↓ (API Manager path mapping)
srvAutoregistroPerito (Spring 3.1.4 + Jersey 2.14)
    ↓ (Axis2 SOAP)
WSO2 Identity Server (RemoteUserStoreManager)
```

### Arquitectura Objetivo (CRT)
```
FEDI-WEB (Spring 4.0.0)
    ├─ RolesServiceFEDI (NUEVA - equivalente a RolesServiceImpl)
    │  ├─ Axis2 SOAP client
    │  └─ WSO2 Identity Server (mismo endpoint)
    └─ AdminUsuariosServiceImpl (MODIFICADO - llama a RolesServiceFEDI)
```

### Beneficios
- ✅ Una sola aplicación WAR
- ✅ Código centralizado bajo control FEDI
- ✅ Latencia reducida (sin API Manager)
- ✅ Mantenimiento simplificado
- ✅ Mejor arquitectura a largo plazo

### Riesgos Identificados
- ⚠️ Compatibilidad Axis2 con Spring 4.0 (Nivel: BAJO - Axis2 es agnóstico a Spring)
- ⚠️ Manejo de excepciones SOAP (Nivel: BAJO - bien documentado)
- ⚠️ Timeout de conexión SOAP (Nivel: BAJO - configurable)
- ⚠️ Credenciales WSO2 en propiedades (Nivel: MEDIO - usar environment variables)
- ⚠️ Testing sin acceso real a WSO2 (Nivel: BAJO - mocks suficientes)

---

## REQUISITOS TÉCNICOS

### Herramientas Necesarias
```
✅ Maven 3.6+
✅ Java JDK 8 (compatible con Spring 4.0)
✅ VS Code + Maven extension
✅ Git (para versionado)
✅ Postman o curl (para testing)
```

### Repositorios Maven Necesarios
Ya están configurados en tu `settings.xml`:
```xml
<repository>
    <id>wso2-nexus</id>
    <name>WSO2 Nexus Repository</name>
    <url>https://maven.wso2.org/nexus/content/groups/wso2-public/</url>
</repository>
```

### Dependencias que Necesitarás Agregar a FEDI pom.xml

```xml
<!-- Axis2 para SOAP -->
<dependency>
    <groupId>org.apache.axis2</groupId>
    <artifactId>axis2-kernel</artifactId>
    <version>1.7.9</version>
</dependency>
<dependency>
    <groupId>org.apache.axis2</groupId>
    <artifactId>axis2-transport-http</artifactId>
    <version>1.7.9</version>
</dependency>
<dependency>
    <groupId>org.apache.axis2</groupId>
    <artifactId>axis2-transport-local</artifactId>
    <version>1.7.9</version>
</dependency>

<!-- Stubs generados de WSO2 (copiado de srvAutoregistro) -->
<!-- Se describe abajo cómo generarlos -->

<!-- Apache Commons HTTP (para SSL/TLS) -->
<dependency>
    <groupId>org.apache.httpcomponents</groupId>
    <artifactId>httpclient</artifactId>
    <version>4.5.13</version>
</dependency>
```

### Archivos a Copiar de srvAutoregistroPerito

| Archivo | Origen | Destino | Propósito |
|---------|--------|---------|-----------|
| `RemoteUserStoreManagerServiceStub.java` | `srvAutoregistroPerito/src/main/java/mx/org/ift/mod/seg/scim/service/stubs/` | `fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/stubs/` | Stub Axis2 para WSO2 |
| `RemoteUserStoreManagerServiceCallbackHandler.java` | Mismo origen | Mismo destino | Handler para callbacks |
| `RemoteUserStoreManagerService*.xsd` | Mismo origen | Mismo destino | Schemas XSD |
| `Role.java` (modelo) | `srvAutoregistroPerito/src/main/java/mx/org/ift/mod/seg/scim/model/` | `fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/model/` | Modelo de datos |
| `ResponseMensaje.java` | Mismo origen | Mismo destino | Modelo de respuesta |

---

## FASE 1: Validación de Compatibilidad (Horas 1-5)

### 1.1 Verificar Compatibilidad Axis2 ↔ Spring 4.0 (1 hora)

**Tarea:** Confirmar que Axis2 1.7.9 funciona sin conflictos en Spring 4.0.0

```bash
# Terminal - Navegar a fedi-web
cd c:\github\fedi-web

# Listar dependencias para buscar conflictos
mvn dependency:tree -Doutput=dependency-tree.txt

# Buscar versiones problemáticas de commons-logging, commons-httpclient
mvn dependency:tree | grep -i "logging\|httpclient\|xalan\|xerces"
```

**Validación Esperada:**
- ✅ No hay conflictos de versión de `commons-logging`
- ✅ No hay múltiples versiones de `xmlbeans` o `xalan`
- ✅ Spring 4.0.0 y Axis2 1.7.9 coexisten sin problemas

**Documento de Salida:** `01_VALIDACION_COMPATIBILIDAD.md`
```
## Resultado de Validación Axis2 + Spring 4.0

### Dependencias Críticas Encontradas:
- commons-logging: [version]
- commons-lang: [version]
- xml-apis: [version]

### Conclusión:
✅ COMPATIBLE - No hay conflictos identificados
```

---

### 1.2 Analizar ConfigurationContext en Axis2 (1.5 horas)

**Tarea:** Entender cómo se configura Axis2 en Spring 4.0 context

**Documento a Crear:** `02_ANALISIS_AXIS2_CONFIGURATION.md`

Contenido esperado:
```markdown
## Configuración de Axis2 en Contexto Spring 4.0

### Patrón Actual (srvAutoregistro):
```java
ConfigurationContext configContext = 
    ConfigurationContextFactory.createConfigurationContextFromFileSystem(null, null);
```

### Problemas:
- null, null busca en classpath (puede fallar en Spring)
- Sin bean management de Spring

### Solución Recomendada:
Crear un `@Configuration` bean que instancie ConfigurationContext
una sola vez (singleton pattern) para evitar múltiples contextos.
```

---

### 1.3 Validar Generación de Stubs Axis2 (2.5 horas)

**Tarea:** Generar/copiar y validar stubs de `RemoteUserStoreManager` desde srvAutoregistro

**OPCIÓN A: Copiar stubs existentes (RECOMENDADO - 30 min)**

```bash
# 1. Copiar stubs desde srvAutoregistro
mkdir -p fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/stubs
cp c:\github\srvAutoRegistroPerito\src\main\java\mx\org\ift\mod\seg\scim\service\stubs\RemoteUserStoreManagerService*.java \
   fedi-web\src\main\java\fedi\ift\org\mx\arq\core\service\security\stubs\

# 2. Actualizar package declarations en los stubs copiados
# (IMPORTANTE: cambiar "mx.org.ift.mod.seg.scim.service.stubs" a "fedi.ift.org.mx.arq.core.service.security.stubs")
```

**OPCIÓN B: Generar nuevos stubs con WSDL2Java (2.5 horas)**

```bash
# Si necesitas generar desde WSDL de WSO2:
cd fedi-web

# Obtener WSDL de WSO2 (requerirá credenciales de Daniel)
# Típicamente: https://[WSO2_SERVER]:[PORT]/services/RemoteUserStoreManagerService?wsdl

# Generar stubs (requiere Axis2 client tools)
# download: https://axis.apache.org/axis2/java/core/

# En Windows PowerShell:
$AXIS2_HOME = "C:\tools\axis2-1.7.9"
& "$AXIS2_HOME\bin\wsdl2java.bat" `
  -uri "https://wso2-server:9443/services/RemoteUserStoreManagerService?wsdl" `
  -o "src/main/java" `
  -p "fedi.ift.org.mx.arq.core.service.security.stubs" `
  -s
```

**Validación Esperada:**
- ✅ Archivos .java generados sin errores
- ✅ Package correcto: `fedi.ift.org.mx.arq.core.service.security.stubs`
- ✅ Classes principales presentes:
  - `RemoteUserStoreManagerServiceStub`
  - `RemoteUserStoreManagerServiceCallbackHandler`
  - `RemoteUserStoreManagerService` (interface)

**Documento de Salida:** `03_STUBS_AXIS2_VALIDADOS.md`

---

## FASE 2: Preparación de Codebase FEDI (Horas 6-10)

### 2.1 Crear Estructura de Directorios (30 min)

```bash
# FEDI-WEB - Nuevas carpetas
mkdir -p fedi-web\src\main\java\fedi\ift\org\mx\arq\core\service\security\stubs
mkdir -p fedi-web\src\main\java\fedi\ift\org\mx\arq\core\service\security\model
mkdir -p fedi-web\src\main\java\fedi\ift\org\mx\arq\core\service\security\roles
mkdir -p fedi-web\src\test\java\fedi\ift\org\mx\arq\core\service\security

# Copiar stubs (si no ya lo hiciste)
# Ver Fase 1.3
```

### 2.2 Copiar Modelos de Datos (1 hora)

**Archivos a copiar desde srvAutoregistroPerito:**

```
srvAutoregistroPerito/src/main/java/mx/org/ift/mod/seg/scim/model/
├── Role.java
├── ResponseMensaje.java
├── ResponseRoles.java
└── DatosRoles.java
```

**Destino:**
```
fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/model/
```

**Actualizar Package Declarations:**

```bash
# En Windows PowerShell - actualizar packages en los archivos copiados:
(Get-Content "fedi-web\src\main\java\fedi\ift\org\mx\arq\core\service\security\model\Role.java") `
  -replace "package mx\.org\.ift\.mod\.seg\.scim\.model;", "package fedi.ift.org.mx.arq.core.service.security.model;" | `
  Set-Content "fedi-web\src\main\java\fedi\ift\org\mx\arq\core\service\security\model\Role.java"

# Repetir para ResponseMensaje.java, ResponseRoles.java, DatosRoles.java
```

**Validación:**
- ✅ Archivos compilables sin errores
- ✅ Package correcto en cada archivo

### 2.3 Actualizar pom.xml de FEDI (1.5 horas)

**Modificar:** `fedi-web/pom.xml`

**Agregar dependencias Axis2 en sección `<dependencies>`:**

```xml
<!-- AXIS2 SOAP INTEGRATION -->
<dependency>
    <groupId>org.apache.axis2</groupId>
    <artifactId>axis2-kernel</artifactId>
    <version>1.7.9</version>
    <exclusions>
        <exclusion>
            <groupId>commons-logging</groupId>
            <artifactId>commons-logging</artifactId>
        </exclusion>
    </exclusions>
</dependency>
<dependency>
    <groupId>org.apache.axis2</groupId>
    <artifactId>axis2-transport-http</artifactId>
    <version>1.7.9</version>
</dependency>
<dependency>
    <groupId>org.apache.axis2</groupId>
    <artifactId>axis2-transport-local</artifactId>
    <version>1.7.9</version>
</dependency>
<dependency>
    <groupId>org.apache.neethi</groupId>
    <artifactId>neethi</artifactId>
    <version>3.1.1</version>
</dependency>
<dependency>
    <groupId>org.apache.woden</groupId>
    <artifactId>woden-core</artifactId>
    <version>1.0M10</version>
</dependency>
<dependency>
    <groupId>org.apache.httpcomponents</groupId>
    <artifactId>httpclient</artifactId>
    <version>4.5.13</version>
</dependency>
```

**Compilación y Validación:**

```bash
cd fedi-web
mvn clean install -DskipTests

# Esperado: BUILD SUCCESS
# Si hay errores de dependencias, revisar:
# - WSO2 repository disponible en settings.xml ✅
# - No hay versiones conflictivas
```

### 2.4 Crear Properties File para Credenciales (1 hora)

**Crear archivo:** `fedi-web/src/main/resources/security-roles.properties`

```properties
# WSO2 Identity Server Configuration
# DEVELOPMENT (environment-specific, se sobrescribe por perfil Maven)
wso2.identity-server.url=http://localhost:9443
wso2.identity-server.service.endpoint=/services/RemoteUserStoreManagerService

# LDAP Service Account Credentials (IMPORTANTE: usar variables de environment en producción)
wso2.ldap.username=peritos_svc
wso2.ldap.password=${LDAP_PASSWORD_PERITOS}

# Extended Peritos Account (para usuarios EXT)
wso2.ldap.username.ext=peritos_ext_svc
wso2.ldap.password.ext=${LDAP_PASSWORD_PERITOS_EXT}

# Timeouts y configuración
wso2.ldap.connection.timeout=30000
wso2.ldap.read.timeout=30000
wso2.ldap.cache.enabled=true
wso2.ldap.cache.ttl=300000

# Almacenes (prefijos para filtrar roles)
peritos.almacen.principal=0015MSPERITOSDES-INT
peritos.almacen.simca=0015SIMCADES-INT
```

**Crear versiones por perfil Maven:**

- `fedi-web/src/main/resources/security-roles-development-oracle1.properties`
- `fedi-web/src/main/resources/security-roles-qa-oracle1.properties`
- `fedi-web/src/main/resources/security-roles-production.properties`

Cada una con URLs y credenciales específicas del ambiente.

**Integración en pom.xml:**

```xml
<profiles>
    <profile>
        <id>development-oracle1</id>
        <build>
            <plugins>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-resource-plugin</artifactId>
                    <executions>
                        <execution>
                            <id>copy-security-roles</id>
                            <phase>process-resources</phase>
                            <goals>
                                <goal>copy-resources</goal>
                            </goals>
                            <configuration>
                                <outputDirectory>${project.build.outputDirectory}</outputDirectory>
                                <resources>
                                    <resource>
                                        <directory>src/main/resources</directory>
                                        <includes>
                                            <include>security-roles-development-oracle1.properties</include>
                                        </includes>
                                        <targetPath>.</targetPath>
                                        <filtering>true</filtering>
                                    </resource>
                                </resources>
                            </configuration>
                        </execution>
                    </executions>
                </plugin>
            </plugins>
        </build>
    </profile>
</profiles>
```

**Validación:**
- ✅ Archivo compilable
- ✅ Propiedades accesibles desde Spring context

---

## FASE 3: Implementación de RolesServiceFEDI (Horas 11-20)

### 3.1 Crear Clase Axis2ConfigurationService (2 horas)

**Archivo:** `fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/roles/Axis2ConfigurationService.java`

```java
package fedi.ift.org.mx.arq.core.service.security.roles;

import org.apache.axis2.addressing.EndpointReference;
import org.apache.axis2.client.Options;
import org.apache.axis2.context.ConfigurationContext;
import org.apache.axis2.context.ConfigurationContextFactory;
import org.apache.axis2.transport.http.HTTPConstants;
import org.apache.axis2.transport.http.HttpTransportProperties;
import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.protocol.Protocol;
import org.apache.commons.httpclient.protocol.ProtocolSocketFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.net.ssl.SSLContext;
import java.io.IOException;

/**
 * Singleton Service que gestiona la ConfigurationContext de Axis2
 * Previene múltiples instancias y maneja SSL/TLS correctamente
 */
@Service
public class Axis2ConfigurationService {
    
    private static final Logger LOGGER = LoggerFactory.getLogger(Axis2ConfigurationService.class);
    
    @Value("${wso2.ldap.connection.timeout:30000}")
    private int connectionTimeout;
    
    @Value("${wso2.ldap.read.timeout:30000}")
    private int readTimeout;
    
    private ConfigurationContext configurationContext;
    private Object configLock = new Object();
    
    /**
     * Obtiene o crea la ConfigurationContext de Axis2 (lazy initialization)
     * Thread-safe singleton pattern
     */
    public ConfigurationContext getConfigurationContext() {
        if (configurationContext == null) {
            synchronized (configLock) {
                if (configurationContext == null) {
                    try {
                        configurationContext = ConfigurationContextFactory
                            .createConfigurationContextFromFileSystem(null, null);
                        
                        LOGGER.info("Axis2 ConfigurationContext initialized successfully");
                    } catch (Exception e) {
                        LOGGER.error("Failed to initialize Axis2 ConfigurationContext", e);
                        throw new RuntimeException("Cannot initialize Axis2 configuration", e);
                    }
                }
            }
        }
        return configurationContext;
    }
    
    /**
     * Configura opciones HTTP para el cliente SOAP
     * Incluye autenticación básica, timeouts, y SSL/TLS
     */
    public void configureHttpOptions(Options options, String username, String password) {
        
        // Crear autenticador básico
        HttpTransportProperties.Authenticator authenticator = 
            new HttpTransportProperties.Authenticator();
        authenticator.setUsername(username);
        authenticator.setPassword(password);
        authenticator.setPreemptiveAuthentication(true);
        
        // Aplicar autenticador
        options.setProperty(
            org.apache.axis2.transport.http.HTTPConstants.AUTHENTICATE, 
            authenticator
        );
        
        // Configurar timeouts
        options.setTimeOutInMilliSeconds(readTimeout);
        options.setProperty(HTTPConstants.SO_TIMEOUT, readTimeout);
        options.setProperty(HTTPConstants.CONNECTION_TIMEOUT, connectionTimeout);
        
        // Deshabilitar validación de certificado para desarrollo (CAMBIAR EN PRODUCCIÓN)
        options.setProperty(
            HTTPConstants.CUSTOM_PROTOCOL_HANDLER, 
            Protocol.getProtocol("https")
        );
    }
    
    /**
     * Limpia recursos (llamado en shutdown)
     */
    public void cleanup() {
        if (configurationContext != null) {
            try {
                configurationContext.terminate();
                LOGGER.info("Axis2 ConfigurationContext terminated");
            } catch (Exception e) {
                LOGGER.warn("Error terminating ConfigurationContext", e);
            }
        }
    }
}
```

---

### 3.2 Crear Clase RolesServiceFEDI (5 horas)

**Archivo:** `fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/roles/RolesServiceFEDI.java`

```java
package fedi.ift.org.mx.arq.core.service.security.roles;

import fedi.ift.org.mx.arq.core.service.security.model.*;
import fedi.ift.org.mx.arq.core.service.security.stubs.*;
import org.apache.axis2.addressing.EndpointReference;
import org.apache.axis2.client.Options;
import org.apache.axis2.client.ServiceClient;
import org.apache.axis2.context.ConfigurationContext;
import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.rmi.RemoteException;
import java.util.*;

/**
 * Servicio nativo FEDI para operaciones de Roles
 * Equivalente a RolesServiceImpl de srvAutoregistroPerito
 * Integra directamente con WSO2 Identity Server via Axis2 SOAP
 */
@Service("rolesServiceFEDI")
public class RolesServiceFEDI {
    
    private static final Logger LOGGER = LoggerFactory.getLogger(RolesServiceFEDI.class);
    
    @Autowired
    private Axis2ConfigurationService axis2Config;
    
    @Value("${wso2.identity-server.url:http://localhost:9443}")
    private String wso2BaseUrl;
    
    @Value("${wso2.identity-server.service.endpoint:/services/RemoteUserStoreManagerService}")
    private String serviceEndpoint;
    
    @Value("${wso2.ldap.username}")
    private String ldapUsername;
    
    @Value("${wso2.ldap.password}")
    private String ldapPassword;
    
    @Value("${wso2.ldap.username.ext:#{null}}")
    private String ldapUsernameExt;
    
    @Value("${wso2.ldap.password.ext:#{null}}")
    private String ldapPasswordExt;
    
    @Value("${peritos.almacen.principal}")
    private String almacenPrincipal;
    
    @Value("${peritos.almacen.simca:#{null}}")
    private String almacenSimca;
    
    @Value("${wso2.ldap.cache.enabled:true}")
    private boolean cacheEnabled;
    
    @Value("${wso2.ldap.cache.ttl:300000}")
    private long cacheTtl;
    
    /**
     * OPERACION 1: Recupera lista de roles, usuarios, o mapeos
     * 
     * @param tipo 1=Validar usuario, 2=Obtener todos los roles, 3=Roles del usuario, 4=Usuarios del rol
     * @param filtro Parámetro de búsqueda (usuario, rol, etc.)
     * @param almacen Prefijo para filtrar resultados (ej: "0015MSPERITOSDES-INT")
     * @return List<Role> con los datos solicitados
     */
    public List<Role> recuperaLista(int tipo, String filtro, String almacen) throws Exception {
        List<Role> resultado = new ArrayList<>();
        String logPrefix = String.format("[ROLES-OP%d] ", tipo);
        
        try {
            LOGGER.info("{}Iniciando recuperaLista: tipo={}, filtro={}, almacen={}", 
                logPrefix, tipo, filtro, almacen);
            
            RemoteUserStoreManagerServiceStub stub = createStub(almacen);
            
            switch (tipo) {
                case 1:
                    // Validar que usuario existe
                    resultado = recuperaUsuario(stub, filtro, almacen);
                    break;
                    
                case 2:
                    // Obtener lista de TODOS los roles
                    resultado = recuperaRoles(stub, almacen);
                    break;
                    
                case 3:
                    // Obtener roles de un usuario específico
                    resultado = recuperaRolesDelUsuario(stub, filtro, almacen);
                    break;
                    
                case 4:
                    // Obtener usuarios que tienen un rol específico
                    resultado = recuperaUsuariosDelRol(stub, filtro, almacen);
                    break;
                    
                default:
                    LOGGER.warn("{}Tipo de operación desconocida: {}", logPrefix, tipo);
                    throw new IllegalArgumentException("Tipo de operación no válido: " + tipo);
            }
            
            LOGGER.info("{}Operación completada exitosamente. Registros retornados: {}", 
                logPrefix, resultado.size());
            
        } catch (RemoteException e) {
            LOGGER.error("{}Error en comunicación SOAP con WSO2", logPrefix, e);
            throw new Exception("Error comunicando con Identity Server: " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.error("{}Error inesperado en recuperaLista", logPrefix, e);
            throw e;
        }
        
        return resultado;
    }
    
    /**
     * OPERACION 2: Actualiza roles de un usuario
     * 
     * @param userName Usuario a actualizar
     * @param rolesBorrar Array de roles a remover
     * @param rolesAgregar Array de roles a agregar
     * @return ResponseMensaje con resultado de la operación
     */
    public ResponseMensaje administraRol(String userName, String[] rolesBorrar, String[] rolesAgregar) {
        ResponseMensaje respuesta = new ResponseMensaje();
        respuesta.setCode(102); // Default: éxito
        respuesta.setMensaje("Operación completada exitosamente");
        
        String logPrefix = "[ROLES-UPDATE] ";
        
        try {
            LOGGER.info("{}Actualizando roles de usuario: {}", logPrefix, userName);
            LOGGER.debug("{}Roles a borrar: {}", logPrefix, Arrays.toString(rolesBorrar));
            LOGGER.debug("{}Roles a agregar: {}", logPrefix, Arrays.toString(rolesAgregar));
            
            RemoteUserStoreManagerServiceStub stub = createStub(almacenPrincipal);
            
            // Llamada SOAP a WSO2: actualizar lista de roles del usuario
            stub.updateRoleListOfUser(userName, rolesBorrar, rolesAgregar);
            
            LOGGER.info("{}Roles actualizados correctamente para usuario: {}", logPrefix, userName);
            
        } catch (RemoteException e) {
            LOGGER.error("{}Error SOAP al actualizar roles", logPrefix, e);
            respuesta.setCode(101); // Error
            respuesta.setMensaje("Error al actualizar roles: " + e.getMessage());
            respuesta.setError("SOAP_REMOTE_ERROR");
            
        } catch (Exception e) {
            LOGGER.error("{}Error inesperado", logPrefix, e);
            respuesta.setCode(101);
            respuesta.setMensaje("Error inesperado: " + e.getMessage());
            respuesta.setError("UNKNOWN_ERROR");
        }
        
        return respuesta;
    }
    
    /**
     * OPERACION ADICIONAL: Validar usuario existe en WSO2
     */
    private List<Role> recuperaUsuario(RemoteUserStoreManagerServiceStub stub, 
                                       String usuario, String almacen) throws RemoteException {
        List<Role> resultado = new ArrayList<>();
        
        try {
            String[] usuarios = stub.listUsers(usuario, 100);
            
            if (usuarios != null && usuarios.length > 0) {
                for (String user : usuarios) {
                    if (user.startsWith(almacen)) {
                        Role role = new Role();
                        role.setDisplayName(user);
                        role.setName(user);
                        resultado.add(role);
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.error("[ROLES-OP1] Error validando usuario", e);
            throw e;
        }
        
        return resultado;
    }
    
    /**
     * OPERACION ADICIONAL: Obtener todos los roles
     */
    @Cacheable(value = "rolesCache", condition = "@axis2ConfigurationService.isCacheEnabled()", 
               unless = "#result == null or #result.isEmpty()")
    private List<Role> recuperaRoles(RemoteUserStoreManagerServiceStub stub, 
                                     String almacen) throws RemoteException {
        List<Role> resultado = new ArrayList<>();
        
        try {
            String[] roles = stub.getRoleNames();
            
            if (roles != null) {
                for (String roleName : roles) {
                    if (roleName.startsWith(almacen)) {
                        Role role = new Role();
                        role.setDisplayName(roleName);
                        role.setName(roleName);
                        resultado.add(role);
                    }
                }
            }
            
            // Ordenar por nombre
            resultado.sort(Comparator.comparing(Role::getName));
            
        } catch (Exception e) {
            LOGGER.error("[ROLES-OP2] Error obteniendo roles", e);
            throw e;
        }
        
        return resultado;
    }
    
    /**
     * OPERACION ADICIONAL: Obtener roles de un usuario específico
     */
    private List<Role> recuperaRolesDelUsuario(RemoteUserStoreManagerServiceStub stub,
                                               String usuario, String almacen) throws RemoteException {
        List<Role> resultado = new ArrayList<>();
        
        try {
            String[] roles = stub.getRoleListOfUser(usuario);
            
            if (roles != null) {
                for (String roleName : roles) {
                    if (roleName.startsWith(almacen)) {
                        Role role = new Role();
                        role.setDisplayName(roleName);
                        role.setName(roleName);
                        resultado.add(role);
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.error("[ROLES-OP3] Error obteniendo roles del usuario", e);
            throw e;
        }
        
        return resultado;
    }
    
    /**
     * OPERACION ADICIONAL: Obtener usuarios de un rol específico
     */
    private List<Role> recuperaUsuariosDelRol(RemoteUserStoreManagerServiceStub stub,
                                              String rol, String almacen) throws RemoteException {
        List<Role> resultado = new ArrayList<>();
        
        try {
            String[] usuarios = stub.getUserListOfRole(rol);
            
            if (usuarios != null) {
                for (String usuario : usuarios) {
                    if (usuario.startsWith(almacen)) {
                        Role role = new Role();
                        role.setDisplayName(usuario);
                        role.setName(usuario);
                        resultado.add(role);
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.error("[ROLES-OP4] Error obteniendo usuarios del rol", e);
            throw e;
        }
        
        return resultado;
    }
    
    /**
     * Crea instancia de RemoteUserStoreManagerServiceStub
     * Configura autenticación, timeouts, SSL/TLS
     */
    private RemoteUserStoreManagerServiceStub createStub(String almacen) throws Exception {
        try {
            // Obtener ConfigurationContext
            ConfigurationContext configContext = axis2Config.getConfigurationContext();
            
            // Determinar credenciales (usar EXT si es para SIMCA)
            String username = ldapUsername;
            String password = ldapPassword;
            
            if (StringUtils.isNotEmpty(almacenSimca) && almacen.equals(almacenSimca)) {
                if (StringUtils.isNotEmpty(ldapUsernameExt)) {
                    username = ldapUsernameExt;
                    password = ldapPasswordExt;
                }
            }
            
            // Crear URL del servicio
            String serviceUrl = wso2BaseUrl + serviceEndpoint;
            EndpointReference epr = new EndpointReference(serviceUrl);
            
            // Crear stub
            RemoteUserStoreManagerServiceStub stub = 
                new RemoteUserStoreManagerServiceStub(configContext, epr);
            
            // Configurar opciones HTTP (autenticación, timeouts)
            Options options = stub._getServiceClient().getOptions();
            axis2Config.configureHttpOptions(options, username, password);
            
            LOGGER.debug("Stub creado para servicio: {}", serviceUrl);
            
            return stub;
            
        } catch (Exception e) {
            LOGGER.error("Error creando RemoteUserStoreManagerServiceStub", e);
            throw new Exception("Cannot create SOAP stub for WSO2 RemoteUserStoreManager", e);
        }
    }
}
```

---

### 3.3 Crear Modelos de Datos (2 horas)

**Archivo:** `fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/model/Role.java`

```java
package fedi.ift.org.mx.arq.core.service.security.model;

import java.io.Serializable;

public class Role implements Serializable {
    private static final long serialVersionUID = 1L;
    
    private String name;
    private String displayName;
    private String description;
    private String type;
    
    public Role() {}
    
    public Role(String name, String displayName) {
        this.name = name;
        this.displayName = displayName;
    }
    
    // Getters y Setters
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public String getDisplayName() {
        return displayName;
    }
    
    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public String getType() {
        return type;
    }
    
    public void setType(String type) {
        this.type = type;
    }
    
    @Override
    public String toString() {
        return "Role{" +
                "name='" + name + '\'' +
                ", displayName='" + displayName + '\'' +
                ", type='" + type + '\'' +
                '}';
    }
}
```

**Archivo:** `fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/model/ResponseMensaje.java`

```java
package fedi.ift.org.mx.arq.core.service.security.model;

import java.io.Serializable;

public class ResponseMensaje implements Serializable {
    private static final long serialVersionUID = 1L;
    
    private int code;          // 102 = éxito, 101 = error
    private String mensaje;
    private String error;
    
    public ResponseMensaje() {}
    
    public ResponseMensaje(int code, String mensaje) {
        this.code = code;
        this.mensaje = mensaje;
    }
    
    // Getters y Setters
    public int getCode() {
        return code;
    }
    
    public void setCode(int code) {
        this.code = code;
    }
    
    public String getMensaje() {
        return mensaje;
    }
    
    public void setMensaje(String mensaje) {
        this.mensaje = mensaje;
    }
    
    public String getError() {
        return error;
    }
    
    public void setError(String error) {
        this.error = error;
    }
    
    @Override
    public String toString() {
        return "ResponseMensaje{" +
                "code=" + code +
                ", mensaje='" + mensaje + '\'' +
                ", error='" + error + '\'' +
                '}';
    }
}
```

---

### 3.4 Crear Excepciones Personalizadas (1 hora)

**Archivo:** `fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/roles/RolesServiceException.java`

```java
package fedi.ift.org.mx.arq.core.service.security.roles;

public class RolesServiceException extends RuntimeException {
    
    private String errorCode;
    
    public RolesServiceException(String message) {
        super(message);
        this.errorCode = "UNKNOWN_ERROR";
    }
    
    public RolesServiceException(String message, Throwable cause) {
        super(message, cause);
        this.errorCode = "UNKNOWN_ERROR";
    }
    
    public RolesServiceException(String errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }
    
    public RolesServiceException(String errorCode, String message, Throwable cause) {
        super(message, cause);
        this.errorCode = errorCode;
    }
    
    public String getErrorCode() {
        return errorCode;
    }
}
```

---

## FASE 4: Integración con AdminUsuariosServiceImpl (Horas 21-25)

### 4.1 Análisis de AdminUsuariosServiceImpl Actual (1 hora)

**Archivo a analizar:** `fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/AdminUsuariosServiceImpl.java`

**Documento:** `04_ANALISIS_ADMIN_USUARIOS_ACTUAL.md`

Identificar:
- ✅ Dónde se llama a srvAutoregistro
- ✅ Métodos que necesitan refactoring
- ✅ Points de inyección del RolesServiceFEDI

```bash
# Buscar referencias a srvAutoregistro
grep -n "srvAutoregistro\|MDSeguridadService\|registro/consultas/roles" \
  fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/AdminUsuariosServiceImpl.java
```

---

### 4.2 Refactoring de AdminUsuariosServiceImpl (3 horas)

**Cambios principales:**

1. **Inyectar RolesServiceFEDI:**

```java
// ANTES
private MDSeguridadService mdSeguridadService;

// DESPUÉS
@Autowired
private RolesServiceFEDI rolesServiceFEDI;

// Mantener mdSeguridadService para otras funcionalidades no relacionadas con roles
```

2. **Reemplazar llamadas a srvAutoregistro:**

```java
// ANTES (ejemplo)
String metodo = "registro/consultas/roles/2/1/" + sistemaId;
ResponseWS respuesta = mdSeguridadService.ejecutarServicio(metodo);

// DESPUÉS
try {
    List<Role> roles = rolesServiceFEDI.recuperaLista(2, "1", almacenPrincipal);
    // Convertir List<Role> a formato esperado por UI
    respuesta = convertirRolesToResponseWS(roles);
} catch (Exception e) {
    LOGGER.error("Error obteniendo roles", e);
    // Manejar error
}
```

3. **Crear métodos helper para conversión:**

```java
private ResponseWS convertirRolesToResponseWS(List<Role> roles) {
    ResponseWS respuesta = new ResponseWS();
    respuesta.setCode(102);
    respuesta.setData(roles.stream()
        .map(r -> new RoleDTO(r.getName(), r.getDisplayName()))
        .collect(Collectors.toList()));
    return respuesta;
}
```

4. **Refactoring de métodos específicos:**

```java
public List<Role> obtenerRoles() throws Exception {
    // Obtener TODOS los roles (tipo 2)
    return rolesServiceFEDI.recuperaLista(2, "", almacenPrincipal);
}

public List<String> obtenerUsuariosDelRol(String rol) throws Exception {
    // Obtener usuarios de un rol (tipo 4)
    List<Role> usuarios = rolesServiceFEDI.recuperaLista(4, rol, almacenPrincipal);
    return usuarios.stream()
        .map(Role::getName)
        .collect(Collectors.toList());
}

public void actualizarPermisosUsuario(String usuario, String[] rolesAgregar, String[] rolesBorrar) throws Exception {
    ResponseMensaje respuesta = rolesServiceFEDI.administraRol(usuario, rolesBorrar, rolesAgregar);
    if (respuesta.getCode() != 102) {
        throw new RolesServiceException(respuesta.getError(), respuesta.getMensaje());
    }
}
```

---

### 4.3 Actualizar Configuración Spring (1 hora)

**Crear/modificar:** `fedi-web/src/main/resources/spring/spring-security-roles.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans 
       http://www.springframework.org/schema/beans/spring-beans.xsd">
    
    <!-- Cargar propiedades de roles -->
    <bean class="org.springframework.beans.factory.config.PropertyPlaceholderConfigurer">
        <property name="locations">
            <list>
                <value>classpath:security-roles.properties</value>
            </list>
        </property>
    </bean>
    
    <!-- Axis2 Configuration Service (singleton) -->
    <bean id="axis2ConfigurationService" 
          class="fedi.ift.org.mx.arq.core.service.security.roles.Axis2ConfigurationService"/>
    
    <!-- Roles Service FEDI -->
    <bean id="rolesServiceFEDI"
          class="fedi.ift.org.mx.arq.core.service.security.roles.RolesServiceFEDI">
        <property name="axis2Config" ref="axis2ConfigurationService"/>
    </bean>
    
    <!-- Cache Manager para roles (opcional pero recomendado) -->
    <bean id="cacheManager" class="org.springframework.cache.concurrent.ConcurrentMapCacheManager">
        <constructor-arg>
            <list>
                <value>rolesCache</value>
            </list>
        </constructor-arg>
    </bean>
    
</beans>
```

**Incluir en applicationContext.xml principal:**

```xml
<!-- En fedi-web/src/main/resources/applicationContext.xml -->
<import resource="spring/spring-security-roles.xml"/>
```

---

## FASE 5: Testing y Validación (Horas 26-30)

### 5.1 Crear Test Unitarios (2 horas)

**Archivo:** `fedi-web/src/test/java/fedi/ift/org/mx/arq/core/service/security/RolesServiceFEDITest.java`

```java
package fedi.ift.org.mx.arq.core.service.security;

import fedi.ift.org.mx.arq.core.service.security.model.Role;
import fedi.ift.org.mx.arq.core.service.security.model.ResponseMensaje;
import fedi.ift.org.mx.arq.core.service.security.roles.Axis2ConfigurationService;
import fedi.ift.org.mx.arq.core.service.security.roles.RolesServiceFEDI;
import fedi.ift.org.mx.arq.core.service.security.stubs.RemoteUserStoreManagerServiceStub;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.class)
public class RolesServiceFEDITest {
    
    @Mock
    private Axis2ConfigurationService axis2ConfigService;
    
    @InjectMocks
    private RolesServiceFEDI rolesServiceFEDI;
    
    @Before
    public void setup() {
        // Inyectar propiedades usando Reflection
        ReflectionTestUtils.setField(rolesServiceFEDI, "wso2BaseUrl", "http://localhost:9443");
        ReflectionTestUtils.setField(rolesServiceFEDI, "serviceEndpoint", "/services/RemoteUserStoreManagerService");
        ReflectionTestUtils.setField(rolesServiceFEDI, "ldapUsername", "admin");
        ReflectionTestUtils.setField(rolesServiceFEDI, "ldapPassword", "admin");
        ReflectionTestUtils.setField(rolesServiceFEDI, "almacenPrincipal", "0015MSPERITOSDES-INT");
    }
    
    @Test
    public void testRecuperaListaRoles() throws Exception {
        // Arrange
        List<Role> expectedRoles = createMockRoles();
        
        // Act
        // List<Role> actual = rolesServiceFEDI.recuperaLista(2, "", almacenPrincipal);
        
        // Assert
        // assertEquals(expectedRoles.size(), actual.size());
        
        // Nota: Para testing completo, necesitas mocks de RemoteUserStoreManagerServiceStub
    }
    
    @Test
    public void testAdministraRol_Success() throws Exception {
        // Arrange
        String usuario = "PERITO001";
        String[] rolesAgregar = {"0015MSPERITOSDES-INT_REVISOR"};
        String[] rolesBorrar = {};
        
        // Act
        // ResponseMensaje respuesta = rolesServiceFEDI.administraRol(usuario, rolesBorrar, rolesAgregar);
        
        // Assert
        // assertEquals(102, respuesta.getCode());
    }
    
    private List<Role> createMockRoles() {
        List<Role> roles = new ArrayList<>();
        roles.add(new Role("0015MSPERITOSDES-INT_ADMIN", "Administrador"));
        roles.add(new Role("0015MSPERITOSDES-INT_REVISOR", "Revisor"));
        return roles;
    }
}
```

---

### 5.2 Testing Manual (2 horas)

**Checklist de Testing:**

```bash
# 1. Compilar el proyecto
cd fedi-web
mvn clean install -DskipTests
# Esperado: BUILD SUCCESS

# 2. Iniciar aplicación en ambiente de desarrollo
# (en el IDE o terminal)

# 3. Testing de endpoints con curl
curl -X GET "http://localhost:8080/fedi/admin/roles?tipo=2&almacen=0015MSPERITOSDES-INT" \
     -H "Authorization: Bearer [token]"
     
# Respuesta esperada:
# {
#   "code": 102,
#   "data": [
#     {"name": "0015MSPERITOSDES-INT_ADMIN", "displayName": "Administrador"},
#     {"name": "0015MSPERITOSDES-INT_REVISOR", "displayName": "Revisor"}
#   ]
# }

# 4. Testing de actualización de roles
curl -X POST "http://localhost:8080/fedi/admin/usuarios/PERITO001/roles" \
     -H "Authorization: Bearer [token]" \
     -H "Content-Type: application/json" \
     -d '{
       "rolesAgregar": ["0015MSPERITOSDES-INT_REVISOR"],
       "rolesBorrar": []
     }'

# Respuesta esperada:
# {
#   "code": 102,
#   "mensaje": "Operación completada exitosamente"
# }
```

**Documento de Validación:** `05_TEST_MANUAL_RESULTADOS.md`

---

### 5.3 Validación de Performance (0.5 horas)

**Monitoreo:**

```
Métrica | Objetivo | Actual
--------|----------|--------
Latencia GET roles | < 100ms | ___ms
Latencia POST roles | < 150ms | ___ms
Conexiones SOAP abiertas | < 3 simultáneas | ___
Memory leak (Axis2) | Ninguno | ✓/✗
Cache hit rate | > 70% | ___%
```

---

### 5.4 Documentación Final (0.5 horas)

**Crear:** `06_MIGRACION_COMPLETADA_OPCION_B.md`

```markdown
# Migración Opción B Completada

## Resumen
- ✅ RolesServiceFEDI implementado (160 líneas)
- ✅ Axis2ConfigurationService configurado
- ✅ AdminUsuariosServiceImpl refactorizado
- ✅ Tests unitarios creados
- ✅ Testing manual completado
- ✅ Performance validado

## Archivos Modificados
- fedi-web/pom.xml (dependencias Axis2)
- fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/AdminUsuariosServiceImpl.java
- fedi-web/src/main/resources/applicationContext.xml

## Archivos Nuevos
- fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/roles/RolesServiceFEDI.java
- fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/roles/Axis2ConfigurationService.java
- fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/model/Role.java
- fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/model/ResponseMensaje.java
- fedi-web/src/main/resources/security-roles.properties
- fedi-web/src/test/java/fedi/ift/org/mx/arq/core/service/security/RolesServiceFEDITest.java

## Próximo Paso
Requiere credenciales de WSO2 CRT de Daniel Mijangos para finalizar configuración.
```

---

## CÓDIGO BASE COMPLETO

### Estructura Final del Proyecto

```
fedi-web/
├── src/main/java/fedi/ift/org/mx/arq/core/service/security/
│   ├── AdminUsuariosServiceImpl.java (MODIFICADO)
│   ├── roles/
│   │   ├── RolesServiceFEDI.java (NUEVO)
│   │   ├── Axis2ConfigurationService.java (NUEVO)
│   │   └── RolesServiceException.java (NUEVO)
│   ├── stubs/
│   │   ├── RemoteUserStoreManagerServiceStub.java (COPIADO)
│   │   ├── RemoteUserStoreManagerServiceCallbackHandler.java (COPIADO)
│   │   └── RemoteUserStoreManagerService.xsd (COPIADO)
│   └── model/
│       ├── Role.java (NUEVO)
│       ├── ResponseMensaje.java (NUEVO)
│       └── (otros modelos)
├── src/main/resources/
│   ├── security-roles.properties (NUEVO)
│   ├── security-roles-development-oracle1.properties (NUEVO)
│   ├── security-roles-qa-oracle1.properties (NUEVO)
│   ├── security-roles-production.properties (NUEVO)
│   ├── spring/
│   │   └── spring-security-roles.xml (NUEVO)
│   └── applicationContext.xml (MODIFICADO)
├── src/test/java/fedi/ift/org/mx/arq/core/service/security/
│   └── RolesServiceFEDITest.java (NUEVO)
└── pom.xml (MODIFICADO)
```

---

## CHECKLIST DE VALIDACIÓN

### Pre-Desarrollo
- [ ] Requisitos técnicos instalados (Maven 3.6+, Java JDK 8)
- [ ] Repositorio WSO2 disponible en settings.xml ✅
- [ ] Acceso a srvAutoRegistroPerito para copiar stubs
- [ ] Acceso a GitLab/GitHub para commitar cambios

### Fase 1: Validación (Horas 1-5)
- [ ] Axis2 1.7.9 compatible con Spring 4.0.0 (no conflictos)
- [ ] Documento 01_VALIDACION_COMPATIBILIDAD.md creado
- [ ] Documento 02_ANALISIS_AXIS2_CONFIGURATION.md creado
- [ ] Stubs Axis2 copiados/generados y validados
- [ ] Documento 03_STUBS_AXIS2_VALIDADOS.md creado

### Fase 2: Preparación (Horas 6-10)
- [ ] Directorio `stubs/` creado en FEDI-WEB
- [ ] Directorio `model/` creado en FEDI-WEB
- [ ] Directorio `roles/` creado en FEDI-WEB
- [ ] Modelos copiados (Role.java, ResponseMensaje.java, etc.)
- [ ] Package declarations actualizados
- [ ] Dependencias Axis2 agregadas a pom.xml
- [ ] pom.xml compila sin errores (`mvn clean install -DskipTests`)
- [ ] Properties files creados (security-roles.properties)
- [ ] Perfiles Maven configurados (development, qa, production)

### Fase 3: Implementación (Horas 11-20)
- [ ] Axis2ConfigurationService.java implementado
- [ ] RolesServiceFEDI.java implementado completamente
- [ ] RolesServiceException.java creado
- [ ] Modelos Role.java, ResponseMensaje.java completos
- [ ] Todas las clases compilables sin errores
- [ ] Documentación de código (Javadoc) completa

### Fase 4: Integración (Horas 21-25)
- [ ] AdminUsuariosServiceImpl.java analizado
- [ ] RolesServiceFEDI inyectado en AdminUsuariosServiceImpl
- [ ] Métodos refactorizados (obtenerRoles, obtenerUsuarios, etc.)
- [ ] Conversores de datos creados
- [ ] spring-security-roles.xml creado
- [ ] Incluido en applicationContext.xml principal
- [ ] Proyecto compila (`mvn clean install`)

### Fase 5: Testing (Horas 26-30)
- [ ] RolesServiceFEDITest.java creado
- [ ] Tests ejecutan sin fallos (`mvn test`)
- [ ] Testing manual completado (curl commands exitosos)
- [ ] Performance dentro de límites (latencia < 150ms)
- [ ] Documentación final creada (06_MIGRACION_COMPLETADA_OPCION_B.md)
- [ ] Changelog generado con todos los cambios

### Post-Implementación
- [ ] Código commiteado a Git
- [ ] Code review realizado
- [ ] Plan de rollback documentado
- [ ] Credenciales WSO2 CRT obtenidas de Daniel

---

## TROUBLESHOOTING Y PLAN B

### Error: "Cannot find RemoteUserStoreManagerServiceStub"

**Causa:** Stubs no copiados o package incorrecto

**Solución:**
```bash
# 1. Verificar que stubs están en el lugar correcto
ls fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/stubs/

# 2. Verificar package declaration en los archivos
grep "package" fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/stubs/RemoteUserStoreManagerServiceStub.java

# 3. Si está incorrecto, actualizar
sed -i 's/mx.org.ift.mod.seg.scim.service.stubs/fedi.ift.org.mx.arq.core.service.security.stubs/g' \
  fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/stubs/*.java
```

### Error: "Axis2 ConfigurationContextFactory exception"

**Causa:** Ruta de archivo XML de configuración incorrecta

**Solución:**
```java
// En Axis2ConfigurationService.java, cambiar:
configurationContext = ConfigurationContextFactory
    .createConfigurationContextFromFileSystem(null, null);

// Por:
configurationContext = ConfigurationContextFactory
    .createConfigurationContextFromFileSystem(
        "src/main/resources/axis2",  // Carpeta con axis2.xml
        null
    );
```

### Error: "SOAP Authentication failed"

**Causa:** Credenciales incorrectas en properties

**Solución:**
```bash
# 1. Validar credenciales en propiedades
grep "wso2.ldap.username\|wso2.ldap.password" fedi-web/src/main/resources/security-roles*.properties

# 2. Testing manual con curl
curl -u username:password "http://wso2-server:9443/services/RemoteUserStoreManagerService"

# 3. Si falla: obtener credenciales correctas de Daniel
```

### Error: "Maven: Cannot resolve dependency org.apache.axis2:axis2-kernel:1.7.9"

**Causa:** Repository WSO2 no accesible o no configurado

**Solución:**
```xml
<!-- En settings.xml, verificar que repository WSO2 está habilitado -->
<repository>
    <id>wso2-nexus</id>
    <name>WSO2 Nexus Repository</name>
    <url>https://maven.wso2.org/nexus/content/groups/wso2-public/</url>
    <releases>
        <enabled>true</enabled>
    </releases>
</repository>

<!-- Si sigue fallando, usar mirror: -->
<mirror>
    <id>wso2</id>
    <name>WSO2 Mirror</name>
    <url>https://wso2.org/nexus/content/repositories/releases</url>
    <mirrorOf>wso2-nexus</mirrorOf>
</mirror>
```

### Error: "SOAP timeout connecting to WSO2"

**Causa:** Timeout insuficiente o WSO2 no disponible

**Solución:**
```properties
# En security-roles.properties, aumentar timeouts:
wso2.ldap.connection.timeout=60000  # 60 segundos
wso2.ldap.read.timeout=60000
```

### Error: "Memory leak - Axis2 ConfigurationContext not closing"

**Causa:** Context no se destruye al shutdown

**Solución:**
```java
// Agregar a Spring shutdown hook en Axis2ConfigurationService
@PreDestroy
public void cleanup() {
    try {
        configurationContext.terminate();
        LOGGER.info("Axis2 ConfigurationContext cleaned up");
    } catch (Exception e) {
        LOGGER.warn("Error during cleanup", e);
    }
}
```

---

## PLAN B: Si Option B Falla en Week 1

Si durante week 1 encuentras **bloqueadores técnicos importantes** (ej: incompatibilidad crítica Axis2):

### Rollback a Option A (4 horas)

1. **Revert cambios a FEDI-WEB:**
   ```bash
   git revert --no-commit [commits de cambios FEDI]
   git clean -fd
   ```

2. **Preparar srvAutoregistro para CRT:**
   ```bash
   cd srvAutoregistro
   cp pom.xml pom-original.xml
   # Crear profile crt-oracle1
   # Compilar: mvn clean install -Pcrt-oracle1
   ```

3. **Deployment srvAutoregistro a WebLogic CRT:**
   - Tiempo: ~2 horas
   - Requiere credenciales de Daniel

4. **Testing en CRT:**
   - Tiempo: ~1.5 horas
   - Validar endpoints responden

### Documentar Lecciones Aprendidas

```markdown
## Por qué Option B no fue viable

- Bloqueador identificado: [describir]
- Stacktrace: [logs]
- Recomendación: [siguiente paso]

## Continuar con Option B después

- Cuando: [timeline]
- Requiere: [prerequisitos]
```

---

## RESUMEN FINAL

### Timeline Realista (30 horas)

| Fase | Horas | Estado | Output |
|------|-------|--------|--------|
| **1. Validación** | 5 | Planning | 3 documentos técnicos |
| **2. Preparación** | 5 | Planning | Estructura + pom.xml |
| **3. Implementación** | 10 | Planning | RolesServiceFEDI + modelos |
| **4. Integración** | 5 | Planning | Refactoring AdminUsuarios |
| **5. Testing** | 5 | Planning | Tests + documentación |
| **TOTAL** | **30** | ✅ | **Opción B lista para deployment** |

### Criterio de Éxito Week 1

- ✅ RolesServiceFEDI funcional (todas 4 operaciones implementadas)
- ✅ Integración con AdminUsuariosServiceImpl completada
- ✅ Tests unitarios y manual pasando
- ✅ Performance validado (latencia < 150ms)
- ✅ Documentación completa
- ✅ Código listo para production deployment (solo falta credenciales WSO2 CRT)

### Siguiente Paso: Week 2-3 (Con Aprobación)

- Deployment a WebLogic CRT
- Testing en ambiente CRT real
- Monitoreo y fine-tuning
- Rollout a producción

---

**Documento Generado:** 2026-02-06  
**Responsable:** Equipo FEDI CRT  
**Versión:** 1.0 - Plan de Ejecución  

Si tienes preguntas durante la implementación, consulta el índice maestro `24_INDICE_MAESTRO_DOCUMENTACION.md` para navegar toda la documentación de contexto.
