# Análisis de Autenticación IFT Exitosa

**Fecha:** 2026-01-29
**Usuario de Prueba:** dgtic.dds.ext023 (IFT)
**Resultado:** ✅ EXITOSO

## 1. Secuencia de Autenticación

### Paso 1: Usuario Ingresa Credenciales en UI
```
Línea 1-3 del log:
- Usuario ingresa: "dgtic.dds.ext023" (SIN dominio @ift.org.mx)
- EsExterno: false
- Contraseña: (encriptada)
```

**IMPORTANTE:** El usuario NO escribe el dominio @ift.org.mx en el login. Solo escribe el nombre de usuario.

### Paso 2: Identificación de Sistema
```
Líneas 7-8 del log:
- Sistema Identificador Interno: 0022FEDI
- Sistema Identificador Externo: 0022FEDI
```

**Configuración en pom.xml:**
```xml
<profile.sistema.identificador>0022FEDI</profile.sistema.identificador>
<profile.sistema.identif.ext>0022FEDI</profile.sistema.identif.ext>
```

### Paso 3: Obtención de Token OAuth2
```
Líneas 16-21 del log:
- URL Token: http://apimanager-dev.ift.org.mx/token
- Token ID length: 82 caracteres
- HTTP Response: 200 OK
- Resultado: Token obtenido exitosamente
```

**URL Completa de Token:**
```
http://apimanager-dev.ift.org.mx/token
```

**Token ID (Base64):**
```
Basic VGZxc3BCYWVYZHhCNlF0SUJHV0EzZUxpMkw0YTpWTUdUVHhqUDVkMl91eFoxdW5uSVBSTGpmZ01h
```

### Paso 4: Construcción de URL de Autenticación
```
Líneas 23-24 del log:
- Método API: 0022FEDI/dgtic.dds.ext023/THhJWFJMOHpQSFVTNERkekZaeTNPVXIvS2w0dnJwVmkxNGpYZDlJUFhKWT0
- URL Completa: https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/0022FEDI/dgtic.dds.ext023/THhJWFJMOHpQSFVTNERkekZaeTNPVXIvS2w0dnJwVmkxNGpYZDlJUFhKWT0
```

**Formato de URL:**
```
https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/{SISTEMA}/{USERNAME}/{PASSWORD_BASE64}
```

**Componentes:**
- `{SISTEMA}`: 0022FEDI
- `{USERNAME}`: dgtic.dds.ext023 (sin dominio, sin encoding)
- `{PASSWORD_BASE64}`: Contraseña encriptada con Encoder.codifica() y luego Base64

### Paso 5: Llamada HTTP GET de Autenticación
```
Líneas 25-32 del log:
- Método HTTP: GET
- Header: Authorization: Bearer {token}
- HTTP Response: 200 OK
- Resultado: Autenticación EXITOSA
```

### Paso 6: Contexto de Seguridad Spring
```
Línea 33 del log:
====== AUTENTICACION EXITOSA para usuario: dgtic.dds.ext023 ======
```

Spring Security crea el contexto de autenticación con UserDetails obtenido del API.

---

## 2. Hallazgos Críticos

### ✅ USERNAME SIN DOMINIO
**Evidencia:** Línea 12 del log
```
>>> Username: dgtic.dds.ext023
```

El código NO agrega @ift.org.mx al username. El backend de IFT lo maneja automáticamente.

### ✅ USERNAME SIN URL ENCODING
**Evidencia:** Línea 24 del log
```
URL completa: .../0022FEDI/dgtic.dds.ext023/...
```

El username NO se codifica con URLEncoder. Se envía tal cual (sin convertir @ a %40).

### ✅ PASSWORD ENCODING
**Evidencia:** Código en AuthenticationServiceImpl.java líneas 169-171
```java
String cadenaClaveCodi=Encoder.codifica(prmClave);
String prmClaveCodificado=Base64.getEncoder().encodeToString(cadenaClaveCodi.getBytes());
prmClaveCodificado= prmClaveCodificado.replace("=", "");
```

La contraseña SÍ se encripta con algoritmo personalizado (Encoder.codifica) y luego Base64.

### ✅ TOKEN BEARER
**Evidencia:** Línea 20 del log (HTTP 200) y código MDSeguridadServiceImpl.java línea 188
```java
.header("Authorization", "Bearer " + prmTokenAcceso)
```

El token OAuth2 se envía en header Authorization con formato "Bearer {token}".

---

## 3. Comparación: Código Erróneo vs Código Correcto

### ❌ Código Erróneo (Rompe Autenticación)
```java
// Auto-append de dominio
if (!prmUsername.contains("@")) {
    if (prmEsExterno) {
        prmUsername = prmUsername + "@crt.gob.mx";
    } else {
        prmUsername = prmUsername + "@ift.org.mx";
    }
}

// URL encoding
String usernameEncoded = URLEncoder.encode(prmUsername, "UTF-8");
vbuilder.append(usernameEncoded);
```

**Por qué falla:**
1. El backend de IFT YA agrega automáticamente el dominio @ift.org.mx
2. Si nosotros lo agregamos, queda duplicado: dgtic.dds.ext023@ift.org.mx@ift.org.mx
3. El backend espera el @ sin codificar, no como %40

### ✅ Código Correcto (Funciona)
```java
// Sin auto-append, sin encoding
vbuilder.append(prmSistema);
vbuilder.append("/");
vbuilder.append(prmUsername);  // Tal cual, sin modificar
vbuilder.append("/");
vbuilder.append(prmClaveCodificado);
```

**Por qué funciona:**
1. El username se envía sin dominio: "dgtic.dds.ext023"
2. El backend de IFT agrega automáticamente @ift.org.mx
3. No hay encoding que rompa el formato esperado

---

## 4. Errores HTTP Observados Durante Desarrollo

### Error HTTP 500
```
Causa: Usuario con dominio agregado manualmente
URL: .../0022FEDI/dgtic.dds.ext023@ift.org.mx/...
Mensaje: "La autenticación del usuario dgtic.dds.ext023@ift.org.mx no es correcta, validación en el repositorio central"
```

**Razón:** Backend de IFT agrega @ift.org.mx automáticamente, si ya viene en el username queda duplicado.

### Error HTTP 404
```
Causa: @ codificado como %40
URL: .../0022FEDI/dgtic.dds.ext023%40ift.org.mx/...
Mensaje: "No matching resource found for given API Request"
```

**Razón:** El API Manager espera @ sin codificar, no reconoce %40 como parte de la ruta.

### Error HTTP 502
```
Causa: Backend no disponible o timeout
Mensaje: "Bad Gateway"
```

**Razón:** Problema de infraestructura, no de código.

---

## 5. Configuración IFT Exitosa

### pom.xml (profile: development-oracle1)
```xml
<profile.mdsgd.token.url>http://apimanager-dev.ift.org.mx/token</profile.mdsgd.token.url>
<profile.mdsgd.token.id>Basic VGZxc3BCYWVYZHhCNlF0SUJHV0EzZUxpMkw0YTpWTUdUVHhqUDVkMl91eFoxdW5uSVBSTGpmZ01h</profile.mdsgd.token.id>
<profile.lgn.api.url>https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/</profile.lgn.api.url>
<profile.mdsgd.api.url>https://apimanager-dev.ift.org.mx/</profile.mdsgd.api.url>
<profile.mdsgd.bit.url>https://apimanager-dev.ift.org.mx/LogEventos/v1.0/bitacora</profile.mdsgd.bit.url>
<profile.sistema.identificador>0022FEDI</profile.sistema.identificador>
<profile.sistema.identif.ext>0022FEDI</profile.sistema.identif.ext>
<profile.autoregistro.url>http://apimanager-dev.ift.org.mx/AutoRegistro/v1.0/autoregistro/</profile.autoregistro.url>
<profile.ldp.url>http://fwldp-dev.ift.org.mx/pruebasPlataformaDigital/api/</profile.ldp.url>
<profile.fedi.url>https://apimanager-dev.ift.org.mx/FEDI/v1.0/</profile.fedi.url>
<profile.fedi.notificaciones.url>https://apimanager-dev.ift.org.mx/Notificaciones/v1.0/</profile.fedi.notificaciones.url>
```

### application.properties
```properties
mdsgd.token.url=${profile.mdsgd.token.url}
mdsgd.token.id=${profile.mdsgd.token.id}
mdsgd.api.url=${profile.mdsgd.api.url}
lgn.api.url=${profile.lgn.api.url}
mdsgd.bit.url=${profile.mdsgd.bit.url}
sistema.identificador=${profile.sistema.identificador}
sistema.identif.ext=${profile.sistema.identif.ext}
autoregistro.url=${profile.autoregistro.url}
ldp.url=${profile.ldp.url}
fedi.url=${profile.fedi.url}
fedi.notificaciones.url=${profile.fedi.notificaciones.url}
```

---

## 6. Conclusiones para Migración CRT

### Hipótesis A: CRT Backend Igual que IFT (Más Probable)
Si el backend de CRT funciona igual que IFT:
- **NO se necesitan cambios de código**
- Solo cambiar URLs en pom.xml de ift.org.mx a crt.gob.mx
- Usuario ingresa sin dominio: "deid.ext33"
- Backend CRT agrega automáticamente @crt.gob.mx

**Acción:** Cambiar solo pom.xml y probar.

### Hipótesis B: CRT Backend Diferente (Menos Probable)
Si el backend de CRT NO agrega dominio automáticamente:
- Necesitamos lógica condicional en código
- Para IFT: enviar username sin dominio
- Para CRT: enviar username CON dominio @crt.gob.mx
- Sin URL encoding en ambos casos

**Acción:** Si Hipótesis A falla, implementar condicional.

### Pruebas Recomendadas
1. **Cambiar solo URLs a CRT en pom.xml**
2. **Probar usuario CRT sin dominio:** "deid.ext33"
3. **Capturar logs completos con código actual**
4. **Analizar HTTP response:**
   - HTTP 200: Backend CRT igual a IFT ✅
   - HTTP 500: Usuario no existe en AD (problema infraestructura)
   - HTTP 404: Backend CRT requiere dominio explícito (implementar Hipótesis B)

---

## 7. Archivos de Código Relevantes

### LoginMB.java
- Línea 251: Log inicio login
- Línea 259: Log login exitoso
- Línea 264: Log login fallido

### AuthenticationServiceImpl.java
- Líneas 64-106: Método login() con logs
- Líneas 139-204: Método loginUsuario() con logs
- Línea 193: `usrio.setClave(prmClave)` - guarda contraseña en objeto Usuario

### MDSeguridadServiceImpl.java
- Líneas 95-150: Método ObtenTokenDeAcceso() con logs
- Líneas 161-216: Método EjecutaMetodoGET() con logs
- Línea 188: Header "Authorization: Bearer {token}"

---

## 8. Checklist Pre-Migración CRT

- [ ] Verificar usuarios CRT existen en Active Directory (contactar infraestructura)
- [ ] Verificar conectividad desde servidor Windows a apimanager-dev.crt.gob.mx
- [ ] Confirmar Token ID es el mismo para IFT y CRT
- [ ] Hacer backup de pom.xml antes de cambios
- [ ] Compilar y desplegar con URLs CRT
- [ ] Probar usuario CRT sin dominio primero: "deid.ext33"
- [ ] Capturar logs completos (token + autenticación)
- [ ] Comparar logs CRT vs logs IFT (este documento)
- [ ] Si falla, verificar HTTP status code para diagnóstico

---

**Última Actualización:** 2026-01-29 22:52
**Autor:** Claude Code
**Versión:** 1.0
