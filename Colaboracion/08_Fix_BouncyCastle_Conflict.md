# Fix Error BouncyCastle - Conflicto de Versiones
**Fecha**: 17/Feb/2026 00:17
**Estado**: ✅ Resuelto - WAR compilado exitosamente

---

## 🔴 ERROR ORIGINAL

**Línea logs**: 58-59 (fedi4.txt)
```
com.itextpdf.text.exceptions.InvalidPdfException:
class "org.bouncycastle.asn1.ASN1Primitive"'s signer information does not match
signer information of other classes in the same package
```

**Ubicación**: `PdfHelper.java:314` al crear `new PdfReader()`

**Impacto**:
- ✅ Login funciona
- ✅ Consultas BD funcionan
- ✅ Lectura archivos funciona
- ❌ **Firma de documentos falla** al generar PDF con página de firmas

---

## 🔍 DIAGNÓSTICO

### Versiones conflictivas detectadas:

Ejecutamos `mvn dependency:tree -Dincludes=org.bouncycastle:*` y encontramos **6 versiones diferentes**:

| Librería | Versión | Origen | Tipo |
|----------|---------|--------|------|
| `bcprov-jdk15` | 1.45 | vt-password → vt-crypt | Transitiva |
| `bcprov-jdk14` | 1.38 | itext → bctsp-jdk14 | Transitiva |
| `bctsp-jdk14` | 1.38 | itext | Transitiva |
| `bcmail-jdk14` | 1.38 | itext → bctsp-jdk14 | Transitiva |
| `bcprov-jdk15on` | 1.54 | Declarada directamente | **✅ CORRECTA** |
| `bcpkix-jdk15on` | 1.54 | Declarada directamente | **✅ CORRECTA** |

### Root Cause:
Múltiples versiones de BouncyCastle con **firmas digitales JAR incompatibles** en el classpath, causando conflicto en la verificación de integridad de clases.

---

## ✅ SOLUCIÓN APLICADA

### 1. Exclusión de BouncyCastle antigua en `vt-password`

**Archivo**: `fedi-web/fedi-web/pom.xml` líneas 271-283

```xml
<!-- Password Strength -->
<dependency>
    <groupId>edu.vt.middleware</groupId>
    <artifactId>vt-password</artifactId>
    <version>3.1.1</version>
    <!-- MIGRACIÓN FEDI 2.0 (17/Feb/2026): Excluir BouncyCastle antigua para evitar conflicto con 1.54 -->
    <exclusions>
        <exclusion>
            <groupId>org.bouncycastle</groupId>
            <artifactId>bcprov-jdk15</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

**Efecto**: Elimina `bcprov-jdk15:1.45` del classpath

---

### 2. Exclusión de BouncyCastle antiguas en `itext`

**Archivo**: `fedi-web/fedi-web/pom.xml` líneas 448-469

```xml
<!-- Source: https://mvnrepository.com/artifact/com.lowagie/itext -->
<dependency>
    <groupId>com.lowagie</groupId>
    <artifactId>itext</artifactId>
    <version>2.1.7.js2</version>
    <scope>compile</scope>
    <!-- MIGRACIÓN FEDI 2.0 (17/Feb/2026): Excluir BouncyCastle antiguas para evitar conflicto con 1.54 -->
    <exclusions>
        <exclusion>
            <groupId>org.bouncycastle</groupId>
            <artifactId>bctsp-jdk14</artifactId>
        </exclusion>
        <exclusion>
            <groupId>org.bouncycastle</groupId>
            <artifactId>bcprov-jdk14</artifactId>
        </exclusion>
        <exclusion>
            <groupId>org.bouncycastle</groupId>
            <artifactId>bcmail-jdk14</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

**Efecto**: Elimina 3 versiones antiguas:
- `bctsp-jdk14:1.38`
- `bcprov-jdk14:1.38`
- `bcmail-jdk14:1.38`

---

## 📊 VALIDACIÓN POST-FIX

### Dependency Tree después del fix:

```
mvn dependency:tree -Dincludes=org.bouncycastle:*

[INFO] fedi.ift.org.mx:FEDIPortalWeb:war:1.0
[INFO] +- org.bouncycastle:bcprov-jdk15on:jar:1.54:compile
[INFO] \- org.bouncycastle:bcpkix-jdk15on:jar:1.54:compile
[INFO] BUILD SUCCESS
```

✅ **Solo 2 librerías BouncyCastle (ambas v1.54)**

### Compilación exitosa:

```
[INFO] BUILD SUCCESS
[INFO] Total time:  13.025 s
[INFO] Finished at: 2026-02-17T00:17:34-06:00
```

**WAR generado**: `fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war`

---

## 🧪 PRUEBAS NECESARIAS

### ✅ Funcionalidades que YA funcionaban:
- [x] Login con credenciales CRT
- [x] Consulta de documentos pendientes
- [x] Listado de firmantes
- [x] Lectura de archivos PDF del filesystem

### 🔍 Funcionalidad a validar POST-DESPLIEGUE:
- [ ] **Firmar documento** - Debe generar PDF con página de firmas sin error `InvalidPdfException`
- [ ] Verificar que PdfReader puede leer PDFs correctamente
- [ ] Confirmar que no aparece error: `ASN1Primitive's signer information does not match`

---

## 📋 LOGS ESPERADOS (Éxito)

### Antes del fix (ERROR):
```
[ERROR] PdfHelper:353 - Exception agregarFirmasAlPdf
com.itextpdf.text.exceptions.InvalidPdfException: class "org.bouncycastle.asn1.ASN1Primitive"'s
signer information does not match signer information of other classes in the same package
	at com.itextpdf.text.pdf.PdfReader.readPdf(PdfReader.java:738)
```

### Después del fix (ESPERADO):
```
[INFO] PdfHelper:314 - >>> PdfReader creado exitosamente
[INFO] PdfHelper:350 - >>> PDF con firmas generado: 63 páginas (62 originales + 1 firma)
[INFO] FEDIServiceImpl:933 - >>> Documento firmado exitosamente: ManualUsuario_F1_O0.pdf
```

---

## 🔧 CONTEXTO TÉCNICO

### ¿Por qué ocurre este error?

1. **Firmas digitales JAR**: Los JARs de BouncyCastle están firmados digitalmente
2. **Validación de integridad**: La JVM verifica que todas las clases del mismo paquete tengan la misma firma
3. **Conflicto**: Al tener múltiples versiones (1.38, 1.45, 1.54) con firmas diferentes, la JVM rechaza cargar las clases
4. **Resultado**: `InvalidPdfException` al intentar usar clases de BouncyCastle desde iText

### ¿Por qué no afectaba al login?

El login NO usa operaciones criptográficas de BouncyCastle a través de iText. Solo cuando `PdfReader` intenta leer un PDF (que puede contener firmas digitales), necesita las clases ASN.1 de BouncyCastle.

---

## 🚀 PRÓXIMOS PASOS

1. **Desplegar WAR** en ambiente DEV
2. **Ejecutar prueba de firma** de documento
3. **Monitorear logs** para confirmar que:
   - PdfReader se crea sin errores
   - Página de firmas se genera correctamente
   - No aparecen errores de BouncyCastle
4. **Validar firma completa** de 2 documentos con múltiples firmantes

---

## 📌 ARCHIVOS MODIFICADOS

- `fedi-web/fedi-web/pom.xml` (líneas 276-282, 454-468)
  - Agregadas exclusiones de BouncyCastle en dependencias transitivas

---

## 📚 REFERENCIAS

- **Error original**: `InvalidPdfException: signer information does not match`
- **Causa**: https://stackoverflow.com/questions/23890033/bouncycastle-class-signer-information-does-not-match
- **Maven exclusions**: https://maven.apache.org/guides/introduction/introduction-to-optional-and-excludes-dependencies.html
- **BouncyCastle compatibility**: https://www.bouncycastle.org/latest_releases.html

---

**Compilado por**: Claude Code
**Fecha**: 17/Feb/2026 00:17
**Versión BouncyCastle unificada**: 1.54 (jdk15on)
**Estado**: ✅ Listo para despliegue y pruebas
