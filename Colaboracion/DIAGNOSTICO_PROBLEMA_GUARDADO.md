# Diagnóstico: Problema al Guardar Documentos

## 🔍 Análisis de Logs

### Logs Revisados
- `Logs_fedi_srv_ambiente_dev.txt`
- `Logs_fedi_web_ambiente_dev.txt`

### Problema Identificado

**❌ NO es problema de `cargarDocumentos()`**

El error real ocurre **ANTES** de llegar a guardar documentos:

```
2026-02-11 17:30:00,816 [ERROR] [] [] DocumentoVistaFirmaMB:968 - 
Ocurrio un error al guardar el documento FEDIServiceImpl.obtenerCatUsuarios(): timeout
```

### Root Cause

```
URL=https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios
Error=timeout, Duracion=120065ms
```

**fedi-srv NO está respondiendo** o **API Manager no puede alcanzarlo**.

### Flujo del Error

```
1. Usuario hace login → ✅ OK
2. DocumentoVistaFirmaMB.guardar() llama obtenerCatUsuarios() → ❌ TIMEOUT 120s
3. fedi-web intenta llamar: https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios
4. API Manager timeout esperando respuesta de fedi-srv
5. Error se propaga a UI: "Ocurrio un error al guardar el documento"
```

### Evidencia

**SP_CONSULTA_USUARIOS es ultra simple:**
```sql
CREATE PROCEDURE [dbo].[SP_CONSULTA_USUARIOS]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM CAT_USUARIOS;
END;
```

**NO debería tardar 120 segundos**. El problema es infraestructura/red, NO el código.

---

## ✅ Acciones para Solucionar

### Opción A: Verificar Estado de fedi-srv

1. **RDP a servidor de fedi-srv (probablemente 172.17.42.105)**
   ```bash
   # Verificar si el servicio está corriendo
   Get-Service | Where-Object {$_.Name -like "*tomcat*" -or $_.Name -like "*fedi*"}
   
   # O verificar proceso Java
   Get-Process java
   ```

2. **Ver logs de Tomcat/WebLogic en servidor**
   ```bash
   # Ubicación típica de logs
   tail -f /var/log/tomcat/catalina.out
   # O
   tail -f C:\tomcat\logs\catalina.out
   ```

3. **Verificar que fedi-srv responde localmente**
   ```bash
   # Desde el servidor de fedi-srv
   curl http://localhost:8080/srvFEDIApi/catalogos/consultarUsuarios
   ```

### Opción B: Verificar Conectividad API Manager → fedi-srv

1. **Desde API Manager, probar conectividad**
   ```bash
   # Ping al servidor
   ping 172.17.42.105
   
   # Telnet al puerto de fedi-srv (probablemente 8080)
   telnet 172.17.42.105 8080
   ```

2. **Revisar configuración de rutas en API Manager**
   - Ver si la ruta `/FEDI/v1.0/catalogos/*` apunta correctamente a fedi-srv
   - Verificar timeout configurado (debe ser > 120s o ajustar código)

### Opción C: Desplegar Nuevo WAR con SQL Directo

Si fedi-srv está caído por el problema de SPs lentos:

1. **Copiar WAR compilado**
   ```powershell
   Copy-Item "C:\github\fedi-srv\target\srvFEDIApi-1.0.war" `
             "\\172.17.42.105\webapps\" -Force
   ```

2. **Reiniciar servicio**
   ```bash
   # Reiniciar Tomcat
   sudo systemctl restart tomcat
   # O
   net stop Tomcat9
   net start Tomcat9
   ```

3. **Monitorear logs**
   ```bash
   tail -f /var/log/fedi-srv.log | grep "***"
   ```

4. **Probar guardado de documento**
   - Intentar subir 1 documento desde fedi-web
   - Buscar en logs: `*** Usando SQL DIRECTO`
   - Verificar tiempo: debe ser < 20 segundos

---

## 📊 Validación de Éxito

### Antes (con problema)
```
[ERROR] MDSeguridadServiceImpl:232 - IOException. 
URL=https://apimanager-dev.ift.org.mx/FEDI/v1.0/catalogos/consultarUsuarios
Error=timeout, Duracion=120065ms
```

### Después (funcionando)
```
[INFO] MDSeguridadServiceImpl:222 - EjecutaMetodoGET exitoso. 
StatusCode=200, BodySize=XXX, Duracion=2000ms
```

```
[INFO] *** INICIO cargarDocumentos - Total: 1 documentos
[INFO] *** Usando SQL DIRECTO (sin SPs)
[INFO] *** SQL DIRECTO cargarDocumentos() tardó: 3500ms
[INFO] *** FIN cargarDocumentos - Exitosos: 1, Fallos: 0
```

---

## 🎯 Próximos Pasos Recomendados

1. **URGENTE**: Verificar por qué fedi-srv no responde
   - Revisar si el servicio está corriendo
   - Ver logs de error en el servidor
   - Verificar conectividad de red

2. **DESPLIEGUE**: Una vez fedi-srv responda, desplegar nuevo WAR con SQL Directo
   - Copiar `srvFEDIApi-1.0.war` a servidor
   - Reiniciar servicio
   - Probar guardado de documentos

3. **BENCHMARKING**: Comparar tiempos antes/después
   - Antes: SP_CARGAR_DOCUMENTOS (120s timeout)
   - Después: SQL DIRECTO (< 20s esperado)

4. **DOCUMENTACIÓN**: Generar reporte de mejora
   - Capturar logs con tiempos
   - Documentar mejora de performance
   - Compartir resultados con equipo
