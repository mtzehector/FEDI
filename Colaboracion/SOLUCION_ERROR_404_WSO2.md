# 🔧 SOLUCIÓN: Error 404 - Propiedades WSO2 Faltantes

## Problema Identificado

El error 404 ocurre porque **Spring no puede inicializar la aplicación** debido a propiedades WSO2 faltantes.

### Error Exacto (de los logs):
```
org.springframework.beans.factory.BeanCreationException: 
Could not autowire field: private java.lang.String 
fedi.ift.org.mx.arq.core.service.security.roles.RolesServiceFEDI.ldapUsername; 
nested exception is java.lang.IllegalArgumentException: 
Could not resolve placeholder 'wso2.ldap.username' in string value "${wso2.ldap.username}"
```

## ¿Por qué sucede?

RolesServiceFEDI requiere 7 propiedades WSO2 que NO están definidas:

1. ❌ `wso2.ldap.username` - Usuario LDAP (SIN valor por defecto)
2. ❌ `wso2.ldap.password` - Contraseña LDAP (SIN valor por defecto)
3. ❌ `wso2.identity-server.url` - URL del servidor WSO2
4. ❌ `wso2.identity-server.service.endpoint` - Endpoint del servicio
5. ⚠️ `wso2.ldap.username.ext` - Usuario LDAP externo (con default: null)
6. ⚠️ `wso2.ldap.password.ext` - Contraseña LDAP externa (con default: null)
7. ⚠️ `wso2.ldap.cache.enabled` - Cache habilitado (con default: true)

## Solución (3 pasos)

### PASO 1: Agregar propiedades en application.properties

Agregar al final de `src/main/resources/application.properties`:

```properties
# WSO2 Identity Server Configuration para servicio de roles FEDI
wso2.identity-server.url=${profile.wso2.identity-server.url:http://localhost:9443}
wso2.identity-server.service.endpoint=${profile.wso2.identity-server.service.endpoint:/services/RemoteUserStoreManagerService}
wso2.ldap.username=${profile.wso2.ldap.username}
wso2.ldap.password=${profile.wso2.ldap.password}
wso2.ldap.username.ext=${profile.wso2.ldap.username.ext:#{null}}
wso2.ldap.password.ext=${profile.wso2.ldap.password.ext:#{null}}
wso2.ldap.cache.enabled=${profile.wso2.ldap.cache.enabled:true}
wso2.ldap.connection.timeout=${profile.wso2.ldap.connection.timeout:30000}
wso2.ldap.read.timeout=${profile.wso2.ldap.read.timeout:30000}
```

### PASO 2: Agregar propiedades en perfil DEV (pom.xml)

Agregar en la sección `<properties>` del perfil `development-oracle1`:

```xml
<!-- WSO2 LDAP Configuration -->
<profile.wso2.identity-server.url>http://tu-servidor-wso2:9443</profile.wso2.identity-server.url>
<profile.wso2.identity-server.service.endpoint>/services/RemoteUserStoreManagerService</profile.wso2.identity-server.service.endpoint>
<profile.wso2.ldap.username>admin</profile.wso2.ldap.username>
<profile.wso2.ldap.password>CONTRASEÑA_DEL_ADMIN_WSO2</profile.wso2.ldap.password>
<profile.wso2.ldap.username.ext></profile.wso2.ldap.username.ext>
<profile.wso2.ldap.password.ext></profile.wso2.ldap.password.ext>
<profile.wso2.ldap.cache.enabled>true</profile.wso2.ldap.cache.enabled>
<profile.wso2.ldap.connection.timeout>30000</profile.wso2.ldap.connection.timeout>
<profile.wso2.ldap.read.timeout>30000</profile.wso2.ldap.read.timeout>
```

### PASO 3: Recompilar y redeploy

```bash
cd c:\github\fedi-web
mvn clean install -P development-oracle1 -DskipTests
# Copiar WAR a Tomcat
copy target\FEDIPortalWeb.war "C:\ruta-tomcat\webapps\"
# Reiniciar Tomcat
```

## Valores Recomendados para DEV

| Propiedad | DEV | Descripción |
|-----------|-----|------------|
| `wso2.identity-server.url` | `http://localhost:9443` o tu-servidor-wso2 | URL del servidor WSO2 |
| `wso2.ldap.username` | `admin` | Usuario administrativo WSO2 |
| `wso2.ldap.password` | *** | Contraseña del admin |
| `wso2.ldap.connection.timeout` | `30000` | Timeout de conexión (ms) |
| `wso2.ldap.read.timeout` | `30000` | Timeout de lectura (ms) |
| `wso2.ldap.cache.enabled` | `true` | Habilitar cache de roles |

## Verificación Post-Fix

Después de redeploy, deberías ver en los logs:

```
2026-02-08 17:43:33 [INFO] [AXIS2-CONFIG] ... Axis2 ConfigurationContext inicializado exitosamente
2026-02-08 17:43:33 [INFO] [] [] ContextLoader:272 - Root WebApplicationContext: startup complete
```

Y la aplicación debe ser accesible en:
```
http://tu-servidor:8080/FEDIPortalWeb
```

## ⚠️ Nota sobre la versión pom.xml que compartiste

Línea 770 está cortada. El perfil `development-oracle1` termina aproximadamente en la línea 795.

Necesitas agregar las propiedades WSO2 **ANTES del cierre** `</properties>` del perfil.
