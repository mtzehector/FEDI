# Despliegue WAR Final - Procedimiento

**Fecha**: 17/Feb/2026 02:40
**WAR a desplegar**: `FEDIPortalWeb-1.0.war` (02:39:52)

---

## Situación Actual

### Problemas Identificados

1. ✅ **Guardado de documentos funciona** - Documento ID=23752 guardado exitosamente
2. ⚠️ **Timeout al enviar notificación** - Servicio externo demora 2+ minutos
3. ❌ **Error al firmar (ASN1Primitive)** - WAR desplegado es incorrecto (versión 01:15)

### WAR Desplegado Actual (INCORRECTO)

Log muestra:
```
Versión WAR: 17/Feb/2026 01:15 - BouncyCastle fix + Hardcode
```

Este WAR **NO tiene** las versiones jdk14-138 de BouncyCastle necesarias para firmar.

---

## WAR Final Correcto

**Archivo**: `fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war`

**Timestamp**: 17/Feb/2026 02:39:52

**Tamaño**: ~93 MB

### Contenido BouncyCastle

```bash
jar -tf FEDIPortalWeb-1.0.war | grep "WEB-INF/lib/bc" | sort
```

**Resultado esperado (7 JARs)**:
```
WEB-INF/lib/bcmail-jdk14-1.38.jar     ← De vt-password
WEB-INF/lib/bcmail-jdk14-138.jar      ← De itext 2.1.7 ✅ (para guardar)
WEB-INF/lib/bcpkix-jdk15on-1.54.jar   ← Para itextpdf 5.5.8 ✅ (para firmar)
WEB-INF/lib/bcprov-jdk14-1.38.jar     ← De vt-password
WEB-INF/lib/bcprov-jdk14-138.jar      ← De itext 2.1.7 ✅ (para guardar, tiene DEREncodable)
WEB-INF/lib/bcprov-jdk15on-1.54.jar   ← Para itextpdf 5.5.8 ✅ (para firmar)
WEB-INF/lib/bctsp-jdk14-1.38.jar      ← De vt-password
```

**Crítico**: Deben existir **ambas versiones**:
- `bcprov-jdk14-138.jar` → Para guardar documentos (iText 2.1.7 con DEREncodable)
- `bcprov-jdk15on-1.54.jar` → Para firmar documentos (itextpdf 5.5.8)

---

## Procedimiento de Despliegue

### Paso 1: Verificar WAR Local

```bash
# En máquina de desarrollo
cd fedi-web/fedi-web/target

# Verificar timestamp
ls -lh FEDIPortalWeb-1.0.war
# Debe mostrar: feb. 17 02:39

# Verificar BouncyCastle JARs
jar -tf FEDIPortalWeb-1.0.war | grep "WEB-INF/lib/bc" | wc -l
# Debe mostrar: 7

# Ver lista completa
jar -tf FEDIPortalWeb-1.0.war | grep "WEB-INF/lib/bc" | sort
```

### Paso 2: Copiar WAR al Servidor

```bash
# Copiar a servidor
scp fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war usuario@servidor:/tmp/

# En el servidor, verificar
ls -lh /tmp/FEDIPortalWeb-1.0.war
```

### Paso 3: Detener Tomcat

```bash
# En el servidor
systemctl stop tomcat

# Verificar que se detuvo
systemctl status tomcat | grep Active
# Debe mostrar: Active: inactive (dead)
```

### Paso 4: Limpiar Despliegue Anterior

```bash
# Navegar a webapps
cd /ruta/tomcat/webapps

# Respaldar WAR anterior (opcional)
mv FEDIPortalWeb-1.0.war FEDIPortalWeb-1.0.war.bak_01-15

# Eliminar carpeta desplegada
rm -rf FEDIPortalWeb-1.0/

# Limpiar logs antiguos (opcional)
> /ruta/tomcat/logs/catalina.out
```

### Paso 5: Desplegar Nuevo WAR

```bash
# Copiar WAR a webapps
cp /tmp/FEDIPortalWeb-1.0.war /ruta/tomcat/webapps/

# Verificar timestamp correcto
ls -lh /ruta/tomcat/webapps/FEDIPortalWeb-1.0.war
# Debe mostrar: feb. 17 02:39

# Verificar permisos
chmod 644 /ruta/tomcat/webapps/FEDIPortalWeb-1.0.war
chown tomcat:tomcat /ruta/tomcat/webapps/FEDIPortalWeb-1.0.war
```

### Paso 6: Iniciar Tomcat

```bash
# Iniciar servicio
systemctl start tomcat

# Verificar inicio
systemctl status tomcat | grep Active
# Debe mostrar: Active: active (running)

# Monitorear despliegue
tail -f /ruta/tomcat/logs/catalina.out
```

### Paso 7: Verificar Despliegue Exitoso

**Buscar en logs**:

1. **Inicio de aplicación**:
```bash
grep "Server startup" /ruta/tomcat/logs/catalina.out
```

2. **Sin errores críticos**:
```bash
grep -i "error\|exception" /ruta/tomcat/logs/catalina.out | tail -20
```

3. **Verificar JARs desplegados**:
```bash
ls -lh /ruta/tomcat/webapps/FEDIPortalWeb-1.0/WEB-INF/lib/bc*
```

Debe listar 7 archivos BouncyCastle.

---

## Verificación Funcional

### Test 1: Iniciar Sesión

**URL**: `https://fedidev.crt.gob.mx/FEDIPortalWeb-1.0/`

**Credenciales**: `deid.ext33@crt.gob.mx`

**Verificar en logs**:
```bash
tail -f /ruta/logs/catalina.out | grep "FEDI WAR VERSION"
```

**Resultado esperado**:
```
[INFO] ========================================
[INFO] FEDI WAR VERSION: 17/Feb/2026 02:30
[INFO] Fixes: BouncyCastle COEXISTENCIA jdk14-138 + jdk15on-1.54
[INFO] ========================================
```

### Test 2: Guardar Documento

**Pasos**:
1. Cargar PDF
2. Agregar firmantes: `deid.ext33@crt.gob.mx`, `david.alvarez@ift.org.mx`
3. Guardar

**Verificar en logs** (NO debe aparecer):
```bash
grep "DEREncodable" /ruta/logs/catalina.out
grep "NoClassDefFoundError" /ruta/logs/catalina.out
```

**Verificar guardado**:
```bash
grep "Documento guardado" /ruta/logs/catalina.out | tail -1
```

**Nota sobre timeout de notificación**:
Si aparece error de timeout (2 minutos), **es normal**. El documento se guarda correctamente, solo falla el envío de notificación al servicio externo.

### Test 3: Firmar Documento

**Pasos**:
1. Ir a "Documentos pendientes"
2. Seleccionar documento guardado
3. Firmar

**Verificar en logs** (NO debe aparecer):
```bash
grep "ASN1Primitive" /ruta/logs/catalina.out | tail -5
```

**Resultado esperado en logs**:
```
[INFO] >>> PdfHelper.agregarFirmasAlPdf() - INICIO
[INFO] >>> Documento: [nombre].pdf
[INFO] >>> Firmantes totales: 2
[INFO] >>> PDF con firmas final: [tamaño] bytes
[INFO] >>> PdfHelper.agregarFirmasAlPdf() - FIN
```

**Verificar archivo PDF firmado**:
- Descargar PDF
- Abrir en visor
- **Verificar**: Última página debe mostrar cuadro con firmas

---

## Problemas Conocidos

### 1. Timeout al Enviar Notificación

**Síntoma**:
```
ERROR: FEDIServiceImpl.enviarNotificacion(): timeout
SocketTimeoutException: timeout (120081ms)
```

**Impacto**: El documento se guarda correctamente, pero no se envía notificación a firmantes.

**Causa**: Servicio externo `https://apimanager-dev.crt.gob.mx/REGISTRO/CORREOS/FEDI/v1.0/firmaUsuarios/1/[id]` no responde en 2 minutos.

**Solución temporal**: Aceptable para DEV. El flujo principal (guardar/firmar) funciona.

### 2. Invalid JWT Token en LDAP

**Síntoma**:
```
StatusCode=401, Error: Invalid JWT token. Make sure you have provided the correct security credentials
```

**Impacto**: Mínimo. El hardcode para `deid.ext33@crt.gob.mx` se activa automáticamente.

**Verificar**:
```bash
grep "HARDCODE TEMPORAL: Retornando información ficticia" /ruta/logs/catalina.out
```

---

## Rollback (Si es Necesario)

```bash
# Detener Tomcat
systemctl stop tomcat

# Restaurar WAR anterior
cd /ruta/tomcat/webapps
rm -f FEDIPortalWeb-1.0.war
rm -rf FEDIPortalWeb-1.0/
mv FEDIPortalWeb-1.0.war.bak_01-15 FEDIPortalWeb-1.0.war

# Iniciar Tomcat
systemctl start tomcat
```

---

## Checklist de Verificación

Antes de dar por completado el despliegue, verificar:

- [ ] WAR copiado tiene timestamp 02:39:52
- [ ] Tomcat detenido antes de reemplazar WAR
- [ ] WAR anterior respaldado
- [ ] Carpeta `FEDIPortalWeb-1.0/` eliminada
- [ ] Nuevo WAR tiene permisos correctos (644, tomcat:tomcat)
- [ ] Tomcat inició sin errores
- [ ] Log muestra versión "02:30 - BouncyCastle COEXISTENCIA"
- [ ] 7 JARs BouncyCastle en WEB-INF/lib/
- [ ] Login funciona
- [ ] Guardar documento funciona (sin error DEREncodable)
- [ ] Firmar documento funciona (sin error ASN1Primitive)
- [ ] PDF firmado tiene página de firmas al final

---

## Comandos Rápidos de Diagnóstico

```bash
# Ver versión WAR desplegada
grep "FEDI WAR VERSION" /ruta/logs/catalina.out | tail -1

# Ver errores BouncyCastle
grep -E "DEREncodable|ASN1Primitive" /ruta/logs/catalina.out

# Ver documentos guardados hoy
grep "Documento guardado\|cadenaEncriptada" /ruta/logs/catalina.out | grep "2026-02-17"

# Ver documentos firmados hoy
grep "Firma registrada exitosamente" /ruta/logs/catalina.out | grep "2026-02-17"

# Monitorear en tiempo real
tail -f /ruta/logs/catalina.out | grep -E "ERROR|Exception|FEDI WAR|Documento|Firma"
```

---

## Contacto y Soporte

**WAR a desplegar**: `fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war` (02:39:52)

**Documentos relacionados**:
- `05_Sesion_17Feb2026_BouncyCastle_y_Guardado.md` - Contexto completo
- `06_Actualizacion_DEREncodable.md` - Solución DEREncodable
- `Colaboracion/fedi4.txt` - Logs con errores

**Estado esperado después del despliegue**:
- ✅ Guardar documento (sin error DEREncodable)
- ✅ Firmar documento (sin error ASN1Primitive)
- ✅ Página de firmas en PDF
- ⚠️ Timeout de notificaciones (aceptable en DEV)

---

*Última actualización: 17/Febrero/2026 02:41*
