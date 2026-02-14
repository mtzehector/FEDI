# ✅ CHECKLIST DE DESPLIEGUE - Prueba Login con API Manager IFT

**Fecha:** 2026-02-13
**Objetivo:** Desplegar fedi-srv y fedi-web para validar que el login funciona correctamente con dominio IFT antes de migrar a CRT
**Estado:** Listo para compilar y desplegar

---

## 🎯 Objetivo de la Prueba

1. **Validar** que el login funciona con API Manager IFT
2. **Confirmar** que ambos compilados (fedi-srv y fedi-web) están correctamente configurados
3. **Establecer** línea base funcional antes de cualquier cambio a CRT
4. **Identificar** cualquier problema antes de la migración

---

## 📊 ANÁLISIS DE CONFIGURACIÓN ACTUAL

### ✅ fedi-srv (Backend API)

**Ubicación:** `D:\GIT\GITHUB\CRT2\FEDI2026\fedi-srv\fedi-srv\`

#### Profile Activo: `development-oracle11`
```xml
<profile>
    <id>development-oracle11</id>
    <activation>
        <activeByDefault>true</activeByDefault>
    </activation>
</profile>
```

#### Configuración Crítica:
| Propiedad | Valor | Estado |
|-----------|-------|--------|
| **Base de Datos** | Oracle (172.17.42.87:1521) | ⚠️ Verificar conectividad |
| **JDBC Driver** | `oracle.jdbc.OracleDriver` | ✅ OK |
| **MyBatis XMLs** | `myBatis/sqlserver/**/*.xml` | ⚠️ Inconsistente (dice Oracle pero busca SQL Server XMLs) |
| **Sistema ID** | `0022FEDI` | ✅ OK |
| **LDAP URL** | `http://172.17.42.47:9001/mx.org.ift.srv.rst.ldap/LDP/` | ✅ OK (IFT) |

**⚠️ PROBLEMA DETECTADO:**
```xml
<!-- Base de datos: Oracle -->
<profile.jdbc.driverClassName>oracle.jdbc.OracleDriver</profile.jdbc.driverClassName>

<!-- Pero MyBatis busca en carpeta SQL Server -->
<profile.myBatis.xml.location>myBatis/sqlserver/**/*.xml</profile.myBatis.xml.location>
```

**📝 Acción Requerida:** Verificar si fedi-srv realmente usa Oracle o SQL Server.

---

### ✅ fedi-web (Frontend Portal)

**Ubicación:** `D:\GIT\GITHUB\CRT2\FEDI2026\fedi-web\fedi-web\`

#### Profile Activo: `development-oracle1`
```xml
<profile>
    <id>development-oracle1</id>
    <activation>
        <activeByDefault>true</activeByDefault>
    </activation>
</profile>
```

#### Configuración Crítica - URLs de API Manager IFT:

| Servicio | URL Configurada | Estado |
|----------|----------------|--------|
| **Token OAuth2** | `http://apimanager-dev.ift.org.mx/token` | ✅ API Manager IFT |
| **Login API** | `https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/` | ✅ API Manager IFT |
| **FEDI API** | `https://fedidev.crt.gob.mx/srvFEDIApi-1.0/` | ✅ Directo a fedi-srv CRT |
| **Autoregistro** | `https://apimanager-dev.ift.org.mx/srvAutoregistroQA/v1.0/` | ✅ API Manager IFT |
| **LDP (LDAP)** | `https://apimanager-dev.ift.org.mx/ldp.inf.ift.org.mx/v1.0/` | ✅ API Manager IFT |
| **Bitácora** | `http://apimanager-dev.ift.org.mx/bit.reg.ift.org.mx/registroBitacora/` | ✅ API Manager IFT |
| **WSO2 Identity** | `https://identityserver-dev.ift.org.mx` | ✅ IFT |

#### Token de Autenticación:
```xml
<profile.mdsgd.token.id>
  Basic VGZxc3BCYWVYZHhCNlF0SUJHV0EzZUxpMkw0YTpWTUdUVHhqUDVkMl91eFoxdW5uSVBSTGpmZ01h
</profile.mdsgd.token.id>
```
✅ Token IFT configurado

---

## 🔍 ANÁLISIS DE FLUJO DE LOGIN

### Secuencia Esperada:

```
1. Usuario → https://fedidev.crt.gob.mx/FEDIPortalWeb-1.0/
   ↓
2. Login.jsf carga
   ↓
3. Usuario ingresa credenciales (dgtic.dds.ext023@ift.org.mx)
   ↓
4. fedi-web → POST https://apimanager-dev.ift.org.mx/token
   Obtiene: Bearer Token
   ↓
5. fedi-web → POST https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/
   Header: Authorization Bearer [token]
   Body: { username, password }
   ↓
6. API Manager valida con WSO2 Identity Server IFT
   ↓
7. ✅ Login exitoso → Redirige a /content/restricted/redirect.jsf
```

### Puntos de Validación:

| # | Checkpoint | Esperado | Cómo Validar |
|---|-----------|----------|--------------|
| 1 | Token OAuth2 | HTTP 200 + access_token | Logs: "Token obtenido" |
| 2 | Login API | HTTP 200 + sessionId | Logs: "Login exitoso" |
| 3 | Catálogo Usuarios | HTTP 200 + JSON | Logs: "consultarUsuarios OK" |
| 4 | Redirección | /restricted/redirect.jsf | Navegador |

---

## 📋 CHECKLIST PRE-COMPILACIÓN

### fedi-srv

- [ ] **Verificar conectividad a BD Oracle:**
  ```bash
  # Desde servidor donde está desplegado
  telnet 172.17.42.87 1521
  ```

- [ ] **Verificar inconsistencia MyBatis:**
  ```bash
  # Listar XMLs disponibles
  ls fedi-srv/fedi-srv/src/main/resources/myBatis/sqlserver/
  ls fedi-srv/fedi-srv/src/main/resources/myBatis/oracle/
  ```
  **Decisión:** ¿Oracle o SQL Server?

- [ ] **Revisar dependencias:**
  ```bash
  cd fedi-srv/fedi-srv
  mvn dependency:tree > dependencies-srv.txt
  # Buscar conflictos
  grep -i "conflict\|omitted" dependencies-srv.txt
  ```

### fedi-web

- [ ] **Validar que profile `development-oracle1` está activo**
  ```bash
  grep -A 5 "activeByDefault.*true" fedi-web/fedi-web/pom.xml
  ```

- [ ] **Verificar URLs IFT en pom.xml:**
  ```bash
  grep "apimanager-dev.ift.org.mx" fedi-web/fedi-web/pom.xml
  ```
  ✅ Debe aparecer en:
  - `profile.mdsgd.token.url`
  - `profile.lgn.api.url`
  - `profile.autoregistro.url`
  - `profile.ldp.url`

- [ ] **Verificar Token ID no esté vacío:**
  ```bash
  grep "profile.mdsgd.token.id" fedi-web/fedi-web/pom.xml
  ```

---

## 🛠️ COMANDOS DE COMPILACIÓN

### 1. Compilar fedi-srv

```bash
cd D:\GIT\GITHUB\CRT2\FEDI2026\fedi-srv\fedi-srv

# Limpiar compilaciones anteriores
mvn clean

# Compilar con profile activo (development-oracle11 es default)
mvn package -DskipTests

# Verificar WAR generado
ls -lh target/srvFEDIApi-1.0.war
```

**Esperado:**
```
BUILD SUCCESS
target/srvFEDIApi-1.0.war (tamaño ~30-50 MB)
```

---

### 2. Compilar fedi-web

```bash
cd D:\GIT\GITHUB\CRT2\FEDI2026\fedi-web\fedi-web

# Limpiar compilaciones anteriores
mvn clean

# Compilar con profile development-oracle1 (es default)
mvn package -DskipTests

# Verificar WAR generado
ls -lh target/FEDIPortalWeb-1.0.war
```

**Esperado:**
```
BUILD SUCCESS
target/FEDIPortalWeb-1.0.war (tamaño ~80-120 MB)
```

---

## 📦 CHECKLIST DE DESPLIEGUE

### Pre-Despliegue

- [ ] **Backup de WARs actuales:**
  ```bash
  # En servidor de despliegue
  cp /path/to/webapps/srvFEDIApi-1.0.war /backup/srvFEDIApi-1.0.war.backup_$(date +%Y%m%d)
  cp /path/to/webapps/FEDIPortalWeb-1.0.war /backup/FEDIPortalWeb-1.0.war.backup_$(date +%Y%m%d)
  ```

- [ ] **Verificar espacio en disco:**
  ```bash
  df -h /path/to/webapps
  # Debe tener al menos 500 MB libres
  ```

- [ ] **Verificar Tomcat/WebLogic corriendo:**
  ```bash
  # Para Tomcat
  ps aux | grep tomcat

  # Para WebLogic
  ps aux | grep weblogic
  ```

---

### Despliegue de fedi-srv

1. **Copiar WAR al servidor:**
   ```bash
   scp D:\GIT\GITHUB\CRT2\FEDI2026\fedi-srv\fedi-srv\target\srvFEDIApi-1.0.war usuario@servidor:/tmp/
   ```

2. **Detener servidor de aplicaciones:**
   ```bash
   # Tomcat
   sudo systemctl stop tomcat9

   # O WebLogic (según tu setup)
   ./stopWebLogic.sh
   ```

3. **Eliminar despliegue anterior:**
   ```bash
   rm -rf /path/to/webapps/srvFEDIApi-1.0
   rm -f /path/to/webapps/srvFEDIApi-1.0.war
   ```

4. **Copiar nuevo WAR:**
   ```bash
   cp /tmp/srvFEDIApi-1.0.war /path/to/webapps/
   ```

5. **Iniciar servidor:**
   ```bash
   # Tomcat
   sudo systemctl start tomcat9

   # WebLogic
   ./startWebLogic.sh
   ```

6. **Verificar despliegue:**
   ```bash
   # Esperar 30-60 segundos
   tail -f /path/to/logs/catalina.out | grep -i "srvFEDIApi"

   # Buscar línea:
   # "Deployment of web application directory [srvFEDIApi-1.0] has finished"
   ```

7. **Test endpoint:**
   ```bash
   curl -k -i https://fedidev.crt.gob.mx/srvFEDIApi-1.0/catalogos/consultarUsuarios

   # Esperado: HTTP 200
   ```

---

### Despliegue de fedi-web

1. **Copiar WAR al servidor:**
   ```bash
   scp D:\GIT\GITHUB\CRT2\FEDI2026\fedi-web\fedi-web\target\FEDIPortalWeb-1.0.war usuario@servidor:/tmp/
   ```

2. **Detener servidor (si no está detenido):**
   ```bash
   sudo systemctl stop tomcat9
   ```

3. **Eliminar despliegue anterior:**
   ```bash
   rm -rf /path/to/webapps/FEDIPortalWeb-1.0
   rm -f /path/to/webapps/FEDIPortalWeb-1.0.war
   ```

4. **Copiar nuevo WAR:**
   ```bash
   cp /tmp/FEDIPortalWeb-1.0.war /path/to/webapps/
   ```

5. **Iniciar servidor:**
   ```bash
   sudo systemctl start tomcat9
   ```

6. **Verificar despliegue:**
   ```bash
   tail -f /path/to/logs/catalina.out | grep -i "FEDIPortalWeb"

   # Buscar líneas:
   # "Deployment of web application directory [FEDIPortalWeb-1.0] has finished"
   # "Spring context initialized"
   ```

---

## 🧪 PRUEBAS POST-DESPLIEGUE

### Test 1: Acceso a la Aplicación

```bash
# Desde navegador
https://fedidev.crt.gob.mx/FEDIPortalWeb-1.0/
```

**Esperado:**
- ✅ Página de login carga correctamente
- ✅ Logo IFT/CRT visible
- ✅ Campos de usuario y contraseña visibles
- ✅ Sin errores 404 o 500

---

### Test 2: Login con Usuario IFT

**Credenciales de Prueba:**
```
Usuario: dgtic.dds.ext023
Contraseña: [password del ambiente DEV]
```

**Pasos:**
1. Ingresar usuario (sin @ift.org.mx)
2. Ingresar contraseña
3. Clic en "Iniciar Sesión"

**Esperado:**
- ⏱️ Login toma 3-5 segundos
- ✅ Redirección a `/content/restricted/redirect.jsf`
- ✅ Dashboard carga correctamente
- ✅ Nombre de usuario visible en header
- ✅ Opciones de menú disponibles

---

### Test 3: Validación de Logs

**fedi-web logs:**
```bash
tail -200 /path/to/logs/catalina.out | grep -E "DIAG-WEB|ERROR|login"
```

**Buscar:**
- ✅ `[DIAG-WEB] Llamando API: https://apimanager-dev.ift.org.mx/token`
- ✅ `[DIAG-WEB] Token obtenido exitosamente`
- ✅ `[DIAG-WEB] Llamando API: https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/`
- ✅ `[DIAG-WEB] Login exitoso para usuario: dgtic.dds.ext023`
- ❌ No debe haber: `ERROR`, `timeout`, `Connection refused`

**fedi-srv logs:**
```bash
tail -200 /path/to/logs/catalina.out | grep -E "ERROR|consultarUsuarios"
```

**Buscar:**
- ✅ `GET /catalogos/consultarUsuarios - HTTP 200`
- ❌ No debe haber: `ERROR`, `SQLException`, `NullPointerException`

---

## 🚨 TROUBLESHOOTING

### Error: "Cannot connect to database"

**Causa:** fedi-srv no puede conectar a Oracle

**Solución:**
```bash
# 1. Verificar conectividad
telnet 172.17.42.87 1521

# 2. Verificar credenciales en pom.xml
grep "profile.jdbc" fedi-srv/fedi-srv/pom.xml

# 3. Verificar driver JDBC en WEB-INF/lib
unzip -l target/srvFEDIApi-1.0.war | grep ojdbc
```

---

### Error: "Token request failed - HTTP 401"

**Causa:** Token ID incorrecto o expirado

**Solución:**
```bash
# 1. Validar token en pom.xml
grep "profile.mdsgd.token.id" fedi-web/fedi-web/pom.xml

# 2. Probar token manualmente
curl -X POST "http://apimanager-dev.ift.org.mx/token" \
  -H "Authorization: Basic VGZxc3BCYWVYZHhCNlF0SUJHV0EzZUxpMkw0YTpWTUdUVHhqUDVkMl91eFoxdW5uSVBSTGpmZ01h" \
  -d "grant_type=client_credentials"

# Esperado: {"access_token":"..."}
```

---

### Error: "Login timeout after 120 seconds"

**Causa:** API Manager no responde

**Solución:**
```bash
# 1. Verificar que API Manager esté accesible
curl -I http://apimanager-dev.ift.org.mx/token

# 2. Verificar rutas en pom.xml
grep "lgn.api.url" fedi-web/fedi-web/pom.xml

# 3. Si persiste, activar consumo directo:
# Editar pom.xml, cambiar:
# <profile.fedi.url>https://apimanager-dev.ift.org.mx/FEDI/v1.0/</profile.fedi.url>
# Por:
# <profile.fedi.url>https://fedidev.crt.gob.mx/srvFEDIApi-1.0/</profile.fedi.url>
```

---

### Error: "NullPointerException in AdminUsuariosServiceImpl"

**Causa:** srvAutoregistroPerito no está disponible

**Solución:**
```bash
# 1. Verificar URL de autoregistro
grep "autoregistro.url" fedi-web/fedi-web/pom.xml

# 2. Test manual
curl -I https://apimanager-dev.ift.org.mx/srvAutoregistroQA/v1.0/registro/consultas/roles/2/1/0022FEDI

# 3. Si falla (HTTP 404), necesitas desplegar srvAutoregistroPerito
# Ver documentos:
# - 19_PLAN_COMPILACION_DESPLIEGUE_CRT.md
# - 23_RESPUESTA_TU_PROPUESTA_ANALISIS.md
```

---

## ✅ CRITERIOS DE ÉXITO

### Despliegue Exitoso si:

- [x] **Compilación:** BUILD SUCCESS en ambos proyectos
- [x] **WARs Generados:** Tamaños correctos (~30MB srv, ~100MB web)
- [x] **Despliegue:** Sin errores en logs de servidor
- [x] **Login:** Usuario IFT puede autenticarse
- [x] **Dashboard:** Página principal carga sin errores
- [x] **Logs Limpios:** No hay ERRORs críticos

### Si Alguno Falla:

1. **Revisar logs** en `/path/to/logs/catalina.out`
2. **Consultar sección Troubleshooting** de este documento
3. **Rollback** a WAR anterior si es necesario:
   ```bash
   cp /backup/srvFEDIApi-1.0.war.backup_20260213 /path/to/webapps/srvFEDIApi-1.0.war
   cp /backup/FEDIPortalWeb-1.0.war.backup_20260213 /path/to/webapps/FEDIPortalWeb-1.0.war
   sudo systemctl restart tomcat9
   ```

---

## 📊 REGISTRO DE PRUEBA

**Completar después del despliegue:**

```
Fecha de despliegue: _______________
Hora de inicio: _______________
Hora de término: _______________

fedi-srv:
  - Compilación: ✅ / ❌
  - Despliegue: ✅ / ❌
  - Endpoint test: ✅ / ❌

fedi-web:
  - Compilación: ✅ / ❌
  - Despliegue: ✅ / ❌
  - Login test: ✅ / ❌
  - Dashboard: ✅ / ❌

Observaciones:
_____________________________________________
_____________________________________________
_____________________________________________

Próximos pasos:
_____________________________________________
_____________________________________________
```

---

## 📚 DOCUMENTOS RELACIONADOS

Para más contexto, revisar:

1. **README.md** (raíz) - Introducción al proyecto
2. **01_ANALISIS_AUTENTICACION_IFT_EXITOSA.md** - Cómo funciona el login IFT
3. **03_GUIA_MIGRACION_CRT.md** - Plan de migración a CRT
4. **04_COMPARACION_LOGS_IFT_vs_CRT.md** - Para comparar logs después
5. **ANALISIS_ENDPOINTS_MANTENIMIENTO.md** - Análisis de endpoints actuales

---

**Documento generado:** 2026-02-13
**Última actualización:** 2026-02-13
**Estado:** Listo para ejecución
