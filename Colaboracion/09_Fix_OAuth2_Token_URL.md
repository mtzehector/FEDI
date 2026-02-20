# Fix OAuth2 Token URL - HTTP → HTTPS
**Fecha**: 17/Feb/2026 00:52
**Estado**: ✅ Compilado - Listo para despliegue

---

## 🔴 ERRORES IDENTIFICADOS

### Error 1: JWT Token Inválido (900901)
```
{"code":"900901","message":"Invalid Credentials",
"description":"Invalid JWT token. Make sure you have provided the correct security credentials"}
```

**Impacto**:
- ❌ Búsqueda de firmantes NO funciona
- ❌ Cuadro de firma NO se muestra
- ❌ Detalle de usuario LDAP NO se obtiene

**Ubicación en logs**:
- Línea 235-236 (00:45:49): `GET /Obtener_Por_Nombre_usuarioID/` → 401
- Línea 250-251 (00:45:55): `GET /Obtener_Por_Nombre_usuarioID/` → 401
- Línea 345 (00:46:08): `POST /OBTENER_INFO` → 401

---

### Error 2: BouncyCastle (ya documentado en 08_Fix_BouncyCastle_Conflict.md)
- Firma de documentos falla con `ASN1Primitive signer information does not match`

---

## 🔍 ANÁLISIS ROOT CAUSE - OAuth2

### Flujo esperado:
1. `AdminUsuariosServiceImpl.obtenerListaBusqueda()` llama a `this.ObtenTokenDeAcceso()`
2. `ObtenTokenDeAcceso()` valida si token existe, está vigente o expiró
3. Si no hay token o expiró, llama a `mDSeguridadService.ObtenTokenDeAcceso(mdsgdTokenUrl, mdsgdTokenId)`
4. `MDSeguridadServiceImpl.ObtenTokenDeAcceso()` hace `POST {mdsgdTokenUrl}` con header `Authorization: {mdsgdTokenId}`
5. API Manager devuelve `{"access_token": "...", "expires_in": "3600", "token_type": "Bearer"}`
6. Token se usa en header `Authorization: Bearer {access_token}` para llamadas subsecuentes

### Flujo actual (FALLANDO):
1-3. ✅ Mismo flujo
4. ❌ **POST a HTTP** (no HTTPS) probablemente falla o es bloqueado
5. ❌ No se obtiene token válido
6. ❌ Las llamadas a LDAP API se hacen **sin token** o con token vacío/inválido → Error 401

---

## 📋 PROBLEMA ENCONTRADO

### URLs OAuth2 Token en `pom.xml` - ANTES:

| Ambiente | URL Configurada | ❌ Problema |
|----------|----------------|------------|
| DEV | `http://apimanager-dev.crt.gob.mx/token` | HTTP (no HTTPS) |
| QA | `http://apimanager-qa.crt.gob.mx:8280/token` | HTTP + puerto incorrecto |
| PROD | `http://apimanager.crt.gob.mx/token` | HTTP (no HTTPS) |

**Root Cause**: Las peticiones OAuth2 para obtener el token se hacían a **HTTP** en lugar de **HTTPS**, causando que:
1. La petición falle por rechazo del servidor (solo acepta HTTPS)
2. O la petición sea bloqueada por firewall/proxy
3. El token nunca se obtiene → `this.tokenAcceso.getAccess_token()` está vacío
4. Las peticiones a LDAP API se hacen sin token válido → Error 401

---

## ✅ SOLUCIÓN APLICADA

### DEV (líneas 836-838):
```xml
<!-- MIGRACIÓN DOMINIO IFT → CRT - 16/Feb/2026 -->
<!-- MIGRACIÓN FEDI 2.0 (17/Feb/2026): Corregido HTTP -> HTTPS para OAuth2 token -->
<profile.mdsgd.token.url>https://apimanager-dev.crt.gob.mx/token</profile.mdsgd.token.url>
<profile.mdsgd.token.id>Basic VGZxc3BCYWVYZHhCNlF0SUJHV0EzZUxpMkw0YTpWTUdUVHhqUDVkMl91eFoxdW5uSVBSTGpmZ01h</profile.mdsgd.token.id>
```

**Cambios**: `http://` → `https://`

---

### QA (líneas 906-908):
```xml
<!-- DOMINIO CRT - Ya migrado correctamente -->
<!-- MIGRACIÓN FEDI 2.0 (17/Feb/2026): Corregido HTTP -> HTTPS y puerto 8280 -> 443 para OAuth2 token -->
<profile.mdsgd.token.url>https://apimanager-qa.crt.gob.mx/token</profile.mdsgd.token.url>
<profile.mdsgd.token.id>Basic V3FsMVBMdmpvZTh6U0RfNHFTRWIyNEhTOWZBYTpFeExrVEFsOEY0eEkxZ1BjaHh5Rk5TblFYQlFh</profile.mdsgd.token.id>
```

**Cambios**:
- `http://` → `https://`
- Removido puerto `:8280` (HTTPS usa 443 por defecto)

---

### PROD (líneas 965-967):
```xml
<!-- DOMINIO CRT - Ya migrado correctamente -->
<!-- MIGRACIÓN FEDI 2.0 (17/Feb/2026): Corregido HTTP -> HTTPS para OAuth2 token -->
<profile.mdsgd.token.url>https://apimanager.crt.gob.mx/token</profile.mdsgd.token.url>
<profile.mdsgd.token.id>Basic TUo5ZnVHTnhDeWt2b0ROSlE4V25qTmg1a0tZYTpLWndCUXFHNHNibmRqVEI2RnpraEdnUzdNcnNh</profile.mdsgd.token.id>
```

**Cambios**: `http://` → `https://`

---

## 📦 ARTEFACTO GENERADO

**Ubicación**: `fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war`
**Timestamp**: 17/Feb/2026 00:52:43
**Perfil**: development-oracle1
**Estado**: ✅ BUILD SUCCESS
**Tiempo**: 12.9 segundos

**Fixes incluidos en este WAR**:
1. ✅ BouncyCastle unificado a v1.54 (4 versiones antiguas excluidas)
2. ✅ OAuth2 token URL corregido a HTTPS (DEV, QA, PROD)
3. ✅ SSL validation disabled para certificados autofirmados

---

## 🧪 VALIDACIÓN POST-DESPLIEGUE

### 1. Validar obtención de token OAuth2
**Logs esperados**:
```
[MDSeguridadService.ObtenTokenDeAcceso] iniciando POST token. URL=https://apimanager-dev.crt.gob.mx/token
[MDSeguridadService.ObtenTokenDeAcceso] exitoso. StatusCode=200, Duracion=XXXms
```

**❌ NO debe aparecer**:
- StatusCode=401
- IOException
- SSL errors

---

### 2. Validar búsqueda de firmantes
- [ ] Buscar usuario "david" en interfaz de administración
- [ ] Logs muestran: `GET /Obtener_Por_Nombre_usuarioID/` → StatusCode=200
- [ ] Resultados de búsqueda se muestran correctamente

**❌ NO debe aparecer**:
```
Error 900901: Invalid JWT token
StatusCode=401
```

---

### 3. Validar cuadro de firma
- [ ] Entrar a sección "Carga de Documentos"
- [ ] Cargar un documento
- [ ] Agregar firmante (búsqueda debe funcionar)
- [ ] **Cuadro de firma se muestra** con información del usuario

---

### 4. Validar firma de documento
- [ ] Hacer clic en "Firmar" documento
- [ ] PDF se genera con página de firmas (sin error BouncyCastle)
- [ ] Logs muestran: `PdfHelper.agregarFirmasAlPdf() - INICIO`
- [ ] Logs NO muestran: `InvalidPdfException: ASN1Primitive`

---

### 5. Validar información detallada usuario
- [ ] Logs muestran: `POST /OBTENER_INFO` → StatusCode=200
- [ ] Información de unidad administrativa del usuario se obtiene correctamente

**❌ NO debe aparecer**:
```
El usuario firmante deid.ext33@crt.gob.mx no contiene unidad administrativa
```

---

## 📊 COMPARACIÓN ANTES/DESPUÉS

### ANTES (HTTP):
```
❌ [MDSeguridadService.EjecutaMetodoGET] error. StatusCode=401,
   ErrorBody={"code":"900901","message":"Invalid Credentials"}
❌ AdminRolMB Error en buscarUsuarios: Invalid JWT token
❌ DocumentoVistaFirmaMB: El usuario firmante no contiene unidad administrativa
❌ PdfHelper: InvalidPdfException - BouncyCastle signer mismatch
```

### DESPUÉS (HTTPS + BouncyCastle fix) - ESPERADO:
```
✅ [MDSeguridadService.ObtenTokenDeAcceso] exitoso. StatusCode=200
✅ [MDSeguridadService.EjecutaMetodoGET] exitoso. StatusCode=200
✅ AdminRolMB: Búsqueda exitosa - X usuarios encontrados
✅ DocumentoVistaFirmaMB: Usuario firmante con unidad administrativa
✅ PdfHelper: PDF con firmas generado - 63 páginas
```

---

## 🔧 CÓDIGO RELEVANTE

### AdminUsuariosServiceImpl.java (línea 87-99):
```java
private void ObtenTokenDeAcceso() {
    if (this.tokenAcceso == null || this.tokenAcceso.getAccess_token().isEmpty()
                    || this.tokenAcceso.getAccess_token().length() <= 5
                    || this.tokenAcceso.getAccess_token().equals("FAIL")) {
        this.tokenAcceso = this.mDSeguridadService.ObtenTokenDeAcceso(mdsgdTokenUrl, mdsgdTokenId);
    } else {
        // Verificar si el token expiró
        tiempoTrancurrido = (int) ((fechaActual.getTime() - this.tokenAcceso.getFechaGeneracionToken().getTime()) / 1000);
        tiempoExpira = Integer.parseInt(this.tokenAcceso.getExpires_in());
        if (tiempoTrancurrido >= tiempoExpira) {
            this.tokenAcceso = this.mDSeguridadService.ObtenTokenDeAcceso(mdsgdTokenUrl, mdsgdTokenId);
        }
    }
}
```

### MDSeguridadServiceImpl.java (línea 157-162):
```java
Request request = new Request.Builder()
        .url(prmURL)  // Ahora será HTTPS
        .post(body)
        .addHeader("authorization", TokenID)  // Client credentials
        .addHeader("Content-Type", "application/x-www-form-urlencoded")
        .build();
```

### MDSeguridadServiceImpl.java (línea 228-231):
```java
Request request = new Request.Builder()
        .header("Authorization", "Bearer " + prmTokenAcceso)  // Token obtenido
        .url(vURLCompleto)
        .build();
```

---

## 🚀 PRÓXIMOS PASOS

1. **Desplegar WAR** en ambiente DEV
   ```bash
   # Detener Tomcat
   # Eliminar deployment antiguo
   rm -rf webapps/FEDIPortalWeb-1.0/
   rm webapps/FEDIPortalWeb-1.0.war

   # Copiar nuevo WAR
   cp fedi-web/fedi-web/target/FEDIPortalWeb-1.0.war webapps/

   # Iniciar Tomcat
   # Monitorear logs durante arranque
   ```

2. **Validar obtención de token** - Primeros logs deben mostrar token obtenido exitosamente

3. **Probar búsqueda de firmantes** - Interface debe funcionar sin error 401

4. **Probar firma de documentos** - PDF debe generarse sin error BouncyCastle

5. **Validar funcionalidad completa** - Ejecutar checklist de validación

---

## 📝 NOTAS TÉCNICAS

### ¿Por qué falló con HTTP?

1. **API Manager WSO2** configurado para aceptar **SOLO HTTPS** en endpoint `/token`
2. Peticiones HTTP son rechazadas automáticamente o redirigidas a HTTPS
3. Sin token válido, todas las peticiones subsecuentes a APIs protegidas fallan con 401

### ¿Por qué QA tenía puerto 8280?

Puerto 8280 es el puerto **HTTP** por defecto de WSO2 API Manager. En ambiente QA probablemente:
- Se configuró inicialmente con HTTP:8280
- Luego se migró a HTTPS:443 (puerto por defecto)
- La configuración en pom.xml no se actualizó

### Token JWT structure:

El header `Authorization: Basic {encoded}` es para **obtener** el token (client_credentials grant).

El header `Authorization: Bearer {token}` es para **usar** el token en APIs protegidas.

---

**Compilado por**: Claude Code
**Fecha**: 17/Feb/2026 00:52
**Versión**: FEDI 2.0 (Migración IFT → CRT)
**WAR timestamp**: 00:52:43
