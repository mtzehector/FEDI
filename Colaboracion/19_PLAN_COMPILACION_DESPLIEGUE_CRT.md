# 📋 PLAN CRT: Compilación y Despliegue de srvAutoRegistroPerito

**Documento:** Plan técnico para migrar srvAutoRegistroPerito a CRT  
**Fecha:** 2026-02-05  
**Estado:** READY FOR IMPLEMENTATION  

---

## FASE 1: ANÁLISIS PREVIO (COMPLETADO)

✅ Proyecto localizado: `C:\github\srvAutoRegistroPerito`  
✅ Endpoints validados: 4 operaciones principales mapeadas  
✅ Dependencias identificadas: Spring 3.1.4 + Jersey 2.14  
✅ Target compatible: WebLogic 12c (mismo que FEDI)  

---

## FASE 2: PREPARACIÓN DEL ENTORNO (REQUISITOS)

### Requisitos Pre-Compilación

**1. Información de CRT a obtener de Daniel:**
```
- IP/Hostname de WebLogic CRT
- Puerto (típicamente 7001 o 8001)
- URL de API Manager CRT
- URL de WSO2 Identity Server CRT
- Credenciales OAuth2 para API Manager CRT
- Configuración LDAP/SCIM en CRT
- Configuración de base de datos PERITOS en CRT
```

**2. Archivos de configuración necesarios:**
```
srvAutoRegistroPerito/
├── src/main/resources/
│   ├── application.properties        ← CONFIGURAR para CRT
│   ├── ldap.properties              ← URLs LDAP/SCIM CRT
│   ├── database.properties          ← JDBC/JNDI CRT
│   └── security.properties          ← OAuth2 credentials CRT
└── src/main/webapp/WEB-INF/
    └── web.xml                      ← Context path
```

**3. Maven profiles esperados:**
```xml
<!-- Analogía con FEDI pom.xml -->
<profile>
    <id>crt-oracle1</id>
    <activation><activeByDefault>false</activeByDefault></activation>
    <properties>
        <profile.mdsgd.token.url>http://apimanager-crt.ift.org.mx:8280/token</profile.mdsgd.token.url>
        <profile.mdsgd.token.id>Basic [BASE64_ENCODED_CREDENTIALS_CRT]</profile.mdsgd.token.id>
        <profile.autoregistro.url>https://apimanager-crt.ift.org.mx/srvAutoregistroCRT/v3.0/</profile.autoregistro.url>
        <profile.ldap.url>https://apimanager-crt.ift.org.mx/ldp.inf.ift.org.mx/v3.0/</profile.ldap.url>
        <!-- ... bases de datos CRT -->
    </properties>
</profile>
```

---

## FASE 3: COMPILACIÓN LOCAL

### Paso 3.1: Verificar estructura pom.xml actual

**Archivo:** `C:\github\srvAutoRegistroPerito\pom.xml`

**Búsqueda rápida:**
```bash
# Windows PowerShell
cd C:\github\srvAutoRegistroPerito
type pom.xml | findstr /I "profile\|id\|version\|groupId"
```

**Resultado esperado:**
```
artifactId: srvAutoregistroPerito
version: 1.0
packaging: war
spring: 3.1.4.RELEASE
jersey: 2.14
```

### Paso 3.2: Compilar con profile development (validación)

```bash
cd C:\github\srvAutoRegistroPerito

# Build sin profiles (para verificar que compila)
mvn clean compile

# Si hay errores:
# - Falta JDK → Instalar JDK 8+
# - Falta dependencies → mvn dependency:resolve
# - Problemas Spring → Revisar pom.xml
```

### Paso 3.3: Compilar WAR para pruebas locales

```bash
cd C:\github\srvAutoRegistroPerito

# Si existe profile development-oracle1 (analogía con FEDI)
mvn clean package

# Resultado esperado:
# BUILD SUCCESS
# target/srvAutoregistroPerito-1.0.war (creado)
```

### Paso 3.4: Verificar artefacto generado

```bash
# Listar contenido del WAR
jar -tf target/srvAutoregistroPerito-1.0.war | findstr "RegistraEvento\|RolesService"

# Resultado esperado:
# mx/org/ift/mod/seg/scim/rest/resource/RegistraEvento.class
# mx/org/ift/mod/seg/scim/service/RolesServiceImpl.class
# mx/org/ift/mod/seg/scim/service/RolesService.class
```

---

## FASE 4: CREACIÓN DE PROFILE CRT

### Paso 4.1: Actualizar pom.xml con profile CRT

**Archivo:** `srvAutoRegistroPerito/pom.xml`

**Agregar nuevo profile (después de development-oracle1 si existe):**

```xml
<profile>
    <id>crt-oracle1</id>
    <activation>
        <activeByDefault>false</activeByDefault>
    </activation>
    <properties>
        <!-- Nombre del profile en tiempo de ejecución -->
        <profileName>crt</profileName>
        
        <!-- Base de datos CRT -->
        <profile.jdbc.driverClassName>oracle.jdbc.OracleDriver</profile.jdbc.driverClassName>
        <profile.jdbc.url>XXXX_OBTENER_DE_DANIEL_XXXX</profile.jdbc.url>
        <profile.jdbc.username>XXXX_OBTENER_DE_DANIEL_XXXX</profile.jdbc.username>
        <profile.jdbc.password>XXXX_OBTENER_DE_DANIEL_XXXX</profile.jdbc.password>
        <profile.jdbc.jndi>jdbc/srvAutoregistro</profile.jdbc.jndi>
        
        <!-- MyBatis XML location -->
        <profile.myBatis.xml.location>myBatis/oracle/**/*.xml</profile.myBatis.xml.location>
        
        <!-- Versión app -->
        <profile.version.app>CRT:20260205-1</profile.version.app>
        
        <!-- API Manager CRT -->
        <profile.mdsgd.token.url>http://apimanager-crt.ift.org.mx:8280/token</profile.mdsgd.token.url>
        <profile.mdsgd.token.id>Basic XXXX_OBTENER_DE_DANIEL_XXXX</profile.mdsgd.token.id>
        <profile.ldap.url>https://apimanager-crt.ift.org.mx/ldp.inf.ift.org.mx/v3.0/</profile.ldap.url>
        
        <!-- Sistema identificadores -->
        <profile.sistema.identificador>0022FEDI</profile.sistema.identificador>
        <profile.sistema.identificador.ext>0015MSPERITOSDES-INT</profile.sistema.identificador.ext>
    </properties>
</profile>
```

### Paso 4.2: Compilar con profile CRT

```bash
cd C:\github\srvAutoRegistroPerito

# Compilar con profile CRT
mvn clean package -P crt-oracle1

# Si falla por configuración (normal):
# - JDBC URLs vacías → Agregar valores de Daniel
# - LDAP no disponible → Esperar a estar en VPN de CRT
# - OAuth2 credenciales → Usar valores de pom.xml actual de referencia
```

---

## FASE 5: ADAPTACIONES A CÓDIGO (SI NECESARIO)

### Revisión de clases que podrían necesitar cambios

**1. Configuración LDAP/SCIM - Archivo a revisar:**
```
srvAutoRegistroPerito/src/main/java/mx/org/ift/mod/seg/scim/service/RolesServiceImpl.java
```

**Búsqueda en código:**
```bash
# Windows PowerShell
cd C:\github\srvAutoRegistroPerito
findstr /R /S "localhost:.*port\|http.*ldap\|http.*scim\|hardcoded.*url" src\
```

**Si encuentra URLs hardcoded:**
- Cambiarlas a propiedades inyectadas desde pom.xml
- Ejemplo: `@Value("${ldap.server.url}")`

**2. Configuración de base de datos - Archivo:**
```
srvAutoRegistroPerito/src/main/resources/datasource.properties
```

Debe estar parametrizado para permitir cambios por profile.

**3. Endpoints REST - VERIFICADO:**
```
srvAutoRegistroPerito/src/main/java/mx/org/ift/mod/seg/scim/rest/resource/RegistraEvento.java
```
✅ **NO REQUIERE CAMBIOS** - Endpoints son genéricos (funcionan con cualquier backend LDAP/SCIM)

---

## FASE 6: DESPLIEGUE EN API MANAGER CRT

### Paso 6.1: Preparar WAR para despliegue

```bash
# Una vez compilado exitosamente
cd C:\github\srvAutoRegistroPerito

# Generar WAR final
mvn clean package -P crt-oracle1 -DskipTests

# Copiar a ubicación de deploy
# Nota: Revisar dónde Daniel tiene el repository de WARs en CRT
copy target\srvAutoregistroPerito-1.0.war \\[CRT_SHARE]\WAR_DEPLOY\
```

### Paso 6.2: Crear API en API Manager CRT (Tarea Manual)

**Requiere acceso a WSO2 API Manager CRT**

1. **Acceso:**
   - URL: `https://apimanager-crt.ift.org.mx:9443/publisher`
   - Usuario/Contraseña: Solicitar a Daniel

2. **Crear API:**
   ```
   Nombre: srvAutoregistroCRT
   Versión: 3.0
   Contexto: /srvAutoregistroCRT
   ```

3. **Configurar Backend (Endpoint):**
   ```
   Endpoint Type: HTTP Endpoint
   URL: http://[CRT_WEBLOGIC_IP]:7001/srvAutoregistroPerito/
   ```

4. **URI Templates (Recursos):**
   ```
   - GET  /registro/consultas/roles/{tipo}/{filtro}/{almacen}
   - POST /registro/actualizar
   - GET  /registro/consultas/simca/roles/{tipo}/{filtro}/{almacen}
   - POST /registro/actualizar/simca
   ```

5. **Policies (Seguridad):**
   ```
   - OAuth2 Security
   - Rate Limiting (si aplica)
   - CORS Enable
   ```

6. **Publicar:**
   - Click "Publish" (Gateway URL generada automáticamente)

### Paso 6.3: Verificar API publicada

```bash
# Obtener token CRT
curl -i -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=[CLIENT_ID_CRT]&client_secret=[CLIENT_SECRET_CRT]" \
  "http://apimanager-crt.ift.org.mx:8280/token"

# Respuesta:
# { "access_token": "xxx", "token_type": "Bearer", "expires_in": 3600 }

# Probar endpoint publicado
curl -i -X GET \
  -H "Authorization: Bearer xxx" \
  "https://apimanager-crt.ift.org.mx/srvAutoregistroCRT/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT"
```

---

## FASE 7: ACTUALIZAR FEDI-WEB PARA CRT

### Paso 7.1: Modificar pom.xml de FEDI-WEB

**Archivo:** `C:\github\fedi-web\pom.xml`

**Crear nuevo profile crt-oracle1:**

```xml
<profile>
    <id>crt-oracle1</id>
    <activation>
        <activeByDefault>false</activeByDefault>
    </activation>
    <properties>
        <!-- ... copiar de qa-oracle1 y cambiar URLs ... -->
        
        <!-- URLs de API Manager CRT -->
        <profile.mdsgd.token.url>http://apimanager-crt.ift.org.mx:8280/token</profile.mdsgd.token.url>
        <profile.mdsgd.token.id>Basic [CREDENTIALS_CRT]</profile.mdsgd.token.id>
        
        <!-- CAMBIO CRÍTICO: Endpoint srvAutoregistro -->
        <profile.autoregistro.url>https://apimanager-crt.ift.org.mx/srvAutoregistroCRT/v3.0/</profile.autoregistro.url>
        
        <!-- Otros endpoints CRT -->
        <profile.fedi.url>https://apimanager-crt.ift.org.mx/FEDI/v3.0/</profile.fedi.url>
        <profile.ldp.url>https://apimanager-crt.ift.org.mx/ldp.inf.ift.org.mx/v3.0/</profile.ldp.url>
        
        <!-- Base de datos FEDI en CRT -->
        <profile.jdbc.url>[OBTENER_DE_DANIEL]</profile.jdbc.url>
        <profile.jdbc.username>[OBTENER_DE_DANIEL]</profile.jdbc.username>
        <profile.jdbc.password>[OBTENER_DE_DANIEL]</profile.jdbc.password>
    </properties>
</profile>
```

### Paso 7.2: Compilar FEDI-WEB para CRT

```bash
cd C:\github\fedi-web

mvn clean package -P crt-oracle1

# Generar WAR
# target/FEDIPortalWeb-1.0.war
```

---

## FASE 8: DESPLIEGUE EN WEBLOGIC CRT

### Paso 8.1: Desplegar srvAutoregistroPerito.war

```bash
# Copiar WAR a domain de WebLogic
copy target\srvAutoregistroPerito-1.0.war [WEBLOGIC_CRT_HOME]\domains\[DOMAIN_NAME]\autodeploy\

# Verificar despliegue en consola:
# https://[CRT_IP]:7002/console
# Deployments → Ver srvAutoregistroPerito (GREEN status)
```

### Paso 8.2: Desplegar FEDIPortalWeb.war

```bash
# Copiar WAR a domain de WebLogic
copy target\FEDIPortalWeb-1.0.war [WEBLOGIC_CRT_HOME]\domains\[DOMAIN_NAME]\autodeploy\

# Verificar despliegue
# FEDIPortalWeb debe estar en GREEN status
```

---

## FASE 9: VALIDACIÓN Y TESTING

### Test 9.1: Validar acceso a endpoints srvAutoRegistroPerito

```bash
# 1. Obtener token de CRT
$token = $(curl -s -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=[ID]&client_secret=[SECRET]" \
  "http://apimanager-crt.ift.org.mx:8280/token" | jq -r '.access_token')

# 2. Test GET roles
curl -i -X GET \
  -H "Authorization: Bearer $token" \
  "https://apimanager-crt.ift.org.mx/srvAutoregistroCRT/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT"

# 3. Test POST actualizar
curl -i -X POST \
  -H "Authorization: Bearer $token" \
  -H "Content-Type: application/json" \
  -d '{"user":"test_user","rolAgregar":["ROLE1"],"rolBorrar":[]}' \
  "https://apimanager-crt.ift.org.mx/srvAutoregistroCRT/v3.0/registro/actualizar"
```

### Test 9.2: Validar FEDI-WEB puede consumir srvAutoRegistroPerito

**Acceso a FEDI-WEB en CRT:**
```
https://[CRT_IP]:7002/FEDIPortalWeb/
```

**Pasos en UI:**
1. Login con usuario CRT
2. Navegar a Administración de Usuarios
3. Verificar que se cargan los dropdowns de roles
4. Intentar cambiar roles a un usuario
5. Confirmar que se actualiza en PERITOS

### Test 9.3: Logs y debugging

```bash
# Ver logs de srvAutoregistroPerito
tail -f [WEBLOGIC_CRT_HOME]/domains/[DOMAIN]/servers/[SERVER]/logs/

# Buscar errores de conexión
grep -i "error\|exception\|failed" [LOGFILE]

# Logs de FEDI
grep -i "AutoregistroServiceImpl\|MDSeguridadService" [WEBLOGIC_LOG]
```

---

## FASE 10: VALIDACIÓN FUNCIONAL COMPLETA

### Test Suite Recomendado

| Test | Descripción | Esperado |
|---|---|---|
| T1 | Obtener roles del sistema | 200 OK + lista de roles |
| T2 | Obtener usuarios por rol | 200 OK + usuarios filtrados |
| T3 | Validar usuario existe | 200 OK + exists: true/false |
| T4 | Asignar roles a usuario | 200 OK + confirmar en LDAP |
| T5 | Remover roles de usuario | 200 OK + confirmar en LDAP |
| T6 | Actualizar multiples usuarios | 200 OK + todos actualizados |
| T7 | FEDI obtiene dropdown roles | 200 OK + UI actualizada |
| T8 | FEDI cambia rol de usuario | 200 OK + cambio reflejado |

---

## RESUMEN DE COMANDOS (CHEAT SHEET)

```bash
# Compilación
cd C:\github\srvAutoRegistroPerito
mvn clean package -P crt-oracle1

# Obtener token
curl -X POST http://apimanager-crt.ift.org.mx:8280/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=X&client_secret=Y"

# Test endpoint
curl -H "Authorization: Bearer TOKEN" \
  "https://apimanager-crt.ift.org.mx/srvAutoregistroCRT/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT"

# Deploy (manual en WebLogic)
# Copy .war to autodeploy folder + verify in console
```

---

## DEPENDENCIAS CRÍTICAS A VERIFICAR EN CRT

- [ ] WebLogic 12c disponible y funcionando
- [ ] Oracle PERITOS DB accesible desde WebLogic
- [ ] WSO2 Identity Server (LDAP/SCIM) configurado y accesible
- [ ] API Manager CRT en funcionamiento
- [ ] Redes: WebLogic ↔ Oracle, WebLogic ↔ LDAP, API ↔ WebLogic
- [ ] Credenciales OAuth2 para APIs (client_id, client_secret)
- [ ] Certificados SSL/TLS válidos en API Manager

---

## CHECKLIST PRE-DESPLIEGUE

- [ ] srvAutoRegistroPerito compila sin errores
- [ ] pom.xml tiene profile crt-oracle1
- [ ] WAR generado contiene RegistraEvento.class
- [ ] FEDI-WEB tiene profile crt-oracle1
- [ ] URLs de API Manager CRT actualizadas en FEDI
- [ ] Credenciales OAuth2 CRT configuradas
- [ ] Base de datos PERITOS CRT accesible
- [ ] LDAP/SCIM CRT accesible
- [ ] API Manager CRT tiene API srvAutoregistroCRT publicada
- [ ] WebLogic CRT puede desplegar WARs

---

**Próximo Paso:** Coordinar con Daniel Mijangos para obtener:
1. URLs exactas de API Manager CRT
2. Credenciales OAuth2 para CRT
3. Configuración de base de datos PERITOS en CRT
4. Configuración LDAP/SCIM en CRT
5. IP/Puerto de WebLogic CRT

---

*Documento: Plan CRT para srvAutoRegistroPerito*  
*Generado: 2026-02-05*  
*Estado: READY FOR IMPLEMENTATION*
