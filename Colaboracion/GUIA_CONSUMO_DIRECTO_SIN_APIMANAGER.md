# 🔌 GUÍA: Consumir fedi-srv Directamente (Sin API Manager)

## El Problema

Actualmente fedi-web consume a través de **API Manager**, que:
- Añade **120+ segundos de timeout**
- Es un punto de falla adicional en la arquitectura
- Puede tener problemas de routing/firewall

## La Solución

Cambiar la URL base en **pom.xml** para que fedi-web acceda **directamente a fedi-srv**.

---

## 📋 Opción 1: Acceso Local en Mismo Servidor (RECOMENDADO PARA TESTING)

Si ambas aplicaciones (fedi-web y fedi-srv) están en el **mismo Tomcat**:

### Cambio en pom.xml

```diff
- <profile.fedi.url>https://apimanager-dev.ift.org.mx/FEDI/v1.0/</profile.fedi.url>
+ <profile.fedi.url>http://localhost:8080/srvFEDIApi/</profile.fedi.url>
```

**Ubicación:**
```
c:\github\fedi-web\pom.xml
Líneas: 809, 867, 915 (un cambio por cada profile)
```

### Ventajas
✅ Sin salir del servidor (más rápido)  
✅ Sin pasar por API Manager  
✅ URL simple: `http://localhost:8080/srvFEDIApi/catalogos/consultarUsuarios`  
✅ Ideal para debugging

### Desventajas
❌ Solo funciona si fedi-web y fedi-srv están en el mismo Tomcat

---

## 📋 Opción 2: Acceso Remoto Directo (MÁS REALISTA)

Si **fedi-srv está en otro servidor**:

### Cambio en pom.xml

```diff
- <profile.fedi.url>https://apimanager-dev.ift.org.mx/FEDI/v1.0/</profile.fedi.url>
+ <profile.fedi.url>http://[IP-O-HOSTNAME-FEDI-SRV]:8080/srvFEDIApi/</profile.fedi.url>
```

**Ejemplo:**
```xml
<!-- Opción A: Si conoces la IP -->
<profile.fedi.url>http://192.168.1.100:8080/srvFEDIApi/</profile.fedi.url>

<!-- Opción B: Si conoces el hostname -->
<profile.fedi.url>http://srv-fedi-backend.dominio.mx:8080/srvFEDIApi/</profile.fedi.url>

<!-- Opción C: Con HTTPS (si está configurado) -->
<profile.fedi.url>https://srv-fedi-backend.dominio.mx:8443/srvFEDIApi/</profile.fedi.url>
```

### Cambios Necesarios

1. **En fedi-web/pom.xml**: Actualizar `profile.fedi.url`
2. **En fedi-srv/pom.xml**: Verificar que el contexto sea `srvFEDIApi`

### Verificar Conectividad

Desde la máquina donde corre fedi-web:

```powershell
# Test 1: Conectividad de red
ping [IP-O-HOSTNAME-FEDI-SRV]

# Test 2: Puerto Tomcat abierto
Test-NetConnection -ComputerName "[IP-O-HOSTNAME-FEDI-SRV]" -Port 8080

# Test 3: Endpoint accesible
Invoke-WebRequest -Uri "http://[IP-O-HOSTNAME-FEDI-SRV]:8080/srvFEDIApi/catalogos/consultarUsuarios" -ErrorAction SilentlyContinue
```

---

## 🔧 Pasos de Implementación

### PASO 1: Decidir la configuración

```powershell
# Preguntate:
# - ¿fedi-web y fedi-srv están en el MISMO servidor? → Usa Opción 1 (localhost:8080)
# - ¿fedi-srv está en OTRO servidor? → Usa Opción 2 (IP/hostname:8080)
```

### PASO 2: Editar pom.xml

Abre: `c:\github\fedi-web\pom.xml`

Busca y reemplaza en **3 ubicaciones** (una para cada profile):

**Profile dev (línea ~809):**
```xml
<!-- ANTES -->
<profile.fedi.url>https://apimanager-dev.ift.org.mx/FEDI/v1.0/</profile.fedi.url>

<!-- DESPUÉS (Opción 1: localhost) -->
<profile.fedi.url>http://localhost:8080/srvFEDIApi/</profile.fedi.url>

<!-- O DESPUÉS (Opción 2: remoto) -->
<profile.fedi.url>http://192.168.1.100:8080/srvFEDIApi/</profile.fedi.url>
```

**Profile qa (línea ~867):**
```xml
<!-- ANTES -->
<profile.fedi.url>https://apimanager-qa.crt.gob.mx/FEDI/v3.0/</profile.fedi.url>

<!-- DESPUÉS -->
<profile.fedi.url>http://[IP-O-HOSTNAME-FEDI-SRV]:8080/srvFEDIApi/</profile.fedi.url>
```

**Profile production (línea ~915):**
```xml
<!-- ANTES -->
<profile.fedi.url>https://apimanager.crt.gob.mx/FEDI/v2.0/</profile.fedi.url>

<!-- DESPUÉS -->
<profile.fedi.url>http://[IP-O-HOSTNAME-FEDI-SRV]:8080/srvFEDIApi/</profile.fedi.url>
```

### PASO 3: Compilar el WAR

```powershell
cd C:\github\fedi-web
mvn clean install -P dev  # Para perfil DEV
```

### PASO 4: Desplegar nuevo WAR

```powershell
# Detener Tomcat
Stop-Service Tomcat9 -Force

# Limpiar cache
Remove-Item "C:\tomcat\webapps\FEDIPortalWeb-1.0" -Recurse -Force
Remove-Item "C:\tomcat\work\Catalina\localhost\*" -Recurse -Force

# Copiar nuevo WAR
Copy-Item "C:\github\fedi-web\target\FEDIPortalWeb-1.0.war" -Destination "C:\tomcat\webapps\"

# Iniciar Tomcat
Start-Service Tomcat9
Start-Sleep -Seconds 45

# Verificar
Get-Content "C:\tomcat\logs\catalina.out" -Tail 50 | Select-String "FEDIPortalWeb|started|ERROR"
```

### PASO 5: Probar

```powershell
# Desde navegador o PowerShell:
# Ir a: http://[fedi-web-url]/FEDIPortalWeb/
# Intentar guardar documento
# Verificar logs en tiempo real:

Get-Content "C:\tomcat\logs\catalina.out" -Wait -Tail 50
```

---

## 📊 Cambio de URLs Esperado

### ANTES (con API Manager)
```
fedi-web → https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios
           ↓ (routing...)
fedi-srv → GET /catalogos/consultarUsuarios
⏱️ Resultado: 120+ segundos (timeout)
```

### DESPUÉS (directo)
```
fedi-web → http://localhost:8080/srvFEDIApi/catalogos/consultarUsuarios
           ↓ (directo!)
fedi-srv → GET /catalogos/consultarUsuarios
⏱️ Resultado: < 5 segundos (esperado)
```

---

## 🚨 Troubleshooting

### Error: Connection Refused
```
Error: Unable to connect to http://localhost:8080/srvFEDIApi
```

**Solución:**
1. Verifica que fedi-srv esté desplegado en Tomcat
2. Verifica que Tomcat esté corriendo: `Get-Service Tomcat9`
3. Prueba directamente: `Invoke-WebRequest http://localhost:8080/srvFEDIApi/`

### Error: Connection Timeout (CORS/Firewall)
```
Error: Connection timeout after 120 seconds
```

**Solución:**
1. Verifica conectividad: `Test-NetConnection -ComputerName [host] -Port 8080`
2. Verifica firewall permite puerto 8080
3. Verifica IP/hostname correcto

### Error: 404 Not Found
```
HTTP 404: /srvFEDIApi/catalogos/consultarUsuarios
```

**Solución:**
1. Verifica que el WAR se desplegó correctamente
2. Verifica el nombre del contexto en Tomcat (debería ser `srvFEDIApi`)
3. Verifica en `C:\tomcat\webapps\` que exista la carpeta `srvFEDIApi`

---

## 📝 Checklists

### Pre-Cambio
- [ ] ¿Sabes dónde está desplegado fedi-srv?
- [ ] ¿Puedes acceder a fedi-srv localmente? (`http://[host]:8080/srvFEDIApi/`)
- [ ] ¿Tomcat tiene acceso de red a fedi-srv?
- [ ] ¿Conoces el IP o hostname de fedi-srv?

### Post-Cambio
- [ ] ¿Compiló sin errores?
- [ ] ¿Tomcat arrancó sin errores?
- [ ] ¿Las peticiones ahora van directas a fedi-srv?
- [ ] ¿Se ve reducción de tiempo (de 120s a < 5s)?
- [ ] ¿Los logs de fedi-srv [DIAG] ahora aparecen?

---

## 💡 Verificación Rápida

**En logs de fedi-web, deberías ver:**

### CON API Manager (❌ Actual)
```
[INFO] *** [DIAG-WEB] Llamando API: https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios
[ERROR] IOException. Error=timeout, Duracion=120096ms
```

### SIN API Manager (✅ Esperado)
```
[INFO] *** [DIAG-WEB] Llamando API: http://localhost:8080/srvFEDIApi/catalogos/consultarUsuarios
[INFO] *** [DIAG-WEB] Respuesta recibida. Duracion: 2345ms, Tamano: 5432 chars
[INFO] *** [DIAG-WEB] JSON parseado exitosamente
```

**En logs de fedi-srv, deberías ver:**
```
[DIAG] REST /catalogos/consultarUsuarios - Peticion recibida
[DIAG] CatalogoServiceImpl.consultarUsuarios() - INICIO
[DIAG] obtenUsuarios() completado. Duracion: 123ms
[DIAG] REST /catalogos/consultarUsuarios - Respuesta exitosa
```

---

## 🎯 Conclusión

**Cambiar URL es trivial** (1 cambio en pom.xml × 3 profiles):
1. Edita pom.xml
2. Compila WAR
3. Despliega
4. Prueba

**Resultado esperado:**
- ✅ Sin timeout de 120s
- ✅ Respuesta en < 5 segundos
- ✅ Logs de fedi-srv aparecen
- ✅ Documento se guarda correctamente

