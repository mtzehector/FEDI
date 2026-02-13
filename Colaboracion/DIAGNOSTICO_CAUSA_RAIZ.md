# ⚠️ PROBLEMA IDENTIFICADO: fedi-srv NO Recibe Peticiones

## 🔍 Diagnóstico Basado en Logs Nuevos

### Evidencia del Log

**fedi-web intenta llamar:**
```
2026-02-11 19:40:56,857 [INFO] FEDIServiceImpl:114 - *** [DIAG-WEB] Llamando API: https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios
2026-02-11 19:40:56,857 [INFO] MDSeguridadServiceImpl:212 - [MDSeguridadService.EjecutaMetodoGET] iniciando GET request
```

**Resultado después de 120 segundos:**
```
2026-02-11 19:42:56,953 [ERROR] MDSeguridadServiceImpl:232 - IOException. Error=timeout, Duracion=120096ms
```

### ❌ Problema Critical

**NO HAY LOGS de `CatalogosResources.consultarUsuarios()` en fedi-srv**

Esto significa:
- ✅ fedi-web **SÍ está intentando** conectar al endpoint
- ✅ API Manager **SÍ recibe la petición**
- ❌ **fedi-srv NO responde** el endpoint REST
- ❌ **API Manager espera 120s y luego timeout**

### Causas Posibles

1. **fedi-srv NO está arrancado correctamente**
   - El WAR se desplegó pero la aplicación no inicializó completamente
   - Verificar logs de startup de Tomcat

2. **Ruta incorrecta en API Manager**
   - API Manager apunta a `https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios`
   - Pero fedi-srv podría estar en otra URL/puerto

3. **Tomcat está caído o sin recursos**
   - Proceso Java no está corriendo
   - Memoria insuficiente

4. **Puerto incorrecto o Firewall**
   - fedi-srv escucha en puerto X, API Manager intenta en puerto Y
   - Firewall bloquea la conexión

---

## 🔧 Acciones Inmediatas (Tu Servidor)

### 1. Verificar que fedi-srv esté corriendo

```powershell
# Ver si hay proceso Java corriendo
Get-Process java -ErrorAction SilentlyContinue

# Ver estado del servicio Tomcat
Get-Service | Where-Object {$_.Name -like "*tomcat*" -or $_.Name -like "*java*"}

# Ver si Tomcat está activo
Get-Service Tomcat9 | Select-Object Name, Status, StartType
```

### 2. Verificar inicio correcto de fedi-srv

```powershell
# Ver últimos 100 líneas del catalina.out
Get-Content "C:\tomcat\logs\catalina.out" -Tail 100

# Buscar errores de startupde fedi-srv
Select-String -Path "C:\tomcat\logs\catalina.out" -Pattern "ERROR|fedi-srv|srvFEDIApi" -ErrorAction SilentlyContinue | Select-Object -Last 20
```

### 3. Probar acceso local a fedi-srv

```powershell
# Desde el servidor, intentar acceder localmente
# Ejemplo si está en puerto 8080:
curl http://localhost:8080/srvFEDIApi/catalogos/consultarUsuarios

# O con Invoke-WebRequest (PowerShell)
$response = Invoke-WebRequest -Uri "http://localhost:8080/srvFEDIApi/catalogos/consultarUsuarios" -ErrorAction SilentlyContinue
$response.StatusCode  # Debería ser 200
```

### 4. Verificar configuración de API Manager

En la UI de API Manager, buscar:
- Ruta: `/FEDI/v1.0/catalogos/consultarUsuarios`
- Backend (Target): ¿A qué servidor/puerto apunta?
- Timeout configurado: ¿Es > 120 segundos?

---

## 📊 Comparación: Lo Que Esperábamos vs Lo Que Vemos

### Flujo Esperado
```
fedi-web [Llamando API] → API Manager → fedi-srv [REST /catalogos] → BD → Respuesta JSON
⏱️ Tiempo esperado: 2-5 segundos
```

### Flujo Actual (Problema)
```
fedi-web [Llamando API] 
  ↓ (19:40:56.857)
API Manager 
  ↓ (intenta conectar)
fedi-srv ❌ NO RESPONDE / NO RECIBE
  ↓ (espera 120 segundos)
Timeout: IOException
⏱️ Tiempo real: 120+ segundos
```

---

## 🎯 Pruebas a Realizar

### Prueba 1: ¿Está Java corriendo?

```powershell
Get-Process java -ErrorAction SilentlyContinue
# Si NO ve nada → Java/Tomcat no está arrancado
```

### Prueba 2: ¿Puedo acceder a fedi-srv localmente?

```powershell
# Desde la misma máquina donde está Tomcat
Invoke-WebRequest -Uri "http://localhost:8080/srvFEDIApi/catalogos/consultarUsuarios" -ErrorAction SilentlyContinue
# Si falla → Tomcat no responde o WAR no está desplegado
```

### Prueba 3: ¿Está corriendo la aplicación?

```powershell
# Ver logs de startup
Get-Content "C:\tomcat\logs\catalina.2026-02-11.log" | Select-String "started" | Select-Object -Last 5
# Buscar línea como: "srvFEDIApi loaded in XXXms"
```

---

## 🚀 ALTERNATIVA RÁPIDA: Omitir API Manager

**En lugar de esperar a que fedi-srv responda a través de API Manager**, puedes **cambiar la URL en pom.xml** para que fedi-web acceda DIRECTAMENTE a fedi-srv:

### Opción 1: Mismo Servidor (Recomendado para Testing)
```xml
<!-- Cambiar en fedi-web/pom.xml línea ~809: -->
<profile.fedi.url>http://localhost:8080/srvFEDIApi/</profile.fedi.url>
```

### Opción 2: Servidor Remoto
```xml
<!-- Cambiar en fedi-web/pom.xml línea ~809: -->
<profile.fedi.url>http://[IP-O-HOSTNAME-FEDI-SRV]:8080/srvFEDIApi/</profile.fedi.url>
```

### Resultado Esperado
```
ANTES: 120+ segundos (timeout vía API Manager) ❌
DESPUÉS: 2-5 segundos (directo a fedi-srv) ✅
```

**Ver**: `GUIA_CONSUMO_DIRECTO_SIN_APIMANAGER.md` para instrucciones completas

---

## 💡 Posible Solución Rápida

Si fedi-srv NO está respondiendo, el problema probablemente sea:

1. **Tomcat no arrancó los WARs correctamente**
   ```powershell
   # Detener Tomcat
   Stop-Service Tomcat9 -Force
   
   # Limpiar cache de Tomcat
   Remove-Item "C:\tomcat\work\Catalina\localhost\*" -Recurse -Force
   Remove-Item "C:\tomcat\webapps\srvFEDIApi-1.0" -Recurse -Force
   Remove-Item "C:\tomcat\webapps\FEDIPortalWeb-1.0" -Recurse -Force
   
   # Iniciar Tomcat nuevamente
   Start-Service Tomcat9
   
   # Esperar a que se despliegue (30-60 segundos)
   Start-Sleep -Seconds 40
   
   # Verificar logs
   Get-Content "C:\tomcat\logs\catalina.out" -Tail 50
   ```

2. **Los WARs no están en el lugar correcto**
   ```powershell
   # Verificar que los WARs estén en webapps
   Get-ChildItem "C:\tomcat\webapps\*.war" | Select-Object Name, Length
   
   # Debería ver:
   # srvFEDIApi-1.0.war (35.7 MB) ← Backend
   # FEDIPortalWeb-1.0.war (98.8 MB) ← Frontend
   ```

---

## 📝 Checklist de Diagnóstico

- [ ] ¿Está proceso Java corriendo? (`Get-Process java`)
- [ ] ¿Tomcat está iniciado? (`Get-Service Tomcat9`)
- [ ] ¿WARs están en `C:\tomcat\webapps\`?
- [ ] ¿Puedo acceder a `http://localhost:8080/srvFEDIApi`? (debería ver error 404, no timeout)
- [ ] ¿Hay logs nuevos en `catalina.out`?
- [ ] ¿API Manager tiene configuración correcta?

---

## 🔄 Próximos Pasos

1. **Ejecuta las verificaciones arriba** en el servidor
2. **Comparte los resultados** de:
   - `Get-Process java`
   - `Get-Service Tomcat9`
   - Últimas 50 líneas de `C:\tomcat\logs\catalina.out`
3. **Con esa info**, podré decirte exactamente qué hacer para que fedi-srv responda

---

## 📌 Nota Importante

Los logs con `[DIAG-WEB]` que agregué SÍ están funcionando (aparecen en fedi-web logs), pero los de fedi-srv (`[DIAG]` en CatalogosResources) NO aparecen porque **el endpoint nunca es alcanzado**.

Esto confirma que el problema es de **infraestructura/red/configuración**, no del código.
