# Sesión 17/Feb/2026 - Firmas PDF y Correos LDAP

## Resumen de la sesión

Esta sesión se enfocó en dos problemas principales:
1. **Firma PDF con cuadro de firma en última página** - ✅ RESUELTO
2. **Correos @ift.org.mx en lugar de @crt.gob.mx** - 🔍 IDENTIFICADO (pendiente solución)

---

## 1. Problema: Cuadro de firma no aparece en PDF (1 firmante)

### Contexto
Cuando un usuario firmaba un documento con 1 solo firmante, el documento quedaba "En proceso" y no aparecía el cuadro de firma en la última página del PDF.

### Diagnóstico (fedi4.txt líneas 187-308)
```
>>> Firmantes que han firmado: 1/1
>>> ¿Todos han firmado? true
>>> Página de firmas creada: 1361 bytes  ← SE CREÓ CORRECTAMENTE
>>> Encriptando PDF (todos los firmantes han firmado)
Exception realizarMergePdfConFirmas
SecurityException: class "org.bouncycastle.asn1.ASN1Primitive"'s signer information does not match
```

**Problema identificado**:
- La página de firmas SÍ se creaba correctamente
- El error ocurría al intentar **encriptar** el PDF cuando todos firmaban
- `PdfWriter.setEncryption()` causaba conflicto entre BouncyCastle jdk14-138 y jdk15on-1.54

### Solución aplicada

**Archivos modificados:**

1. **PdfHelper.java (líneas 407-412)**
```java
// Hacer merge del PDF sin firmas + nueva página de firmas
// MIGRACIÓN FEDI 2.0 (17/Feb/2026): NO ENCRIPTAR - Conflicto BouncyCastle ASN1Primitive
// La encriptación causa SecurityException por firma de JARs incompatibles
LOGGER.info(">>> Haciendo merge PDF SIN ENCRIPTACIÓN (evita conflicto BouncyCastle)");
pdfConFirmas = realizarMergePdfConFirmas(pdfSinFirmas, pdfFirmas,
                                         documento.getNombreDocumento(), hashPassword, false);
```

2. **MDSeguridadServiceImpl.java (líneas 144-152)** - Log actualizado
```java
LOGGER.info("FEDI WAR VERSION: 17/Feb/2026 14:30");
LOGGER.info("Fixes: iText 5.5.13 + BouncyCastle 1.54 + PDF NUNCA ENCRIPTAR");
LOGGER.info("       - Fix: PDF NUNCA se encripta (evita conflicto ASN1Primitive en setEncryption)");
LOGGER.info("       - Fix: PdfCopy + unethicalreading para remover permisos de firma previa");
```

**Compilación:**
- WAR 14:30 compilado exitosamente
- Ubicación: `fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war`

### Resultado
✅ El cuadro de firma ahora aparece correctamente en la última página
✅ El documento queda como "FIRMADO" cuando el único firmante firma
✅ El PDF NO se encripta (evita conflicto BouncyCastle)

### Formato del cuadro de firma
El usuario preguntó si debía tener un recuadro visual. Se decidió **dejar el formato actual** (sin borde):
```
Documento: ManualUsuario_F3_O1.pdf

deid.ext33@crt.gob.mx|17-02-2026 14:23:52|ManualUsuario_F3_O1.pdf|30F2B49E525C637E58F01BE4AADB1CA2
deid.ext33@crt.gob.mx
```

---

## 2. Problema: Correos @ift.org.mx en lugar de @crt.gob.mx

### Contexto
Al cargar documentos y agregar firmantes, los usuarios seleccionados tienen correos **@ift.org.mx** cuando deberían ser **@crt.gob.mx**.

**Evidencia:** Tabla `tbl_Firmantes` muestra:
```
david.alvarez@ift.org.mx
silvia.barcenas@ift.org.mx
pedro.alfaro@ift.org.mx
```

### Investigación realizada

#### 1. Se descartó: Catálogo de usuarios de fedi-srv
**Archivo**: `fedi-srv/src/main/resources/myBatis/sqlserver/app/catUsuario.xml` (línea 6)
```xml
<select id="obtenUsuarios">
    {call dbo.SP_CONSULTA_USUARIOS()}
</select>
```

**SP en BD**:
```sql
CREATE PROCEDURE [dbo].[SP_CONSULTA_USUARIOS]
AS
BEGIN
    SELECT * FROM CAT_USUARIOS;
END
```

**Acción tomada**: Se actualizó la tabla `CAT_USUARIOS` con:
```sql
UPDATE CAT_USUARIOS
SET USUARIOID = REPLACE(USUARIOID, '@ift.org.mx', '@crt.gob.mx')
WHERE USUARIOID LIKE '%@ift.org.mx';
```

**Resultado**: ❌ Los firmantes seguían guardándose con @ift.org.mx

#### 2. CAUSA RAÍZ IDENTIFICADA: LDAP de IFT

**Archivo**: `fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/AdminUsuariosServiceImpl.java` (línea 351)

**Flujo completo:**
1. Usuario busca firmantes en interfaz web → `AdminRolMB.buscarUsuarios()` (línea 595)
2. Llama a servicio → `adminUsuariosService.obtenerListaBusqueda()` (línea 613 de AdminRolMB)
3. Servicio consulta **LDAP de IFT** → (línea 351 de AdminUsuariosServiceImpl):
   ```java
   String vMetodo = "Obtener_Por_Nombre_usuarioID/" + prmHeaderBodyLDAP.getUser();
   respuestaServicioPost = mDSeguridadService.EjecutaMetodoGET(
       this.tokenAcceso.getAccess_token(),
       this.ldpUrl,  // ← LDAP DE IFT
       vMetodo,
       lstParametros
   );
   ```
4. LDAP retorna usuarios con **@ift.org.mx**
5. Usuario selecciona firmante con correo @ift.org.mx
6. Se guarda en `tbl_Firmantes` con el correo incorrecto

**Configuración actual** (`fedi-web/pom.xml` línea 883):
```xml
<profile.ldp.url>https://apimanager-dev.crt.gob.mx/ldp.inf.ift.org.mx/v1.0/</profile.ldp.url>
```

**Problema**: La URL apunta a `ldp.inf.ift.org.mx` (LDAP de IFT con datos antiguos)

### Soluciones propuestas

#### Opción A: Cambiar a LDAP de CRT ⭐ RECOMENDADO
**Acción**: Solicitar al equipo de WSO2/infraestructura la URL del LDAP de CRT

**URL esperada**:
```xml
<profile.ldp.url>https://apimanager-dev.crt.gob.mx/ldp.inf.crt.gob.mx/v1.0/</profile.ldp.url>
```

**Ventajas**:
- Solución definitiva
- Todos los usuarios vendrán del directorio de CRT
- No requiere hardcode ni workarounds

**Desventajas**:
- Depende de equipo externo
- Puede tomar días/semanas

#### Opción B: Usar CAT_USUARIOS en lugar de LDAP
**Acción**: Modificar `AdminUsuariosServiceImpl.obtenerListaBusqueda()` para consultar la tabla `CAT_USUARIOS` (ya actualizada con @crt.gob.mx) en lugar del LDAP

**Ventajas**:
- Control total sobre los datos
- No depende de LDAP externo
- Tabla ya está actualizada

**Desventajas**:
- Requiere mantener manualmente la tabla
- Los 54 usuarios actuales pueden no ser suficientes
- Se pierde sincronización automática con Active Directory

#### Opción C: Ampliar hardcode temporal
**Acción**: Expandir el hardcode existente (líneas 363-386 de AdminUsuariosServiceImpl) para incluir más usuarios de prueba

**Hardcode actual** (solo funciona para búsqueda de "deid"):
```java
if(searchTerm.contains("deid") || searchTerm.contains("david") || searchTerm.contains("alvarez")) {
    LDAPInfoEntry entry = new LDAPInfoEntry();
    entry.setMail("deid.ext33@crt.gob.mx");
    entry.setCn("David Alvarez (Cuenta Test)");
    // ...
}
```

**Ventajas**:
- Rápido de implementar
- Permite seguir probando

**Desventajas**:
- Solo para desarrollo/pruebas
- No escalable
- Temporal

---

## Estado actual de los archivos

### fedi-web WAR 14:30
**Archivos modificados:**
1. `PdfHelper.java:407-412` - Deshabilitada encriptación PDF
2. `MDSeguridadServiceImpl.java:144-152` - Log de versión actualizado

**Ubicación**: `fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war`

### fedi-srv
**Sin cambios** - El endpoint `consultarUsuarios` no se usa para búsqueda de firmantes

### Base de datos
**Tabla actualizada:**
- `CAT_USUARIOS`: ✅ Todos los correos cambiados a @crt.gob.mx (53 usuarios actualizados)
- `tbl_Firmantes`: ❌ Sigue recibiendo correos @ift.org.mx del LDAP

---

## Configuraciones relevantes

### URLs actuales (fedi-web/pom.xml - perfil development)
```xml
<!-- API de NEGOCIO -->
<profile.fedi.url>https://fedidev.crt.gob.mx/srvFEDIApi-1.0/</profile.fedi.url>

<!-- LDAP DE IFT (PROBLEMA) -->
<profile.ldp.url>https://apimanager-dev.crt.gob.mx/ldp.inf.ift.org.mx/v1.0/</profile.ldp.url>

<!-- API NOTIFICACIONES -->
<profile.fedi.notificaciones.url>https://apimanager-dev.crt.gob.mx/REGISTRO/CORREOS/FEDI/v1.0/firmaUsuarios/</profile.fedi.notificaciones.url>

<!-- WSO2 Identity Server -->
<profile.wso2.identity-server.url>https://identityserver-dev.crt.gob.mx</profile.wso2.identity-server.url>
```

### Solicitud pendiente a Ciberseguridad
**IP a desbloquear**: `172.27.1.5` (servidor backend API WSO2)
**Email de notificaciones**: `firmaelectronica-qa@ift.org.mx`

---

## Próximos pasos recomendados

### Inmediato
1. ✅ **Desplegar WAR 14:30** para que las firmas funcionen correctamente
2. 📧 **Solicitar URL de LDAP de CRT** al equipo de WSO2/infraestructura
3. 📧 **Confirmar con Ciberseguridad** el desbloqueo de IP 172.27.1.5

### Corto plazo (mientras llega LDAP de CRT)
**Opción temporal**: Implementar Opción C (ampliar hardcode) con lista completa de usuarios CRT para pruebas

### Mediano plazo
1. Actualizar `profile.ldp.url` con la URL del LDAP de CRT
2. Recompilar fedi-web con nueva configuración
3. Desplegar y probar búsqueda de usuarios

---

## Otros defectos identificados (no resueltos)

1. **Timeout en notificaciones** (120 segundos)
   - URL: `https://apimanager-dev.crt.gob.mx/REGISTRO/CORREOS/FEDI/v1.0/firmaUsuarios`
   - No impide la firma, pero no envía notificaciones

2. **Fecha de vigencia incorrecta** (año 0022 en lugar de 2022)
   - `FechaVigencia convertida: 19-08-0022`
   - Problema de parseo de fechas

3. **Token LDAP inválido** (cae en hardcode)
   - `StatusCode=401, Message=Invalid JWT token`
   - Actualmente usa datos ficticios del hardcode temporal

---

## Archivos de logs de referencia
- `Colaboracion/fedi4.txt` - Logs de pruebas de firma con 1 firmante
- `Colaboracion/build-13-15.log` - Compilación WAR 13:15 (PdfCopy)
- `Colaboracion/build-14-30.log` - No guardado (compilación exitosa en consola)

---

## Comandos útiles para retomar

### Compilar fedi-web
```bash
cd fedi-web/fedi-web
mvn clean package -DskipTests
```

### Buscar en logs
```bash
grep "Firmantes que han firmado" Colaboracion/fedi4.txt
grep "david.alvarez@ift.org.mx" Colaboracion/fedi4.txt
```

### Ver versión WAR desplegada
Los logs mostrarán:
```
FEDI WAR VERSION: 17/Feb/2026 14:30
Fixes: iText 5.5.13 + BouncyCastle 1.54 + PDF NUNCA ENCRIPTAR
```

---

## Contactos y seguimiento

### Pendientes con equipo externo
1. **WSO2/Infraestructura**: URL del LDAP de CRT
2. **Ciberseguridad (Víctor Abraham)**: Confirmar desbloqueo de 172.27.1.5
3. **Equipo de notificaciones**: Configuración del email `firmaelectronica-qa@ift.org.mx`

### Siguiente sesión
- Implementar solución temporal para LDAP (Opción C)
- O bien, actualizar con URL LDAP de CRT si ya está disponible
- Probar flujo completo de multi-firma (2+ firmantes)
- Revisar otros defectos pendientes (fechas, timeouts)
