# Guía de Despliegue y Diagnóstico - FEDI con Logs Mejorados

## 📦 WARs Generados (11-Feb-2026 19:03)

### Archivos Listos para Desplegar
- **fedi-srv**: `C:\github\fedi-srv\target\srvFEDIApi-1.0.war` (35.7 MB)
- **fedi-web**: `C:\github\fedi-web\target\FEDIPortalWeb-1.0.war` (98.8 MB)

---

## 🔧 Mejoras Implementadas

### 1. Logs de Diagnóstico Agregados

#### fedi-srv (Backend)
**CatalogosResources.java** - REST Endpoint
```java
*** [DIAG] REST /catalogos/consultarUsuarios - Peticion recibida
*** [DIAG] REST /catalogos/consultarUsuarios - Respuesta exitosa. Duracion: XXXms
*** [DIAG] REST /catalogos/consultarUsuarios - ERROR despues de XXXms
```

**CatalogoServiceImpl.java** - Service Layer
```java
*** [DIAG] CatalogoServiceImpl.consultarUsuarios() - INICIO
*** [DIAG] Llamando catUsuarioMapper.obtenUsuarios()...
*** [DIAG] obtenUsuarios() completado. Usuarios encontrados: XX, Duracion: XXXms
*** [DIAG] consultarUsuarios() - Retornando XX usuarios con code=102
*** [DIAG] ERROR en consultarUsuarios despues de XXXms
```

**FEDIServiceImpl.java** - cargarDocumentos
```java
*** INICIO fedi() - Procesando: XX documentos
*** [DIAG] JSON generado, tamaño: XXXXX chars
*** Usando SQL DIRECTO (sin SPs)  ← NUEVO
*** SQL DIRECTO cargarDocumentos() tardó: XXXms  ← OPTIMIZADO
*** BD cargarDocumentos() tardó: XXXms  ← FALLBACK a SP
*** [DIAG] fedi.getDocumentosID() disponible: true/false
*** BD SUCCESS - Parseando respuesta JSON
*** MATCH: documento.pdf
*** Guardando en FS: XX documentos
*** FS OK: documento.pdf
*** FIN cargarDocumentos - Exitosos: XX, Fallos: XX
```

#### fedi-web (Frontend)
**FEDIServiceImpl.java** - API Client
```java
*** [DIAG-WEB] FEDIServiceImpl.obtenerCatUsuarios() - INICIO
*** [DIAG-WEB] Obteniendo token de acceso...
*** [DIAG-WEB] Llamando API: https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios
*** [DIAG-WEB] Respuesta recibida. Duracion: XXXms, Tamano: XXXX chars
*** [DIAG-WEB] JSON parseado exitosamente
*** [DIAG-WEB] ERROR en obtenerCatUsuarios despues de XXXms
```

### 2. Optimización SQL Directo (Incluida)
- `FEDIMapperDirect` - Mapper para SQL directo
- `FEDI_DIRECT.xml` - Mappings optimizados sin Stored Procedures
- Integración en `FEDIServiceImpl.fedi()` con fallback automático a SPs

---

## 🚀 Pasos de Despliegue

### 1. Copiar WARs al Servidor

**Desde tu máquina local:**
```powershell
# Copiar fedi-srv
Copy-Item "C:\github\fedi-srv\target\srvFEDIApi-1.0.war" `
          "\\172.17.42.105\webapps\" -Force

# Copiar fedi-web
Copy-Item "C:\github\fedi-web\target\FEDIPortalWeb-1.0.war" `
          "\\172.17.42.105\webapps\" -Force
```

**Desde el servidor (Windows Server 2016):**
```powershell
# Verificar que los WARs llegaron
dir C:\tomcat\webapps\*.war
```

### 2. Hacer Backup de WARs Actuales

```powershell
# Crear carpeta de backup con fecha
$fecha = Get-Date -Format "yyyy-MM-dd_HHmm"
New-Item -ItemType Directory -Path "C:\backup\$fecha" -Force

# Copiar WARs actuales antes de reemplazar
Copy-Item "C:\tomcat\webapps\srvFEDIApi-1.0.war" "C:\backup\$fecha\" -Force
Copy-Item "C:\tomcat\webapps\FEDIPortalWeb-1.0.war" "C:\backup\$fecha\" -Force

# Copiar carpetas desplegadas también (opcional)
Copy-Item "C:\tomcat\webapps\srvFEDIApi-1.0" "C:\backup\$fecha\" -Recurse -Force
Copy-Item "C:\tomcat\webapps\FEDIPortalWeb-1.0" "C:\backup\$fecha\" -Recurse -Force
```

### 3. Detener Tomcat

```powershell
# Ver servicio
Get-Service | Where-Object {$_.Name -like "*tomcat*"}

# Detener servicio (ajustar nombre si es diferente)
Stop-Service -Name "Tomcat9" -Force

# O si es servicio con otro nombre
net stop Tomcat9

# Verificar que se detuvo
Get-Process java -ErrorAction SilentlyContinue
```

### 4. Limpiar Despliegue Anterior

```powershell
# Eliminar carpetas desplegadas
Remove-Item "C:\tomcat\webapps\srvFEDIApi-1.0" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\tomcat\webapps\FEDIPortalWeb-1.0" -Recurse -Force -ErrorAction SilentlyContinue

# Eliminar WARs viejos
Remove-Item "C:\tomcat\webapps\srvFEDIApi-1.0.war" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\tomcat\webapps\FEDIPortalWeb-1.0.war" -Force -ErrorAction SilentlyContinue

# Limpiar work y temp de Tomcat
Remove-Item "C:\tomcat\work\Catalina\localhost\srvFEDIApi-1.0" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\tomcat\work\Catalina\localhost\FEDIPortalWeb-1.0" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\tomcat\temp\*" -Recurse -Force -ErrorAction SilentlyContinue
```

### 5. Copiar Nuevos WARs

```powershell
# Copiar WARs nuevos (ajustar ruta origen si está en otra ubicación)
Copy-Item "C:\deployment\srvFEDIApi-1.0.war" "C:\tomcat\webapps\" -Force
Copy-Item "C:\deployment\FEDIPortalWeb-1.0.war" "C:\tomcat\webapps\" -Force

# Verificar tamaños
Get-ChildItem "C:\tomcat\webapps\*.war" | Select-Object Name, Length, LastWriteTime
```

### 6. Iniciar Tomcat

```powershell
# Iniciar servicio
Start-Service -Name "Tomcat9"

# O con net start
net start Tomcat9

# Verificar que arrancó
Get-Process java
Get-Service | Where-Object {$_.Name -like "*tomcat*"}
```

### 7. Monitorear Logs en Tiempo Real

**Terminal 1 - Logs de Tomcat:**
```powershell
# Ver logs generales
Get-Content "C:\tomcat\logs\catalina.out" -Wait -Tail 50

# O con Select-String para filtrar
Get-Content "C:\tomcat\logs\catalina.out" -Wait -Tail 100 | Select-String -Pattern "DIAG|ERROR|INICIO|SQL DIRECTO"
```

**Terminal 2 - Logs de fedi-srv:**
```powershell
# Buscar archivo de log de fedi-srv (ubicación puede variar)
Get-Content "C:\tomcat\logs\fedi-srv.log" -Wait -Tail 50 | Select-String -Pattern "\*\*\*"
```

**Terminal 3 - Logs de fedi-web:**
```powershell
Get-Content "C:\tomcat\logs\fedi-web.log" -Wait -Tail 50 | Select-String -Pattern "\*\*\*"
```

---

## 🔍 Qué Buscar en los Logs

### Escenario 1: consultarUsuarios funcionando
```
*** [DIAG] REST /catalogos/consultarUsuarios - Peticion recibida
*** [DIAG] CatalogoServiceImpl.consultarUsuarios() - INICIO
*** [DIAG] Llamando catUsuarioMapper.obtenUsuarios()...
*** [DIAG] obtenUsuarios() completado. Usuarios encontrados: 150, Duracion: 2500ms
*** [DIAG] consultarUsuarios() - Retornando 150 usuarios con code=102
*** [DIAG] REST /catalogos/consultarUsuarios - Respuesta exitosa. Duracion: 2800ms
```

✅ **Si ves esto**: El servicio responde correctamente en ~3 segundos

### Escenario 2: consultarUsuarios con timeout
```
*** [DIAG] REST /catalogos/consultarUsuarios - Peticion recibida
*** [DIAG] CatalogoServiceImpl.consultarUsuarios() - INICIO
*** [DIAG] Llamando catUsuarioMapper.obtenUsuarios()...
(espera 120 segundos...)
*** [DIAG] ERROR en consultarUsuarios despues de 120065ms
```

❌ **Si ves esto**: SP_CONSULTA_USUARIOS está bloqueado o BD tiene problemas

### Escenario 3: cargarDocumentos con SQL Directo (ÉXITO)
```
*** INICIO cargarDocumentos - Total: 5 documentos
*** INICIO fedi() - Procesando: 5 documentos
*** [DIAG] JSON generado, tamaño: 12500 chars
*** Usando SQL DIRECTO (sin SPs)
*** SQL DIRECTO cargarDocumentos() tardó: 4500ms
*** BD SUCCESS - Parseando respuesta JSON
*** [DIAG] fedi.getDocumentosID() disponible: true
*** MATCH: documento1.pdf
*** Guardando en FS: 5 documentos
*** FS OK: documento1.pdf
...
*** FIN cargarDocumentos - Exitosos: 5, Fallos: 0
```

✅ **Si ves esto**: SQL Directo funcionando perfectamente (~4.5s para 5 docs)

### Escenario 4: cargarDocumentos con SP (FALLBACK)
```
*** INICIO cargarDocumentos - Total: 5 documentos
*** INICIO fedi() - Procesando: 5 documentos
*** [DIAG] JSON generado, tamaño: 12500 chars
(NO dice "Usando SQL DIRECTO")
*** BD cargarDocumentos() tardó: 85000ms
```

⚠️ **Si ves esto**: Cayó al SP (fediMapperDirect no inyectado), tardó 85 segundos

---

## 🧪 Plan de Pruebas

### Prueba 1: Verificar consultarUsuarios
1. Hacer login en fedi-web
2. Esperar a que cargue página principal
3. Revisar logs: buscar `[DIAG] consultarUsuarios`
4. **Tiempo esperado**: 2-5 segundos
5. **Tiempo actual (con problema)**: 120 segundos (TIMEOUT)

### Prueba 2: Guardar 1 Documento
1. Login exitoso
2. Ir a "Cargar Documentos"
3. Subir 1 PDF pequeño (~2 MB)
4. Agregar 2 firmantes
5. Guardar
6. Revisar logs: buscar `*** INICIO cargarDocumentos`
7. **Tiempo esperado con SQL Directo**: 3-8 segundos
8. **Tiempo con SP**: 30-60 segundos

### Prueba 3: Guardar Múltiples Documentos
1. Subir 5 PDFs
2. Agregar 3 firmantes cada uno
3. Guardar
4. Revisar logs
5. **Tiempo esperado con SQL Directo**: 10-20 segundos
6. **Tiempo con SP**: 90-120 segundos (TIMEOUT probable)

---

## 📊 Interpretación de Resultados

### Si consultarUsuarios FUNCIONA (< 5 segundos):
→ **fedi-srv está corriendo correctamente**
→ Problema anterior era temporal o de red
→ Continuar con prueba de cargarDocumentos

### Si consultarUsuarios sigue con TIMEOUT:
→ **Problema de BD o SP_CONSULTA_USUARIOS**
→ Revisar:
  - Estado de SQL Server
  - Bloqueos en tabla `cat_Usuarios`
  - Índices faltantes

### Si cargarDocumentos muestra "Usando SQL DIRECTO":
→ **✅ OPTIMIZACIÓN ACTIVA**
→ Tiempos deben ser 6-7x más rápidos
→ Documentar mejora con capturas de logs

### Si cargarDocumentos NO muestra "Usando SQL DIRECTO":
→ **⚠️ FALLBACK A SPs**
→ Causas posibles:
  - MyBatis no cargó FEDI_DIRECT.xml
  - Spring no inyectó FEDIMapperDirect
  - Revisar logs de startup de Tomcat

---

## 🔄 Rollback (Si es Necesario)

```powershell
# Detener Tomcat
Stop-Service -Name "Tomcat9" -Force

# Restaurar WARs anteriores
$fecha = "2026-02-11_1800"  # Ajustar a tu backup
Copy-Item "C:\backup\$fecha\srvFEDIApi-1.0.war" "C:\tomcat\webapps\" -Force
Copy-Item "C:\backup\$fecha\FEDIPortalWeb-1.0.war" "C:\tomcat\webapps\" -Force

# Limpiar despliegue actual
Remove-Item "C:\tomcat\webapps\srvFEDIApi-1.0" -Recurse -Force
Remove-Item "C:\tomcat\webapps\FEDIPortalWeb-1.0" -Recurse -Force

# Iniciar Tomcat
Start-Service -Name "Tomcat9"
```

---

## 📝 Checklist de Despliegue

- [ ] Backup de WARs actuales realizado
- [ ] Tomcat detenido correctamente
- [ ] Carpetas desplegadas eliminadas
- [ ] Nuevos WARs copiados a webapps
- [ ] Tomcat iniciado
- [ ] Logs monitoreándose (3 terminales)
- [ ] Login en fedi-web exitoso
- [ ] consultarUsuarios < 5 segundos
- [ ] Documento de prueba guardado exitosamente
- [ ] Logs muestran "Usando SQL DIRECTO"
- [ ] Tiempos de guardado < 20 segundos
- [ ] Capturas de logs guardadas para reporte

---

## 🎯 Próximos Pasos Después del Despliegue

1. **Capturar logs completos** de una ejecución exitosa
2. **Generar reporte de mejora** con comparación antes/después
3. **Documentar benchmarks** para futuras optimizaciones
4. **Compartir resultados** con equipo de desarrollo y QA
5. **Planear despliegue a producción** si pruebas son exitosas

---

## 📞 Puntos de Contacto

Si encuentras problemas durante el despliegue, documenta:
- Timestamp exacto del error
- Líneas de log relevantes (con `*** [DIAG]`)
- Comportamiento observado vs esperado
- Capturas de pantalla de errores en UI
