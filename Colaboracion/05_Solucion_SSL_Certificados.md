# Solución SSL - Certificados Autofirmados

**Fecha:** 16/Feb/2026
**Autor:** Claude (FEDI Migration 2.0)
**Problema:** Error `SSLHandshakeException: PKIX path building failed` al llamar a `https://fedidev.crt.gob.mx`

---

## 1. PROBLEMA IDENTIFICADO

### 1.1 Descripción del Error
```
javax.net.ssl.SSLHandshakeException:
sun.security.validator.ValidatorException:
PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException:
unable to find valid certification path to requested target
```

### 1.2 Causa Raíz
El servidor `fedidev.crt.gob.mx` usa un **certificado SSL autofirmado** que no está en el truststore de Java. Cuando la aplicación intenta conectarse por HTTPS, Java rechaza la conexión porque no puede validar la cadena de certificados.

### 1.3 ¿Por qué el login funciona pero la carga de documentos no?

| Operación | URL | ¿Funciona? | Motivo |
|-----------|-----|------------|--------|
| **Login** | `https://apimanager-dev.crt.gob.mx/ldp.inf.ift.org.mx/v1.0/` | ✅ SÍ | Certificado válido en API Manager |
| **Carga de Documentos** | `https://fedidev.crt.gob.mx/srvFEDIApi-1.0/` | ❌ NO | Certificado autofirmado en servidor directo |

**Explicación:** El login usa el API Manager que tiene certificado válido, pero la sección de documentos llama directamente al servidor `fedidev.crt.gob.mx` que tiene certificado autofirmado.

---

## 2. SOLUCIÓN IMPLEMENTADA

### 2.1 Archivos Creados

#### `SSLUtils.java`
**Ubicación:** `fedi-web/fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/loadsoa/SSLUtils.java`

**Propósito:** Clase utilidad que configura clientes HTTP para aceptar certificados SSL autofirmados.

**Métodos principales:**
- `getTrustAllCertsManager()`: Crea TrustManager que acepta todos los certificados
- `getTrustAllHostnameVerifier()`: Crea HostnameVerifier que acepta todos los hostnames
- `getTrustAllSSLSocketFactory()`: Crea SSLSocketFactory configurado
- `configureToAcceptSelfSignedCertificates(builder)`: Configura un OkHttpClient.Builder
- `createUnsafeOkHttpClient()`: Crea cliente HTTP completo con timeouts

**Advertencia de seguridad:**
```java
/**
 * USO: SOLO para entornos de desarrollo. NO utilizar en producción.
 *
 * ADVERTENCIA: Esto desactiva la validación de certificados SSL.
 */
```

---

### 2.2 Archivos Modificados

#### `MDSeguridadServiceImpl.java`
**Ubicación:** `fedi-web/fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/loadsoa/MDSeguridadServiceImpl.java`

**Cambios realizados:**

1. **Nuevo método `createConfiguredHttpClient()`:**
```java
private OkHttpClient createConfiguredHttpClient() {
    long connectTimeout = environment.getProperty("http.client.connect.timeout", Long.class, 30000L);
    long readTimeout = environment.getProperty("http.client.read.timeout", Long.class, 120000L);
    long writeTimeout = environment.getProperty("http.client.write.timeout", Long.class, 30000L);

    OkHttpClient.Builder builder = new OkHttpClient.Builder()
        .connectTimeout(connectTimeout, TimeUnit.MILLISECONDS)
        .readTimeout(readTimeout, TimeUnit.MILLISECONDS)
        .writeTimeout(writeTimeout, TimeUnit.MILLISECONDS);

    // En desarrollo, aceptar certificados autofirmados
    String[] activeProfiles = environment.getActiveProfiles();
    boolean isDevelopment = false;
    for (String profile : activeProfiles) {
        if (profile.toLowerCase().contains("dev") || profile.toLowerCase().contains("local")) {
            isDevelopment = true;
            break;
        }
    }

    if (isDevelopment) {
        LOGGER.warn("[MDSeguridadService] Perfil de DESARROLLO detectado. Aceptando certificados SSL autofirmados.");
        SSLUtils.configureToAcceptSelfSignedCertificates(builder);
    } else {
        LOGGER.info("[MDSeguridadService] Perfil de PRODUCCIÓN. Validación SSL estándar habilitada.");
    }

    return builder.build();
}
```

2. **Modificación en `ObtenTokenDeAcceso()`:**
```java
// ANTES:
OkHttpClient client = new OkHttpClient.Builder()
    .connectTimeout(connectTimeout, TimeUnit.MILLISECONDS)
    .readTimeout(readTimeout, TimeUnit.MILLISECONDS)
    .writeTimeout(writeTimeout, TimeUnit.MILLISECONDS)
    .build();

// DESPUÉS:
OkHttpClient client = createConfiguredHttpClient();
```

3. **Modificación en `EjecutaMetodoGET()`:**
```java
// ANTES:
OkHttpClient client = new OkHttpClient.Builder()
    .connectTimeout(connectTimeout, TimeUnit.MILLISECONDS)
    .readTimeout(readTimeout, TimeUnit.MILLISECONDS)
    .writeTimeout(writeTimeout, TimeUnit.MILLISECONDS)
    .build();

// DESPUÉS:
OkHttpClient client = createConfiguredHttpClient();
```

---

## 3. CÓMO FUNCIONA

### 3.1 Detección Automática del Entorno

La solución detecta automáticamente si estás en **desarrollo** o **producción**:

```java
String[] activeProfiles = environment.getActiveProfiles();
boolean isDevelopment = false;
for (String profile : activeProfiles) {
    if (profile.toLowerCase().contains("dev") || profile.toLowerCase().contains("local")) {
        isDevelopment = true;
        break;
    }
}
```

**Perfiles de desarrollo detectados:**
- `development-oracle1`
- `local`
- Cualquier perfil que contenga "dev" o "local" (case-insensitive)

### 3.2 Comportamiento por Entorno

| Entorno | Perfil Maven | Validación SSL | Logs |
|---------|--------------|----------------|------|
| **DESARROLLO** | `development-oracle1` | ❌ DESHABILITADA | `WARN: Aceptando certificados SSL autofirmados` |
| **QA** | `qa` | ✅ HABILITADA | `INFO: Validación SSL estándar habilitada` |
| **PRODUCCIÓN** | `production` | ✅ HABILITADA | `INFO: Validación SSL estándar habilitada` |

### 3.3 Flujo de Ejecución

```
1. AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario()
   ↓
2. mDSeguridadService.EjecutaMetodoGET(ldpUrl, "OBTENER_INFO", ...)
   ↓
3. createConfiguredHttpClient()
   ├─ Detecta perfil activo (development-oracle1)
   ├─ isDevelopment = true
   └─ SSLUtils.configureToAcceptSelfSignedCertificates(builder)
       ├─ Instala TrustManager que acepta todos los certificados
       └─ Instala HostnameVerifier que acepta todos los hostnames
   ↓
4. OkHttpClient configurado realiza llamada HTTPS
   ↓
5. ✅ ÉXITO - Certificado autofirmado aceptado
```

---

## 4. VENTAJAS DE ESTA SOLUCIÓN

### 4.1 Seguridad
✅ Solo afecta entornos de desarrollo
✅ Producción mantiene validación SSL completa
✅ No requiere modificar configuración del sistema operativo
✅ No afecta otras aplicaciones Java en el servidor

### 4.2 Mantenibilidad
✅ Código centralizado en `SSLUtils.java`
✅ Detección automática del entorno (no requiere configuración manual)
✅ Logs claros que indican qué perfil está activo
✅ Fácil de desactivar si es necesario

### 4.3 Despliegue
✅ No requiere cambios en el servidor Tomcat
✅ No requiere importar certificados al truststore de Java
✅ El mismo WAR funciona en desarrollo y producción (detecta automáticamente)
✅ No requiere reiniciar servicios del sistema operativo

---

## 5. ADVERTENCIAS IMPORTANTES

### ⚠️ SOLO PARA DESARROLLO
Esta solución **DESACTIVA** la validación de certificados SSL en entornos de desarrollo. **NO es segura para producción.**

### ⚠️ VULNERABILIDADES SI SE USA EN PRODUCCIÓN
Si esta configuración se activara en producción (cosa que no debería pasar por el filtro de perfiles):
- **Man-in-the-Middle attacks:** Un atacante podría interceptar la comunicación
- **Certificate spoofing:** Certificados falsos serían aceptados
- **Data interception:** Datos sensibles podrían ser capturados

### ⚠️ SOLUCIÓN RECOMENDADA PARA PRODUCCIÓN
Para **QA** y **PRODUCCIÓN**, se debe usar una de estas opciones:
1. **Certificados válidos firmados por CA reconocida** (Let's Encrypt, DigiCert, etc.)
2. **Importar certificado autofirmado al truststore de Java:**
   ```bash
   keytool -import -alias fedidev-crt -file fedidev-crt.pem \
           -keystore "$JAVA_HOME/lib/security/cacerts" \
           -storepass changeit
   ```

---

## 6. PRUEBAS Y VALIDACIÓN

### 6.1 Verificar que funciona en DESARROLLO
1. Desplegar WAR en Tomcat con perfil `development-oracle1`
2. Revisar logs de inicio, debe aparecer:
   ```
   WARN [MDSeguridadService] Perfil de DESARROLLO detectado. Aceptando certificados SSL autofirmados.
   WARN [SSLUtils] Configurando cliente HTTP para aceptar certificados autofirmados. SOLO DESARROLLO.
   INFO [SSLUtils] Cliente HTTP configurado para aceptar certificados autofirmados.
   ```
3. Iniciar sesión con usuario CRT
4. Intentar cargar un documento
5. ✅ Debe funcionar sin error SSL

### 6.2 Verificar que NO afecta PRODUCCIÓN
1. Desplegar mismo WAR con perfil `production`
2. Revisar logs de inicio, debe aparecer:
   ```
   INFO [MDSeguridadService] Perfil de PRODUCCIÓN. Validación SSL estándar habilitada.
   ```
3. ✅ Validación SSL normal activa

---

## 7. TROUBLESHOOTING

### Problema: Sigue apareciendo error SSL en desarrollo
**Solución:**
1. Verificar perfil Maven activo en logs de Tomcat al inicio
2. Buscar línea: `Active profiles: development-oracle1`
3. Si no aparece, revisar configuración de despliegue

### Problema: No aparece el log de "Perfil de DESARROLLO detectado"
**Solución:**
1. Verificar que `MDSeguridadServiceImpl` esté compilado con los cambios
2. Verificar que `SSLUtils.java` exista en el WAR
3. Verificar permisos de archivo `application.properties`

### Problema: Error de compilación con SSLUtils
**Solución:**
1. Verificar que OkHttp esté en las dependencias del POM
2. Verificar imports en SSLUtils:
   ```java
   import okhttp3.OkHttpClient;
   import javax.net.ssl.*;
   ```

---

## 8. IMPACTO EN MIGRACIÓN FEDI 2.0

Este cambio es **complementario** a la migración FEDI 2.0:
- No afecta la lógica de negocio migrada (cat_Roles, tbl_UsuarioRol)
- Solo resuelve problemas de infraestructura SSL en desarrollo
- Permite continuar con las pruebas de la migración
- No introduce nuevas dependencias

---

## 9. PRÓXIMOS PASOS

1. ✅ **Compilar y generar WAR** (COMPLETADO)
2. ⏳ **Desplegar en ambiente de desarrollo**
3. ⏳ **Probar inicio de sesión**
4. ⏳ **Probar carga de documentos**
5. ⏳ **Verificar que no hay más errores SSL**
6. ⏳ **Continuar con pruebas funcionales de FEDI 2.0**

---

## 10. REFERENCIAS

- **FEDI Migration 2.0 Docs:**
  - `01_Resumen_Migracion_FEDI.md`
  - `02_Base_Datos_Cambios.md`
  - `03_Dependencias_Eliminadas.md`
  - `04_Proximos_Pasos.md`

- **Código fuente:**
  - `SSLUtils.java`: Utilidad SSL
  - `MDSeguridadServiceImpl.java`: Cliente HTTP configurado
  - `FEDIServiceImpl.java`: Servicio que llama a API FEDI
  - `AdminUsuariosServiceImpl.java`: Servicio que obtiene info LDAP

---

**Fin del documento**
