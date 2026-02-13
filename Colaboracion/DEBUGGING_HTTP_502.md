# Guía de Debugging: HTTP 502 en cargarDocumentos()

## 📋 Resumen del Problema

Cuando el usuario intenta guardar documentos en FEDI, la llamada a `fediService.cargarDocumentos()` falla con **HTTP 502 Bad Gateway**.

## 🔍 Análisis del Flujo

### Flujo de Guardado de Documentos

```
1. fedi-web (DocumentoVistaFirmaMB)
   └─> Llama: fediService.cargarDocumentos(requestFinal)
   
2. fedi-web (FEDIServiceImpl)
   └─> Llama: mDSeguridadService.EjecutaMetodoPOST(...) 
   └─> URL: https://apimanager-dev.ift.org.mx/FEDI/v1.0/fedi/cargarDocumentos
   
3. API Manager
   └─> Enruta hacia fedi-srv/cargarDocumentos
   
4. fedi-srv (FEDIServiceImpl.cargarDocumentos())
   ├─ PASO 1: Genera rutas de archivo (generarRutaDocFS)
   │         └─ Resultado: C:\fedi_docs\{idUsuario}\{timestamp}\{nombreDoc}
   │
   ├─ PASO 2: Divide documentos en lotes (máx 7)
   │         └─ Motivo: SP no retorna bien JSON si hay >7 docs
   │
   ├─ PASO 3: Llama FEDIMapper.cargarDocumentos(fedi)
   │         └─ ⚠️ AQUÍ SE EJECUTA STORED PROCEDURE EN BD
   │         └─ Tiempo esperado: 1-5 segundos
   │         └─ ⏱️ SI TARDÁ >120s: API Manager timeout → HTTP 502
   │
   ├─ PASO 4: Parseá respuesta JSON del SP
   │         └─ 🔴 SI JSON malformado: JsonSyntaxException → HTTP 502
   │
   └─ PASO 5: Guarda en filesystem
              └─ Método: guardarDocEnFS(req)
              └─ 🔴 SI falla: IOException → HTTP 502
```

## 🔴 Puntos de Fallo Potenciales

### 1️⃣ **STORED PROCEDURE en BD (MÁS PROBABLE)**

**Síntoma:** 
- Logs de fedi-srv muestran timeout
- API Manager cancela conexión

**Causa Raíz Probable:**
- SP toma > 120 segundos
- Query sin índices (consultarUsuarios lento)
- Locks en tabla `solicitud_documento`
- Conexión a BD rechazada

**Debugging:**
```sql
-- EN LA BD DE FEDI:

-- 1. Ver si el SP existe
EXEC sp_help 'nombre_del_sp';  -- Cambia por el SP real

-- 2. Ejecutar SP manualmente y ver tiempo
SET STATISTICS TIME ON;
EXEC [SP_nombre] @parametros;
SET STATISTICS TIME OFF;

-- 3. Ver si hay locks
SELECT * FROM sys.dm_tran_locks WHERE request_status = 'WAIT';

-- 4. Ver índices en tabla solicitud_documento
EXEC sp_helpindex 'solicitud_documento';

-- 5. Ver último estado
SELECT TOP 10 * FROM solicitud_documento ORDER BY fecha_creacion DESC;
```

---

### 2️⃣ **Error en Génesis de Ruta (POCO PROBABLE)**

**Síntoma:**
- Logs muestran error en `generarRutaDocFS()`
- Excepción: `PersistFileException`

**Causa Raíz Probable:**
- Usuario que corre fedi-srv SIN permisos en `C:\fedi_docs\`
- Carpeta `C:\fedi_docs\` NO existe
- Ruta inválida (caracteres especiales)

**Debugging:**
```powershell
# En Windows 2016 server (172.17.42.105):

# 1. Verificar que carpeta existe
Test-Path 'C:\fedi_docs'

# 2. Ver permisos
icacls 'C:\fedi_docs'

# 3. Ver quién corre Tomcat/fedi-srv
Get-Process | Where { $_.ProcessName -match 'java|tomcat' } | Select UserName

# 4. Crear carpeta si no existe
New-Item -Path 'C:\fedi_docs' -ItemType Directory -Force

# 5. Dar permisos
icacls 'C:\fedi_docs' /grant 'IFT\usuario_fedi_srv:(OI)(CI)F'
```

---

### 3️⃣ **Error en Parseó JSON (POCO PROBABLE)**

**Síntoma:**
- Logs: `JsonSyntaxException`
- SP retorna formato inesperado

**Causa Raíz:**
- SP retorna columna adicional/faltante
- Valor NULL donde no se espera
- Cambio en SP sin actualizar código Java

**Debugging:**
```sql
-- Ejecutar SP y ver JSON que retorna
EXEC [SP_cargarDocumentos] @parametros;

-- El resultado debe ser JSON válido como:
-- [
--   {"idDocumento":1, "nombreDocumento":"file.pdf", "hash":"abc123"},
--   {"idDocumento":2, "nombreDocumento":"file2.pdf", "hash":"def456"}
-- ]
```

---

### 4️⃣ **Error al Guardar en Filesystem (POSIBLE)**

**Síntoma:**
- Logs: `guardarDocEnFS() retorna false`
- O: `IOException al escribir archivo`

**Causa Raíz:**
- Disco lleno en Windows 2016
- Archivo bloqueado por antivirus
- Permisos insuficientes

**Debugging:**
```powershell
# 1. Ver espacio en disco
Get-Volume | Where { $_.DriveLetter -eq 'C' } | Select Size, SizeRemaining

# 2. Ver archivos en fedi_docs
Get-ChildItem 'C:\fedi_docs' -Recurse | Measure-Object -Sum -Property Length

# 3. Revisar evento de antivirus
# - Abrir Windows Defender
# - Threat history → Ver si bloquea archivos
```

---

## 🔧 Mejoras de Logging Aplicadas

He mejorado el logging en `fedi-srv\FEDIServiceImpl.java` para que ahora muestre:

### **En el método `cargarDocumentos()`:**
```
*** INICIO cargarDocumentos - Total: 2 documentos
*** BD cargarDocumentos() tardó: 3240ms, ErrorCode: 0, Error: null
*** Guardando en FS: 2 documentos
*** FS OK: documento1.pdf
*** FS OK: documento2.pdf
*** FS COMPLETADO - Exitosos: 2, Fallos: 0
*** FIN cargarDocumentos - Exitosos: 2 docs, Fallos: 0 docs
```

### **En el método `fedi()` (interno):**
```
*** INICIO fedi() - Procesando: 2 documentos
*** BD cargarDocumentos() tardó: 3240ms, ErrorCode: 0, Error: null
*** BD SUCCESS - Parseando respuesta JSON
*** MATCH: documento1.pdf
*** Guardando FS: documento1.pdf para usuario: hector@ift.org.mx
*** FS OK: documento1.pdf
*** FS COMPLETADO - Exitosos: 2, Fallos: 0
*** FIN fedi() - ResponseCode: 102
```

---

## 📍 Dónde Revisar los Logs

### **Opción 1: Logs en fedi-srv**
```
Ubicación típica: 
  C:\Program Files\Tomcat\logs\fedi-srv\
  O: C:\fedi_logs\
  O: /var/log/tomcat/

Busca patrones:
  *** INICIO cargarDocumentos
  *** BD ERROR
  *** FS FAIL
```

### **Opción 2: Logs en fedi-web**
```
C:\Program Files\Tomcat\logs\fedi-web\

Línea clave:
  FEDIServiceImpl.cargarDocumentos(): Failed : HTTP error code : 502
```

### **Opción 3: Via SSH/RDP a 172.17.42.105**
```powershell
# Conectar a servidor Windows 2016
$session = New-PSSession -ComputerName 172.17.42.105 -Credential (Get-Credential)

# Leer logs en tiempo real
Invoke-Command -Session $session -ScriptBlock {
  Get-Content 'C:\Program Files\Tomcat\logs\*.log' -Tail 50 -Wait
}
```

---

## ✅ Plan de Acción Recomendado

### **Paso 1: Compilar fedi-srv actualizado** ✅ HECHO
- Ya compilé fedi-srv con logging mejorado
- Archivo: `C:\github\fedi-srv\target\srvFEDIApi.war`

### **Paso 2: Desplegar WAR en servidor**
```powershell
# En 172.17.42.105:

# 1. Detener Tomcat
net stop Tomcat9

# 2. Respaldar WAR viejo
Copy-Item 'C:\Program Files\Tomcat\webapps\srvFEDIApi.war' -Destination 'backup_$(Get-Date -Format yyyyMMdd).war'

# 3. Copiar WAR nuevo
Copy-Item 'C:\github\fedi-srv\target\srvFEDIApi.war' -Destination 'C:\Program Files\Tomcat\webapps\srvFEDIApi.war'

# 4. Iniciar Tomcat
net start Tomcat9

# 5. Esperar 30 segundos a que se inicie
Start-Sleep -Seconds 30

# 6. Ver logs iniciales
Get-Content 'C:\Program Files\Tomcat\logs\catalina.log' -Tail 20
```

### **Paso 3: Probar guardado de documento**
- Ir a fedi-web en navegador
- Login
- Intentar cargar documento
- Revisar logs del servidor

### **Paso 4: Revisar logs específicos**
```powershell
# Buscar líneas con *** para ver flujo completo
Select-String -Path 'C:\Program Files\Tomcat\logs\*.log' -Pattern '\*\*\*'
```

### **Paso 5: Verificar BD (si logs muestran error BD)**
Contactar al DBA para:
- Ejecutar SP manualmente
- Ver tiempo de ejecución
- Revisar índices
- Ver si hay locks

### **Paso 6: Verificar filesystem (si logs muestran error FS)**
```powershell
# Revisar permisos y espacio
Test-Path 'C:\fedi_docs'
icacls 'C:\fedi_docs'
Get-Volume -DriveLetter C | Select SizeRemaining
```

---

## 🎯 Checklist de Validación

- [ ] fedi-srv compilado exitosamente
- [ ] WAR actualizado desplegado en Tomcat
- [ ] Tomcat reiniciado
- [ ] Intentar guardar documento
- [ ] Revisar logs para líneas `*** `
- [ ] Identificar en qué PASO falla:
  - [ ] PASO 1: Generación de rutas
  - [ ] PASO 2: BD cargarDocumentos()
  - [ ] PASO 3: Parseó JSON
  - [ ] PASO 4: FS guardarDocEnFS()
- [ ] Ejecutar comando debugging correspondiente
- [ ] Reportar resultado exacto

---

## 📞 Información para IT/OPS

Cuando contactes al equipo de infraestructura, proporciona:

1. **Logs exactos** del servidor 172.17.42.105 (líneas con `***`)
2. **Tiempo que tardó** BD (`*** BD cargarDocumentos() tardó: Xms`)
3. **Punto exacto de falla** (que PASO falla)
4. **Permisos en C:\fedi_docs\** (¿quién corre Tomcat?)
5. **Espacio en disco C:** (¿está lleno?)
6. **Estado del SP en BD** (¿existe? ¿funciona?)

---

## 🔗 Referencias

- **fedi-srv código:** `C:\github\fedi-srv\src\main\java\fedi\srv\ift\org\mx\service\FEDIServiceImpl.java`
- **Línea inicio logging:** ~202 (cargarDocumentos)
- **Línea método fedi():** ~260
- **Método filesystem:** guardarDocEnFS() ~950
- **WAR compilado:** `C:\github\fedi-srv\target\srvFEDIApi.war`
