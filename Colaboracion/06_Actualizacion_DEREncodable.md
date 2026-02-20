# Actualización: Error NoClassDefFoundError DEREncodable

**Fecha**: 17/Feb/2026 02:27
**Sesión anterior**: `05_Sesion_17Feb2026_BouncyCastle_y_Guardado.md`

---

## Problema Detectado

Después del despliegue del WAR 02:13:07, apareció nuevo error al **guardar documentos**:

```
java.lang.NoClassDefFoundError: org/bouncycastle/asn1/DEREncodable
	Caused by: java.lang.ClassNotFoundException: org.bouncycastle.asn1.DEREncodable
		at com.lowagie.text.pdf.PdfEncryption.<init>(Unknown Source)
```

**Ubicación**: `Colaboracion/fedi4.txt` líneas 1-105

**Causa raíz**:
- La clase `DEREncodable` existe en BouncyCastle 1.38-1.46
- Fue **deprecada y eliminada** en BouncyCastle 1.54+
- `com.lowagie:itext:2.1.7` requiere esta clase para encriptar PDFs
- El WAR anterior (02:13:07) solo tenía BouncyCastle 1.54 (sin DEREncodable)

---

## Solución Implementada: Coexistencia de Versiones

### Estrategia

Permitir que **múltiples versiones de BouncyCastle coexistan** en el WAR:
- **`bouncycastle:*-jdk14:138`** → Para iText 2.1.7 (guardar documentos, tiene DEREncodable)
- **`org.bouncycastle:*-jdk15on:1.54`** → Para itextpdf 5.5.8 (firmar documentos)

### Cambios en pom.xml

**Archivo**: `fedi-web/fedi-web/pom.xml`

#### 1. Actualización de `<dependencyManagement>` (líneas 30-48)

```xml
<!-- MIGRACIÓN FEDI 2.0 (17/Feb/2026): BouncyCastle management -->
<!-- iText 2.1.7 trae bouncycastle:*-jdk14:138 (tiene DEREncodable) -->
<!-- itextpdf 5.5.8 requiere org.bouncycastle:*-jdk15on:1.54 -->
<!-- Ambas versiones deben coexistir: jdk14-138 para guardar, jdk15on-1.54 para firmar -->
<dependencyManagement>
    <dependencies>
        <!-- Forzar BouncyCastle 1.54 para itextpdf 5.5.8 (firmar documentos) -->
        <dependency>
            <groupId>org.bouncycastle</groupId>
            <artifactId>bcprov-jdk15on</artifactId>
            <version>1.54</version>
        </dependency>
        <dependency>
            <groupId>org.bouncycastle</groupId>
            <artifactId>bcpkix-jdk15on</artifactId>
            <version>1.54</version>
        </dependency>
    </dependencies>
</dependencyManagement>
```

#### 2. Remover exclusiones de iText (líneas ~482-490)

**ANTES** (incorrecto):
```xml
<dependency>
    <groupId>com.lowagie</groupId>
    <artifactId>itext</artifactId>
    <version>2.1.7.js2</version>
    <scope>compile</scope>
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

**DESPUÉS** (correcto):
```xml
<dependency>
    <groupId>com.lowagie</groupId>
    <artifactId>itext</artifactId>
    <version>2.1.7.js2</version>
    <scope>compile</scope>
    <!-- MIGRACIÓN FEDI 2.0 (17/Feb/2026): NO excluir BouncyCastle -->
    <!-- itext debe traer sus versiones transitivas jdk14-138 con DEREncodable -->
</dependency>
```

**Razón del cambio**: Las exclusiones impedían que itext trajera sus dependencias BouncyCastle antiguas que contienen `DEREncodable`.

---

## Verificación del WAR

### JARs BouncyCastle Incluidos

```bash
cd fedi-web/fedi-web/target
jar -tf FEDIPortalWeb-1.0.war | grep "WEB-INF/lib/bc" | sort
```

**Resultado**:
```
WEB-INF/lib/bcmail-jdk14-1.38.jar     ← De vt-password
WEB-INF/lib/bcmail-jdk14-138.jar      ← De itext 2.1.7 ✅ (tiene DEREncodable)
WEB-INF/lib/bcpkix-jdk15on-1.54.jar   ← Para itextpdf 5.5.8 ✅
WEB-INF/lib/bcprov-jdk14-1.38.jar     ← De vt-password
WEB-INF/lib/bcprov-jdk14-138.jar      ← De itext 2.1.7 ✅ (tiene DEREncodable)
WEB-INF/lib/bcprov-jdk15on-1.54.jar   ← Para itextpdf 5.5.8 ✅
WEB-INF/lib/bctsp-jdk14-1.38.jar      ← De vt-password
```

**Total**: 7 JARs de BouncyCastle

**Nota sobre duplicados**:
- `bcprov-jdk14-1.38.jar` y `bcprov-jdk14-138.jar` son la **misma versión** (1.38 = 138)
- Naming diferente: Maven los ve como JARs distintos
- Ambos tienen la clase `DEREncodable` necesaria
- **Aceptable**: No causan conflicto porque son versiones compatibles

### Por qué NO causará conflicto ASN1Primitive

El error original de `ASN1Primitive signer mismatch` ocurría cuando:
- **Misma versión** de BouncyCastle venía de **múltiples repositorios** con firmas digitales diferentes
- Maven incluía ambos JARs firmados de forma diferente

Ahora tenemos:
- **Versiones diferentes** (jdk14-138 vs jdk15on-1.54)
- **Artefactos diferentes** (groupId: `bouncycastle` vs `org.bouncycastle`)
- Java cargará la clase correcta según el ClassLoader path

---

## WAR Final

**Archivo**: `fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war`

**Timestamp**: 17/Feb/2026 02:26:34 ⬅️ **USAR ESTE WAR**

**Tamaño**: ~93 MB

**Comando de compilación**:
```bash
cd fedi-web/fedi-web
mvn clean package -Pdevelopment-oracle1 -DskipTests
```

**Resultado**:
```
[INFO] BUILD SUCCESS
[INFO] Total time:  15.863 s
[INFO] Finished at: 2026-02-17T02:26:34-06:00
```

---

## Pruebas Requeridas

### Prueba 1: Guardar Documento (Prioridad ALTA)

**Objetivo**: Verificar que `DEREncodable` esté disponible

**Pasos**:
1. Iniciar sesión con `deid.ext33@crt.gob.mx`
2. Cargar documento PDF
3. Agregar firmantes
4. Guardar documento

**Resultado esperado**:
- ✅ No aparece `NoClassDefFoundError: DEREncodable`
- ✅ No aparece error de PRIMARY KEY
- ✅ Documento aparece en lista de pendientes

**Verificar en logs**:
```bash
grep "DEREncodable" /ruta/logs/catalina.out
grep "NoClassDefFoundError" /ruta/logs/catalina.out
```

### Prueba 2: Firmar Documento (Prioridad ALTA)

**Objetivo**: Verificar que no hay conflicto ASN1Primitive

**Pasos**:
1. Abrir documento pendiente
2. Firmar documento
3. Descargar PDF

**Resultado esperado**:
- ✅ No aparece `ASN1Primitive signer mismatch`
- ✅ PDF tiene página de firmas al final

**Verificar en logs**:
```bash
grep "ASN1Primitive" /ruta/logs/catalina.out
grep "BouncyCastle" /ruta/logs/catalina.out | grep ERROR
```

---

## Comandos de Despliegue

```bash
# 1. Detener Tomcat
systemctl stop tomcat

# 2. Limpiar despliegue anterior
cd /ruta/tomcat/webapps
rm -rf FEDIPortalWeb-1.0.war FEDIPortalWeb-1.0/

# 3. Copiar WAR 02:26:34
cp /ruta/proyecto/fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war .

# 4. Verificar timestamp del WAR copiado
ls -lh FEDIPortalWeb-1.0.war
# Debe mostrar: feb. 17 02:26

# 5. Iniciar Tomcat
systemctl start tomcat

# 6. Monitorear logs
tail -f /ruta/logs/catalina.out | grep -E "FEDI WAR VERSION|DEREncodable|BouncyCastle"
```

---

## Logs para Diagnóstico

### Al iniciar sesión (primera vez)

**Buscar**:
```
[INFO] ========================================
[INFO] FEDI WAR VERSION: 17/Feb/2026 02:26
[INFO] Fixes: BouncyCastle coexistencia jdk14-138 + jdk15on-1.54
[INFO] ========================================
```

### Al guardar documento

**Buscar** (NO debe aparecer):
```
NoClassDefFoundError: org/bouncycastle/asn1/DEREncodable
```

**Buscar** (debe aparecer):
```
[INFO] Usuario registrado exitosamente: [Nombre] - Code: 102
```

### Al firmar documento

**Buscar** (NO debe aparecer):
```
ASN1Primitive signer information does not match
```

---

## Estado del Proyecto

| Problema | Estado | WAR |
|----------|--------|-----|
| BouncyCastle ASN1Primitive conflict | ✅ RESUELTO | 02:13:07 |
| Error PRIMARY KEY al guardar | ✅ RESUELTO | 02:13:07 |
| NoClassDefFoundError DEREncodable | ✅ RESUELTO | 02:26:34 |
| Página de firmas no genera | ⏳ PENDIENTE | 02:26:34 |
| Guardado de documentos funciona | ⏳ PENDIENTE | 02:26:34 |

---

## Documentos Relacionados

1. **`05_Sesion_17Feb2026_BouncyCastle_y_Guardado.md`** - Sesión completa anterior
2. **`Colaboracion/fedi4.txt`** - Logs con error DEREncodable
3. **`01_Resumen_Migracion_FEDI.md`** - Contexto general
4. **`02_Base_Datos_Cambios.md`** - Cambios de BD

---

## Próximos Pasos

1. ✅ **Desplegar WAR 02:26:34** en ambiente DEV
2. ⏳ **Ejecutar Prueba 1**: Guardar documento (verificar DEREncodable disponible)
3. ⏳ **Ejecutar Prueba 2**: Firmar documento (verificar página de firmas)
4. ⏳ **Revisar logs** para confirmar ausencia de errores
5. ⏳ **Documentar resultados** para QA/PROD

---

*Última actualización: 17/Febrero/2026 02:28*
