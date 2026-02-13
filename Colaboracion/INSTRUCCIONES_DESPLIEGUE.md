# 🚀 INSTRUCCIONES DE DESPLIEGUE - FEDI (12-FEB-2026)

**Para:** Usuario (con acceso a Tomcat vía Remote Desktop)  
**Acción:** Desplegar 2 WARs en el Tomcat de desarrollo  
**Tiempo estimado:** 15-20 minutos

---

## 📦 Archivos a Desplegar

### 1️⃣ fedi-srv (Backend REST API)
- **Ruta local:** `C:\github\fedi-srv\target\srvFEDIApi-1.0.war`
- **Tamaño:** 28.6 MB
- **Nombre:** `srvFEDIApi-1.0.war`

### 2️⃣ fedi-web (Frontend Portal)
- **Ruta local:** `C:\github\fedi-web\target\FEDIPortalWeb-1.0.war`
- **Tamaño:** 98.7 MB
- **Nombre:** `FEDIPortalWeb-1.0.war`

---

## 🎯 Instrucciones de Despliegue

### OPCIÓN A: Despliegue Manual (Recomendado)

#### Paso 1: Detener Tomcat

```powershell
# En Remote Desktop (como administrador)
Stop-Service Tomcat9
```

Esperar a que el proceso termine (~5 segundos).

#### Paso 2: Limpiar Deployment Anterior de fedi-srv

```powershell
# Eliminar WAR anterior
Remove-Item "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\srvFEDIApi-1.0.war" -Force -ErrorAction SilentlyContinue

# Eliminar directorio desplegado
Remove-Item "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\srvFEDIApi-1.0" -Recurse -Force -ErrorAction SilentlyContinue

# Limpiar caché de Tomcat
Remove-Item "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\work\Catalina\localhost\srvFEDIApi-1.0" -Recurse -Force -ErrorAction SilentlyContinue
```

#### Paso 3: Limpiar Deployment Anterior de fedi-web

```powershell
# Eliminar WAR anterior
Remove-Item "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\FEDIPortalWeb-1.0.war" -Force -ErrorAction SilentlyContinue

# Eliminar directorio desplegado
Remove-Item "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\FEDIPortalWeb-1.0" -Recurse -Force -ErrorAction SilentlyContinue

# Limpiar caché de Tomcat
Remove-Item "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\work\Catalina\localhost\FEDIPortalWeb-1.0" -Recurse -Force -ErrorAction SilentlyContinue
```

#### Paso 4: Copiar WARs Nuevos

**Opción A.1: Desde tu máquina local (recomendado)**

```powershell
# En tu máquina local (Windows)
$servidor = "\\172.17.42.105\c$"
$destino = "$servidor\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps"

Copy-Item "C:\github\fedi-srv\target\srvFEDIApi-1.0.war" "$destino\" -Force
Copy-Item "C:\github\fedi-web\target\FEDIPortalWeb-1.0.war" "$destino\" -Force

Write-Host "✅ WARs copiados exitosamente"
```

**Opción A.2: Desde el servidor (Remote Desktop)**

```powershell
# En Remote Desktop - en el servidor
Copy-Item "\\[tu-máquina-local]\[carpeta-compartida]\srvFEDIApi-1.0.war" `
          "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\" -Force

Copy-Item "\\[tu-máquina-local]\[carpeta-compartida]\FEDIPortalWeb-1.0.war" `
          "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\" -Force
```

#### Paso 5: Verificar WARs Copiados

```powershell
dir "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\*.war"

# Deberías ver:
# - srvFEDIApi-1.0.war (28.6 MB)
# - FEDIPortalWeb-1.0.war (98.7 MB)
```

#### Paso 6: Iniciar Tomcat

```powershell
Start-Service Tomcat9

# Esperar ~30 segundos para que Tomcat inicie y despliegue
```

#### Paso 7: Monitorear Despliegue (Opcional)

```powershell
# Ver logs en tiempo real (en otra ventana PowerShell)
Get-Content "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\catalina.out" -Wait -Tail 30
```

**Buscar estos mensajes (indicadores de éxito):**
```
INFO: Root WebApplicationContext: initialization completed in XXX ms
INFO: ProtocolHandler [http-nio-9090] started
```

---

## ✅ Validación Post-Despliegue

### Paso 1: Validar fedi-srv

```bash
# Desde CMD o PowerShell
curl -k -i https://fedidev.crt.gob.mx/srvFEDIApi-1.0/catalogos/consultarUsuarios

# Esperado:
# HTTP/2 200
# (o HTTP 401 si requiere autenticación)
```

### Paso 2: Validar fedi-web (Navegador)

```
URL: https://fedidev.crt.gob.mx/FEDIPortalWeb-1.0/

1. Página de login debe cargar correctamente
2. Usuario: dgtic.dds.ext023
3. Contraseña: [la que uses]
4. Click en "Entrar"
5. Debe cargar catálogo de usuarios SIN TIMEOUT
```

### Paso 3: Revisar Logs (Si hay error)

```powershell
# Ver últimos 100 líneas del log de Tomcat
Get-Content "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\catalina.2026-02-*.log" -Tail 100

# Buscar ERRORES o "startup failed"
Select-String -Path "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\*.log" `
              -Pattern "ERROR|SEVERE|Exception|startup failed"
```

---

## 🔄 Script de Despliegue Automático (Opcional)

Si prefieres automatizar todo, crea un archivo `desplegar.ps1`:

```powershell
# desplegar.ps1
# Despliegue automático de WARs FEDI

$TOMCAT_HOME = "C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV"
$WEBAPPS = "$TOMCAT_HOME\webapps"

Write-Host "=== DESPLIEGUE FEDI WARs ===" -ForegroundColor Cyan

# 1. Detener Tomcat
Write-Host "[1/7] Deteniendo Tomcat..." -ForegroundColor Yellow
Stop-Service Tomcat9 -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# 2-3. Limpiar fedi-srv
Write-Host "[2/7] Limpiando srvFEDIApi anterior..." -ForegroundColor Yellow
Remove-Item "$WEBAPPS\srvFEDIApi-1.0.war" -Force -ErrorAction SilentlyContinue
Remove-Item "$WEBAPPS\srvFEDIApi-1.0" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$TOMCAT_HOME\work\Catalina\localhost\srvFEDIApi-1.0" -Recurse -Force -ErrorAction SilentlyContinue

# 4-5. Limpiar fedi-web
Write-Host "[3/7] Limpiando FEDIPortalWeb anterior..." -ForegroundColor Yellow
Remove-Item "$WEBAPPS\FEDIPortalWeb-1.0.war" -Force -ErrorAction SilentlyContinue
Remove-Item "$WEBAPPS\FEDIPortalWeb-1.0" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$TOMCAT_HOME\work\Catalina\localhost\FEDIPortalWeb-1.0" -Recurse -Force -ErrorAction SilentlyContinue

# 6. Copiar WARs nuevos
Write-Host "[4/7] Copiando nuevos WARs..." -ForegroundColor Yellow
Copy-Item "C:\github\fedi-srv\target\srvFEDIApi-1.0.war" "$WEBAPPS\" -Force
Copy-Item "C:\github\fedi-web\target\FEDIPortalWeb-1.0.war" "$WEBAPPS\" -Force

# 7. Iniciar Tomcat
Write-Host "[5/7] Iniciando Tomcat..." -ForegroundColor Yellow
Start-Service Tomcat9
Start-Sleep -Seconds 2

# 8. Verificar WARs
Write-Host "[6/7] Verificando despliegue..." -ForegroundColor Yellow
dir "$WEBAPPS\*.war"

Write-Host "`n[7/7] ✅ DESPLIEGUE COMPLETADO" -ForegroundColor Green
Write-Host "Esperando 30 segundos para inicialización completa..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# Mostrar logs finales
Write-Host "`nÚltimos logs de despliegue:" -ForegroundColor Cyan
Get-Content "$TOMCAT_HOME\logs\catalina.out" -Tail 20

Write-Host "`n✅ LISTO PARA VALIDAR:" -ForegroundColor Green
Write-Host "1. fedi-srv: https://fedidev.crt.gob.mx/srvFEDIApi-1.0/catalogos/consultarUsuarios" -ForegroundColor Cyan
Write-Host "2. fedi-web: https://fedidev.crt.gob.mx/FEDIPortalWeb-1.0/" -ForegroundColor Cyan
```

**Para ejecutar:**
```powershell
powershell.exe -ExecutionPolicy Bypass -File C:\desplegar.ps1
```

---

## ⚠️ Problemas Comunes y Soluciones

### Error: "Port 9090 already in use"

```powershell
# Matar proceso Java que esté usando el puerto
netstat -ano | findstr :9090
taskkill /PID [PID] /F

# Luego iniciar Tomcat normalmente
Start-Service Tomcat9
```

### Error: "One or more listeners failed to start"

```
Causa: Configuración de JNDI o BD
Solución: Revisar server.xml está bien configurado
```

### Timeout en fedi-web

```
Causa: fedi-srv no está respondiendo o acceso por API Manager
Solución: Verificar que fedi-srv esté desplegado y accesible
          curl https://fedidev.crt.gob.mx/srvFEDIApi-1.0/catalogos/consultarUsuarios
```

### Error de SQL Server

```
Causa: Credenciales incorrectas o BD no accesible
Solución: Revisar server.xml, usuario/contraseña de BD
```

---

## 📞 Contacto / Documentación

Si algo falla:
1. Revisar logs en `C:\github\Colaboracion\` (documentación)
2. Buscar en: `RESOLUCION_ERROR_DESPLIEGUE_JNDI.md`
3. Revisar: `ANALISIS_ENDPOINTS_MANTENIMIENTO.md`

---

**Creado por:** GitHub Copilot  
**Fecha:** 2026-02-12  
**Última Actualización:** 2026-02-12 18:50
