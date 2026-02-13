# ⚙️ CONFIGURACIONES POR AMBIENTE

**Actualizar estas URLs en `pom.xml` según tu ambiente**

---

## 🖥️ AMBIENTE DEV (Línea ~810)

### Si fedi-srv está en mismo servidor (localhost):

```xml
<profile.fedi.direct.url>http://localhost:8080/srvFEDIApi/</profile.fedi.direct.url>
```

### Si fedi-srv está en otro servidor:

```xml
<!-- Por IP -->
<profile.fedi.direct.url>http://192.168.1.100:8080/srvFEDIApi/</profile.fedi.direct.url>

<!-- Por hostname -->
<profile.fedi.direct.url>http://fedi-srv-dev.interna.mx:8080/srvFEDIApi/</profile.fedi.direct.url>

<!-- Con HTTPS (si está configurado) -->
<profile.fedi.direct.url>https://fedi-srv-dev.interna.mx:8443/srvFEDIApi/</profile.fedi.direct.url>
```

---

## 🏢 AMBIENTE QA (Línea ~869)

### Si fedi-srv está en la red interna QA:

```xml
<!-- Por IP (ejemplo: 172.17.42.xx) -->
<profile.fedi.direct.url>http://172.17.42.XX:8080/srvFEDIApi/</profile.fedi.direct.url>

<!-- Por hostname QA -->
<profile.fedi.direct.url>http://fedi-srv-qa.ift.org.mx:8080/srvFEDIApi/</profile.fedi.direct.url>

<!-- Con HTTPS -->
<profile.fedi.direct.url>https://fedi-srv-qa.ift.org.mx:8443/srvFEDIApi/</profile.fedi.direct.url>
```

---

## 🔒 AMBIENTE PRODUCTION (Línea ~918)

### Producción - URL segura:

```xml
<!-- Por hostname con HTTPS (RECOMENDADO) -->
<profile.fedi.direct.url>https://fedi-srv.ift.org.mx:8443/srvFEDIApi/</profile.fedi.direct.url>

<!-- Alternativa: Por IP si no hay DNS -->
<profile.fedi.direct.url>https://203.0.113.50:8443/srvFEDIApi/</profile.fedi.direct.url>

<!-- Si es HTTP (no recomendado en PROD) -->
<profile.fedi.direct.url>http://fedi-srv.ift.org.mx:8080/srvFEDIApi/</profile.fedi.direct.url>
```

---

## 🔍 Cómo Descubrir la URL Correcta

### Opción 1: Preguntar al equipo de infraestructura

```
¿En qué servidor:puerto está desplegado srvFEDIApi?
Respuesta esperada: srv-fedi-dev.dominio.mx:8080 o 192.168.1.100:8080
```

### Opción 2: Verificar en Tomcat (si tienes acceso SSH)

```bash
# En el servidor de fedi-srv
ps aux | grep -i tomcat
# Ver qué puerto está listening
netstat -tuln | grep 8080

# Probar localmente
curl http://localhost:8080/srvFEDIApi/
# Esperado: HTTP 200 o similar (no timeout)
```

### Opción 3: Revisar documentación de deployment

Buscar en archivos:
- `tomcat/webapps/srvFEDIApi/`
- Logs de deployment
- Configuración de API Manager

---

## 🧪 Verificar Conectividad

Antes de hacer cambios, verificar que la URL es correcta:

### Desde Windows PowerShell (fedi-web server):

```powershell
# Test 1: Ping a la máquina
ping [HOST]
# Esperado: Reply from...

# Test 2: Puerto abierto
Test-NetConnection -ComputerName "[HOST]" -Port 8080
# Esperado: TcpTestSucceeded: True

# Test 3: Endpoint accesible
$url = "http://[HOST]:8080/srvFEDIApi/catalogos/consultarUsuarios"
$response = Invoke-WebRequest -Uri $url -ErrorAction SilentlyContinue
$response.StatusCode
# Esperado: 200 (o error JSON, pero NO timeout)
```

### Desde línea de comandos:

```powershell
# Verificar conectividad
telnet [HOST] 8080
# Esperado: Connected (no timeout)
```

---

## 📋 Plantilla Rápida

**Editar exactamente estas líneas en pom.xml:**

### Línea ~810 (DEV)
```xml
ANTES:
<profile.fedi.direct.url>http://localhost:8080/srvFEDIApi/</profile.fedi.direct.url>

DESPUÉS (ajusta según tu caso):
<profile.fedi.direct.url>http://[REEMPLAZA-AQUI]:8080/srvFEDIApi/</profile.fedi.direct.url>
```

### Línea ~869 (QA)
```xml
ANTES:
<profile.fedi.direct.url>http://localhost:8080/srvFEDIApi/</profile.fedi.direct.url>

DESPUÉS (ajusta según tu caso):
<profile.fedi.direct.url>http://[REEMPLAZA-AQUI]:8080/srvFEDIApi/</profile.fedi.direct.url>
```

### Línea ~918 (PROD)
```xml
ANTES:
<profile.fedi.direct.url>http://localhost:8080/srvFEDIApi/</profile.fedi.direct.url>

DESPUÉS (ajusta según tu caso):
<profile.fedi.direct.url>http://[REEMPLAZA-AQUI]:8080/srvFEDIApi/</profile.fedi.direct.url>
```

---

## 💡 Ejemplos Concretos

### Ejemplo 1: Mismo servidor

```xml
<profile.fedi.direct.url>http://localhost:8080/srvFEDIApi/</profile.fedi.direct.url>
```

### Ejemplo 2: Otro servidor en red interna (IP)

```xml
<profile.fedi.direct.url>http://192.168.1.50:8080/srvFEDIApi/</profile.fedi.direct.url>
```

### Ejemplo 3: Otro servidor con DNS (QA)

```xml
<profile.fedi.direct.url>http://app-server-qa.ift.org.mx:8080/srvFEDIApi/</profile.fedi.direct.url>
```

### Ejemplo 4: HTTPS en Producción

```xml
<profile.fedi.direct.url>https://app-server-prod.ift.org.mx:8443/srvFEDIApi/</profile.fedi.direct.url>
```

### Ejemplo 5: Con puerto no estándar

```xml
<profile.fedi.direct.url>http://app-server:9090/srvFEDIApi/</profile.fedi.direct.url>
```

---

## ✅ Script de Actualización Rápida

Si tienes el script `cambiar-url-directa.bat` en tu equipo:

```powershell
# DEV
C:\github\Colaboracion\cambiar-url-directa.bat DEV localhost 8080

# QA
C:\github\Colaboracion\cambiar-url-directa.bat QA 192.168.1.50 8080

# PROD
C:\github\Colaboracion\cambiar-url-directa.bat PROD app-server-prod.ift.org.mx 8443
```

El script:
1. Hace backup de pom.xml
2. Actualiza la URL en el ambiente especificado
3. Muestra instrucciones para compilar y desplegar

---

## 🚫 No Olvides

- [ ] **Probar conectividad ANTES** de cambiar el pom.xml
- [ ] **Hacer backup** de pom.xml (el script lo hace automáticamente)
- [ ] **Cambiar la URL en TODOS los profiles** que uses (DEV, QA, PROD)
- [ ] **Compilar DESPUÉS** de cambiar pom.xml
- [ ] **Desplegar el WAR nuevo** (viejo con API Manager no sirve de nada)
- [ ] **Esperar 45 segundos** a que Tomcat levante
- [ ] **Probar** guardando un documento

---

## 🔄 Cambiar de Opinión

Si en algún momento quieres volver a API Manager:

### Opción 1: Simple
```xml
<!-- Simplemente comenta la línea -->
<!-- <profile.fedi.direct.url>http://localhost:8080/srvFEDIApi/</profile.fedi.direct.url> -->
```

El código automáticamente usará `fedi.url` (API Manager)

### Opción 2: Restaurar desde backup
```powershell
# Si hiciste backup
Copy-Item "C:\github\fedi-web\pom.xml.backup" "C:\github\fedi-web\pom.xml"
```

---

## 📞 Contacto

Si no sabes qué URL usar:
1. Pregunta: "¿Dónde está desplegado srvFEDIApi?"
2. Respuesta esperada: "En app-server-qa.ift.org.mx:8080" o "En 192.168.1.50:8080"
3. Usa esa URL en pom.xml

