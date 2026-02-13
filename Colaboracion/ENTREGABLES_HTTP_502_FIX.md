# 📦 ENTREGABLES: Análisis & Fixes HTTP 502

## Estado de los Cambios

### ✅ Compilación Exitosa

```
✓ fedi-srv compilado exitosamente
  └─ Archivo: C:\github\fedi-srv\target\srvFEDIApi-1.0.war (34.01 MB)
  └─ Cambios: Logging mejorado en cargarDocumentos() y fedi()
  └─ Status: LISTO PARA DESPLEGAR

✓ fedi-web compilado exitosamente  
  └─ Archivo: C:\github\fedi-web\target\FEDIPortalWeb-1.0.war (94.2 MB)
  └─ Cambios: Ninguno (pero validado como compatible)
  └─ Status: LISTO PARA DESPLEGAR
```

---

## 🎯 Cambios Realizados

### **En fedi-srv (FEDIServiceImpl.java)**

#### Método: `cargarDocumentos()` (líneas 202-270)

**Logging añadido:**
```java
// Al inicio
LOGGER.info("*** INICIO cargarDocumentos - Total: " + totalDocs + " documentos");

// Al completar
LOGGER.info("*** Procesando segundo lote: " + (tamanio-7) + " documentos");

// Al finalizar
LOGGER.info("*** FIN cargarDocumentos - Exitosos: " + listDocsGuardados.size() + ", Fallos: " + listDocsNoGuardados.size());

// Catch blocks mejorados
LOGGER.error("*** ERROR PersistFileException en cargarDocumentos: " + e.getMessage());
LOGGER.error("*** ERROR en cargarDocumentos: " + e.getMessage());
```

**Beneficio:** Ver tiempo total de ejecución y si falla en el proceso principal.

---

#### Método: `fedi()` (líneas 260-410)

**Logging crítico añadido:**
```java
// Inicio
LOGGER.info("*** INICIO fedi() - Procesando: " + (lista!=null ? lista.size() : 0) + " documentos");

// Tiempo de BD
long inicio = System.currentTimeMillis();
this.FEDIMapper.cargarDocumentos(fedi);
long duracion = System.currentTimeMillis() - inicio;
LOGGER.info("*** BD cargarDocumentos() tardó: " + duracion + "ms, ErrorCode: " + fedi.getErrorCode() + ", Error: " + fedi.getErrorDesc());

// Guardado en filesystem
LOGGER.info("*** Guardando en FS: " + listaF2.size() + " documentos");
LOGGER.info("*** Guardando FS: " + req.getNombreDocumento() + " para usuario: " + req.getIdUsuario());
LOGGER.info("*** FS OK: " + req.getNombreDocumento());
LOGGER.error("*** FS FAIL: " + req.getNombreDocumento() + " para usuario: " + req.getIdUsuario());
LOGGER.info("*** FS COMPLETADO - Exitosos: " + listDocsGuardados.size() + ", Fallos: " + listDocsNoGuardados.size());

// Fin
LOGGER.info("*** FIN fedi() - ResponseCode: " + responseFEDI.getCode());

// Catch blocks mejorados
LOGGER.error("*** JSON ERROR: " + e.getMessage());
LOGGER.error("*** PERSIST ERROR: " + e.getMessage());
LOGGER.error("*** EXCEPTION en fedi(): " + e.getMessage(), e);
```

**Beneficio:** Identificar exactamente en qué PASO del flujo falla:
- PASO 1: Generación de rutas
- PASO 2: BD cargarDocumentos()
- PASO 3: JSON parsing
- PASO 4: FS guardado

---

## 📋 Documentación Creada

### 1. **DEBUGGING_HTTP_502.md**
   - Guía completa de debugging
   - 4 escenarios de falla con SQL/PowerShell debugging
   - Checklist de validación
   - Plan de acción paso-a-paso
   
   **Ubicación:** `C:\github\Colaboracion\DEBUGGING_HTTP_502.md`

### 2. **ANALISIS_FEDI_SRV_COMPLETO.md**
   - Análisis arquitectónico completo
   - Respuestas a tus preguntas iniciales
   - Dependencias identificadas
   - Recomendaciones de acceso a BD/código
   
   **Ubicación:** `C:\github\Colaboracion\ANALISIS_FEDI_SRV_COMPLETO.md`

---

## 🚀 Plan de Despliegue

### **PASO 1: Preparación (5 min)**

```powershell
# Conectar a servidor 172.17.42.105 vía RDP o PSSession

# Crear respaldo
Copy-Item 'C:\Program Files\Tomcat\webapps\srvFEDIApi.war' `
         -Destination "C:\backup_srvFEDIApi_$(Get-Date -Format yyyyMMdd_HHmmss).war"

Copy-Item 'C:\Program Files\Tomcat\webapps\FEDIPortalWeb-1.0.war' `
         -Destination "C:\backup_FEDIPortalWeb_$(Get-Date -Format yyyyMMdd_HHmmss).war"
```

### **PASO 2: Despliegue (2 min)**

```powershell
# Detener Tomcat
net stop Tomcat9

# Copiar nuevos WARs (desde tu máquina o servidor compartido)
Copy-Item '\\tu_servidor\github\fedi-srv\target\srvFEDIApi-1.0.war' `
         -Destination 'C:\Program Files\Tomcat\webapps\srvFEDIApi.war'

Copy-Item '\\tu_servidor\github\fedi-web\target\FEDIPortalWeb-1.0.war' `
         -Destination 'C:\Program Files\Tomcat\webapps\FEDIPortalWeb-1.0.war'

# Iniciar Tomcat
net start Tomcat9

# Esperar a que inicie
Start-Sleep -Seconds 60
```

### **PASO 3: Validación (5 min)**

```powershell
# Verificar que Tomcat inició sin errores
Get-Content 'C:\Program Files\Tomcat\logs\catalina.log' -Tail 30

# Buscar "*** " para ver si los logs nuevos aparecen
Select-String -Path 'C:\Program Files\Tomcat\logs\catalina.log' -Pattern '\*\*\*' | Select-Object -Last 20
```

### **PASO 4: Testing (10 min)**

```
1. Abrir navegador
2. Ir a https://172.17.42.105:8443/FEDIPortalWeb-1.0
3. Login con usuario de prueba
4. Intentar cargar 1 documento (PDF pequeño)
5. Revisar logs mientras carga
```

### **PASO 5: Recopilación de Logs (5 min)**

```powershell
# Extraer logs relevantes
$logs = Select-String -Path 'C:\Program Files\Tomcat\logs\*.log' -Pattern '\*\*\*'
$logs | Out-File 'C:\fedi_logs_debug.txt'

# Enviar a ti para análisis
```

---

## 🔍 Qué Buscar en los Logs

### **Escenario 1: Éxito (debería ver algo como)**
```
*** INICIO cargarDocumentos - Total: 1 documentos
*** Procesando primer lote de 1 documentos
*** INICIO fedi() - Procesando: 1 documentos
*** BD cargarDocumentos() tardó: 2340ms, ErrorCode: 0, Error: null
*** BD SUCCESS - Parseando respuesta JSON
*** MATCH: documento.pdf
*** Guardando en FS: 1 documentos
*** Guardando FS: documento.pdf para usuario: hector.martinez@ift.org.mx
*** FS OK: documento.pdf
*** FS COMPLETADO - Exitosos: 1, Fallos: 0
*** FIN fedi() - ResponseCode: 102
*** FIN cargarDocumentos - Exitosos: 1 docs, Fallos: 0 docs
```

### **Escenario 2: Error en BD (busca)**
```
*** BD cargarDocumentos() tardó: 125000ms, ErrorCode: [algo != 0], Error: [mensaje]
```
→ Significa que SP tardó demasiado o falló en BD

### **Escenario 3: Error en FS (busca)**
```
*** FS FAIL: documento.pdf para usuario: hector.martinez@ift.org.mx
```
→ Significa que no se pudo escribir en disco

### **Escenario 4: Error en JSON (busca)**
```
*** JSON ERROR: Unexpected character...
```
→ Significa que SP retorna JSON malformado

---

## 📊 Checklist pre-Despliegue

Antes de desplegar a producción:

- [ ] Ambos WARs compilados exitosamente (BUILD SUCCESS)
- [ ] WARs están en las ubicaciones correctas
- [ ] Tienes respaldo de los WARs viejos
- [ ] Tienes acceso RDP/SSH a 172.17.42.105
- [ ] Usuario Tomcat tiene permisos write en C:\fedi_docs\
- [ ] Espacio en disco C: > 2 GB disponible
- [ ] Tomcat puedo ser reiniciado sin afectar otros servicios
- [ ] Tienes logs backup plan (copiar logs antes de reiniciar)

---

## ⚙️ Verificaciones Técnicas

### **Permisos Filesystem** (ejecutar en 172.17.42.105)
```powershell
# Quién corre Tomcat
Get-Process -Name java -IncludeUserName | Select ProcessName, UserName

# Permisos en fedi_docs
icacls 'C:\fedi_docs'

# Resultado esperado:
# C:\fedi_docs: (nombre_usuario):F  (Full Control)
```

### **Espacio en Disco**
```powershell
Get-Volume -DriveLetter C | Select Size, SizeRemaining, @{
    Name='PercentFree'
    Expression={[math]::Round(($_.SizeRemaining/$_.Size)*100,2)}
}

# Resultado esperado: PercentFree > 10%
```

### **Puerto Tomcat**
```powershell
netstat -ano | Select-String ':8443|:8080'

# Resultado esperado:
# LISTENING   [PID de Tomcat]
```

---

## 🎯 Resultados Esperados Después del Despliegue

### **Corto Plazo (Inmediato)**
- [x] Logs muestran flujo completo con timestamps
- [x] Podemos identificar exactamente dónde falla (PASO 1-4)
- [x] Si falla en BD: tenemos duración exacta
- [x] Si falla en FS: tenemos nombre del documento

### **Mediano Plazo (1-2 días)**
- [ ] Contactar DBA/OPS con información específica
- [ ] Ejecutar SP manualmente en BD
- [ ] Revisar índices
- [ ] Optimizar si es necesario

### **Largo Plazo (1-2 semanas)**
- [ ] Solicitar acceso a código fedi-srv completo
- [ ] Solicitar acceso a BD
- [ ] Optimizar consultarUsuarios
- [ ] Crear mock de fedi-srv para testing local

---

## 📞 Contactos Necesarios

Para proceder con la solución, necesitas contactar a:

### **1. Equipo de Infraestructura/OPS**
- Desplegar WARs en 172.17.42.105
- Verificar permisos en C:\fedi_docs\
- Reiniciar Tomcat
- Proporcionar acceso a logs

### **2. DBA (Database Admin)**
- Proporcionar acceso a BD FEDI
- Ejecutar SP manualmente
- Revisar índices
- Optimizar queries lentas

### **3. Arquitecto/Tech Lead**
- Aprobar cambios de logging
- Revisar logs de error
- Decidir sobre optimizaciones futuras

---

## 📁 Resumen de Archivos

### **Código**
```
C:\github\fedi-srv\src\main\java\fedi\srv\ift\org\mx\service\FEDIServiceImpl.java
└─ Cambios: Logging mejorado en cargarDocumentos() y fedi()

C:\github\fedi-web\src\main\java\fedi\ift\org\mx\...  
└─ Cambios: Ninguno (validado como compatible)
```

### **WARs Compilados**
```
C:\github\fedi-srv\target\srvFEDIApi-1.0.war (34.01 MB)
└─ Destino: C:\Program Files\Tomcat\webapps\srvFEDIApi.war

C:\github\fedi-web\target\FEDIPortalWeb-1.0.war (94.2 MB)
└─ Destino: C:\Program Files\Tomcat\webapps\FEDIPortalWeb-1.0.war
```

### **Documentación**
```
C:\github\Colaboracion\DEBUGGING_HTTP_502.md
└─ Guía de debugging con ejemplos SQL/PowerShell

C:\github\Colaboracion\ANALISIS_FEDI_SRV_COMPLETO.md
└─ Análisis arquitectónico y respuestas a preguntas
```

---

## ✅ Próximos Pasos Inmediatos

1. **HOY:**
   - [ ] Descargar los 2 WARs compilados
   - [ ] Contactar OPS para despliegue
   - [ ] Reproducir error (guardar documento)
   - [ ] Recopilar logs con patrones `*** `

2. **MAÑANA:**
   - [ ] Analizar logs enviados
   - [ ] Identificar PASO exacto de falla
   - [ ] Contactar DBA/OPS con datos específicos
   - [ ] Ejecutar debugging según escenario

3. **ESTA SEMANA:**
   - [ ] Implementar solución según escenario
   - [ ] Validar que documento se guarda correctamente
   - [ ] Verificar que aparece en tabla "Documentos cargados"

---

## 💡 Notas Finales

- Este análisis es basado en **código estático**, no en ejecución real
- El logging mejorado te permitirá **debug en producción** sin modificar código adicional
- Los logs tienen formato `*** ` para **fácil búsqueda** en archivos grandes
- Si logs no muestran nada: significa que falla **antes** de llegar a FEDIServiceImpl (posiblemente en API Manager)

¿Necesitas ayuda en algún paso del despliegue?
