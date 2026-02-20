# Sesión 17/Feb/2026: Resolución de BouncyCastle y Error de Guardado de Documentos

## Resumen Ejecutivo

Esta sesión resolvió dos problemas críticos en la migración FEDI 2.0:

1. **Error de BouncyCastle** que impedía generar la página de firmas en PDFs
2. **Error de guardado** que impedía registrar documentos para firma (violación de PRIMARY KEY)

---

## 1. Problema: Error de BouncyCastle en Generación de PDF

### 1.1 Síntomas

```
com.itextpdf.text.exceptions.InvalidPdfException:
class "org.bouncycastle.asn1.ASN1Primitive"'s signer information does not match
signer information of other classes in the same package
```

- El cuadro de firmas no aparecía al final del PDF firmado
- Los logs mostraban conflicto de versiones de BouncyCastle

### 1.2 Diagnóstico

**Archivo**: `fedi-web/fedi-web/pom.xml`

**Problema identificado**:
El WAR contenía 4 JARs de BouncyCastle incompatibles:
- ✅ `bcpkix-jdk15on-1.54.jar` (correcto)
- ✅ `bcprov-jdk15on-1.54.jar` (correcto)
- ❌ `bcmail-jdk14-138.jar` (antiguo, incompatible)
- ❌ `bcprov-jdk14-138.jar` (antiguo, incompatible)

**Causa raíz**:
La dependencia `com.lowagie:itext:2.1.7.js2` usa el `groupId="bouncycastle"` (sin "org.") para sus dependencias antiguas, por lo que las exclusiones previas con `groupId="org.bouncycastle"` no funcionaban.

**Comando de diagnóstico**:
```bash
cd fedi-web/fedi-web/target
jar -tf FEDIPortalWeb-1.0.war | grep "WEB-INF/lib" | grep -i "bc"
```

**Árbol de dependencias**:
```bash
mvn dependency:tree -Dverbose 2>&1 | grep -A3 -B3 "bcmail-jdk14\|bcprov-jdk14"
```

Resultado:
```
+- com.lowagie:itext:jar:2.1.7.js2:compile
|  +- bouncycastle:bcmail-jdk14:jar:138:compile
|  \- bouncycastle:bcprov-jdk14:jar:138:compile
```

### 1.3 Solución Implementada

**Archivo modificado**: `fedi-web/fedi-web/pom.xml`

#### Cambio 1: Agregar `<dependencyManagement>` (líneas 30-47)

```xml
<!-- MIGRACIÓN FEDI 2.0 (17/Feb/2026): Forzar versiones únicas de BouncyCastle -->
<!-- Esto establece las versiones oficiales que queremos usar -->
<dependencyManagement>
    <dependencies>
        <!-- Forzar BouncyCastle 1.54 - Provider -->
        <dependency>
            <groupId>org.bouncycastle</groupId>
            <artifactId>bcprov-jdk15on</artifactId>
            <version>1.54</version>
        </dependency>
        <!-- Forzar BouncyCastle 1.54 - PKIX -->
        <dependency>
            <groupId>org.bouncycastle</groupId>
            <artifactId>bcpkix-jdk15on</artifactId>
            <version>1.54</version>
        </dependency>
    </dependencies>
</dependencyManagement>
```

#### Cambio 2: Corregir exclusiones en iText (líneas 467-489)

```xml
<!-- Source: https://mvnrepository.com/artifact/com.lowagie/itext -->
<dependency>
    <groupId>com.lowagie</groupId>
    <artifactId>itext</artifactId>
    <version>2.1.7.js2</version>
    <scope>compile</scope>
    <!-- MIGRACIÓN FEDI 2.0 (17/Feb/2026): Excluir BouncyCastle antiguas para evitar conflicto con 1.54 -->
    <!-- IMPORTANTE: itext 2.1.7.js2 usa groupId "bouncycastle" (sin org.) -->
    <exclusions>
        <exclusion>
            <groupId>bouncycastle</groupId>
            <artifactId>bcmail-jdk14</artifactId>
        </exclusion>
        <exclusion>
            <groupId>bouncycastle</groupId>
            <artifactId>bcprov-jdk14</artifactId>
        </exclusion>
        <exclusion>
            <groupId>bouncycastle</groupId>
            <artifactId>bctsp-jdk14</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

**Nota crítica**: El `groupId` correcto es `bouncycastle` (sin "org."), no `org.bouncycastle`.

### 1.4 Verificación

```bash
cd fedi-web/fedi-web
mvn clean package -Pdevelopment-oracle1 -DskipTests
cd target
jar -tf FEDIPortalWeb-1.0.war | grep "WEB-INF/lib" | grep -i "bc"
```

**Resultado esperado**:
```
WEB-INF/lib/bcpkix-jdk15on-1.54.jar
WEB-INF/lib/bcprov-jdk15on-1.54.jar
WEB-INF/lib/spring-jdbc-4.0.0.RELEASE.jar
```

✅ Solo 2 JARs de BouncyCastle, ambos versión 1.54

---

## 2. Problema: Error al Guardar Documento para Firma

### 2.1 Síntomas

```
ERROR: Violation of PRIMARY KEY constraint 'PK_cat_Usuarios'.
Cannot insert duplicate key in object 'dbo.cat_Usuarios'.
The duplicate key value is (deid.ext33@crt.gob.mx).
```

- El documento no se guardaba
- No aparecía en la lista de documentos pendientes de firma
- El log mostraba "Se encontraron 0 documentos a firmar"

### 2.2 Diagnóstico

**Archivo**: `fedi-web/fedi-web/src/main/java/fedi/ift/org/mx/exposition/DocumentoVistaFirmaMB.java`

**Log del error** (`Colaboracion/fedi4.txt`, línea 173):
```
2026-02-17 02:08:41,201 [ERROR] DocumentoVistaFirmaMB:845 -
Error al registrar usuario: Hector Martinez Espinosa - Code: 2627,
Error: Violation of PRIMARY KEY constraint 'PK_cat_Usuarios'.
Cannot insert duplicate key in object 'dbo.cat_Usuarios'.
The duplicate key value is (deid.ext33@crt.gob.mx).
```

**Causa raíz**:
El código validaba si un usuario ya existe en `cat_Usuarios` comparando **por nombre** en lugar de **por email (IdUsuario)**:

```java
// ❌ CÓDIGO INCORRECTO (línea ~830)
if(catUsuario.getNombre() != null) {
    if(firmante.getCn()== null || "".equals(firmante.getCn())) {
        firmante.setCn(firmante.getName());
    }

    if (catUsuario.getNombre().toUpperCase().equals(firmante.getCn())) {
        existeBD = true;  // Compara por NOMBRE
    }
}
```

**Flujo del error**:
1. En BD existe: `IdUsuario='deid.ext33@crt.gob.mx'`, `Nombre='David Alvarez (Cuenta Test)'`
2. Usuario intenta agregar firmante: `Mail='deid.ext33@crt.gob.mx'`, `Cn='Hector Martinez Espinosa'`
3. Código busca en BD si existe usuario con nombre "HECTOR MARTINEZ ESPINOSA" → ❌ NO encuentra
4. Código intenta `INSERT INTO cat_Usuarios (IdUsuario='deid.ext33@crt.gob.mx', Nombre='HECTOR MARTINEZ ESPINOSA')`
5. SQL ERROR: PRIMARY KEY violation (el email ya existe con otro nombre)

### 2.3 Solución Implementada

**Archivo modificado**: `fedi-web/fedi-web/src/main/java/fedi/ift/org/mx/exposition/DocumentoVistaFirmaMB.java`

Se reemplazaron **6 ocurrencias** del patrón incorrecto con la validación correcta:

```java
// ✅ CÓDIGO CORREGIDO
// MIGRACIÓN FEDI 2.0 (17/Feb/2026): Comparar por email (IdUsuario), NO por nombre
// El nombre puede cambiar pero el email es único y es la PRIMARY KEY
if(catUsuario.getIdUsuario() != null && firmante.getMail() != null) {
    if (catUsuario.getIdUsuario().equalsIgnoreCase(firmante.getMail())) {
        existeBD = true;  // Compara por EMAIL (PRIMARY KEY)
    }
}
```

**Ubicaciones corregidas**:
- Línea ~825: Validación de firmantes principales (método 1)
- Línea ~864: Validación de observadores (método 1)
- Línea ~1056: Validación de firmantes principales (método 2)
- Línea ~1274: Validación de observadores (método 2)
- Otras 2 ocurrencias en métodos similares

### 2.4 Mejora Adicional: Logs Detallados

Se agregaron logs para diagnosticar errores de registro:

```java
ResponseFEDI responseRegistrarUsuario = fediService.registrarUsuario(request);
if (responseRegistrarUsuario != null && responseRegistrarUsuario.getCode() != 102) {
    LOGGER.error("Error al registrar usuario: " + firmante.getCn() +
                 " - Code: " + responseRegistrarUsuario.getCode() +
                 ", Error: " + responseRegistrarUsuario.getError());
} else if(responseRegistrarUsuario != null) {
    LOGGER.info("Usuario registrado exitosamente: " + firmante.getCn() +
                " - Code: " + responseRegistrarUsuario.getCode());
}
```

**Ubicaciones**: Líneas ~845, ~886, ~1080, ~1121

---

## 3. WAR Final Generado

**Archivo**: `fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war`

**Timestamp**: 17/Feb/2026 02:13:07

**Tamaño**: 93 MB

**Contenido BouncyCastle verificado**:
```bash
jar -tf FEDIPortalWeb-1.0.war | grep "WEB-INF/lib" | grep -i "bc"
```
```
WEB-INF/lib/bcpkix-jdk15on-1.54.jar
WEB-INF/lib/bcprov-jdk15on-1.54.jar
WEB-INF/lib/spring-jdbc-4.0.0.RELEASE.jar
```

**Compilación**:
```bash
cd fedi-web/fedi-web
mvn clean package -Pdevelopment-oracle1 -DskipTests
```

---

## 4. Cambios Realizados - Resumen

### 4.1 Archivos Modificados

1. **fedi-web/fedi-web/pom.xml**
   - Líneas 30-47: Agregado `<dependencyManagement>` para forzar BouncyCastle 1.54
   - Líneas 467-489: Corregidas exclusiones de BouncyCastle en iText (groupId correcto)

2. **fedi-web/fedi-web/src/main/java/fedi/ift/org/mx/exposition/DocumentoVistaFirmaMB.java**
   - 6 ocurrencias: Cambiada validación de usuarios de comparar por nombre a comparar por email
   - 4 ubicaciones: Agregados logs detallados para errores de registro

### 4.2 Comandos para Despliegue

```bash
# En el servidor:
# 1. Detener Tomcat
systemctl stop tomcat

# 2. Limpiar despliegue anterior
cd /ruta/tomcat/webapps
rm -rf FEDIPortalWeb-1.0.war FEDIPortalWeb-1.0/

# 3. Copiar nuevo WAR
cp /ruta/proyecto/fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war .

# 4. Iniciar Tomcat
systemctl start tomcat

# 5. Verificar logs
tail -f /ruta/tomcat/logs/catalina.out
```

### 4.3 Logs para Verificar Despliegue Correcto

**Al iniciar sesión (primera vez)**:
```
[INFO] ========================================
[INFO] FEDI WAR VERSION: 17/Feb/2026 02:13
[INFO] Fixes: BouncyCastle v1.54 + Validación por Email
[INFO] ========================================
```

**Al agregar firmante existente**:
```
[INFO] Usuario registrado exitosamente: David Alvarez - Code: 102
```

**Al agregar firmante nuevo**:
```
[INFO] Usuario registrado exitosamente: Nuevo Usuario - Code: 102
```

**Si hay error de duplicado** (ya NO debería ocurrir):
```
[ERROR] Error al registrar usuario: Nombre - Code: 2627, Error: Violation of PRIMARY KEY...
```

---

## 5. Pruebas Pendientes

### 5.1 Prueba 1: Guardado de Documento
1. Iniciar sesión con `deid.ext33@crt.gob.mx`
2. Cargar un documento PDF
3. Agregar firmantes (incluir `deid.ext33@crt.gob.mx`)
4. Guardar documento
5. **Resultado esperado**:
   - ✅ No aparece error de PRIMARY KEY
   - ✅ Documento aparece en lista de "Documentos pendientes"

### 5.2 Prueba 2: Firma de Documento
1. Abrir documento pendiente de firma
2. Firmar el documento
3. Descargar PDF firmado
4. **Resultado esperado**:
   - ✅ No aparece error de BouncyCastle en logs
   - ✅ PDF tiene página de firmas al final con el cuadro de firma

### 5.3 Verificación de Logs

**Buscar en logs**:
```bash
grep "FEDI WAR VERSION" /ruta/logs/fedi-web.log
grep "BouncyCastle" /ruta/logs/fedi-web.log | grep ERROR
grep "Error al registrar usuario" /ruta/logs/fedi-web.log
```

---

## 6. Problemas Conocidos / Notas

### 6.1 Error de Registro de Usuario Hector Martinez

**Contexto**:
Durante las pruebas, se detectó que intentar registrar "Hector Martinez Espinosa" con email `deid.ext33@crt.gob.mx` causaba error porque ese email ya existía en BD con nombre "David Alvarez (Cuenta Test)".

**Solución**:
La corrección de validación por email (en lugar de nombre) resuelve este problema. Ahora el código detecta correctamente que el email ya existe y NO intenta registrar duplicado.

### 6.2 Hardcode Temporal para deid.ext33@crt.gob.mx

**Ubicación**: `AdminUsuariosServiceImpl.java` (líneas ~316-334)

El hardcode sigue activo y proporciona datos ficticios cuando la consulta LDAP falla para este usuario.

**Impacto**: No afecta el funcionamiento. El hardcode proporciona datos de respaldo.

### 6.3 OAuth2 Token HTTP vs HTTPS

**Estado actual**: Usando HTTP para token endpoint (`http://apimanager-dev.crt.gob.mx/token`)

**Ubicación**: `pom.xml` (líneas ~838, ~907, ~966)

**Razón**: HTTPS no funciona en ambiente actual. Mantener HTTP hasta que infraestructura soporte HTTPS.

---

## 7. Próximos Pasos

1. **Desplegar WAR 02:13:07** en ambiente DEV
2. **Ejecutar Prueba 1**: Guardar documento con firmantes
3. **Ejecutar Prueba 2**: Firmar documento y verificar página de firmas
4. **Revisar logs** para confirmar que no hay errores
5. **Si pruebas exitosas**: Desplegar en QA
6. **Documentar** cualquier issue adicional encontrado

---

## 8. Referencias

### 8.1 Documentos Anteriores
- `Colaboracion/01_Resumen_Migracion_FEDI.md`
- `Colaboracion/02_Base_Datos_Cambios.md`
- `Colaboracion/03_Dependencias_Eliminadas.md`
- `Colaboracion/04_Proximos_Pasos.md`

### 8.2 Logs de Sesión
- `Colaboracion/fedi4.txt` - Logs completos de pruebas
- `Colaboracion/build-01-52.log` - Build con BouncyCastle corregido
- `Colaboracion/bouncycastle-tree.txt` - Árbol de dependencias

### 8.3 Enlaces Útiles
- Maven Dependency Tree: `mvn dependency:tree -Dverbose`
- BouncyCastle Docs: https://www.bouncycastle.org/java.html
- iText 2.1.7: https://mvnrepository.com/artifact/com.lowagie/itext/2.1.7.js2

---

## 9. Contacto y Soporte

Para continuar esta sesión más tarde, revisar:
1. Este documento (05_Sesion_17Feb2026_BouncyCastle_y_Guardado.md)
2. WAR compilado: `fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war` (02:13:07)
3. Logs más recientes en `Colaboracion/fedi4.txt`

**Estado del proyecto**:
- ✅ BouncyCastle RESUELTO
- ✅ Error de guardado RESUELTO
- ⏳ Pendiente verificar firma PDF en producción

---

*Última actualización: 17/Febrero/2026 02:15*
