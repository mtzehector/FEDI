# Comparación de Logs: IFT vs CRT

**Propósito:** Documento de referencia para comparar logs de autenticación IFT exitosa con logs de CRT (cuando estén disponibles) para identificar diferencias en el comportamiento de los backends.

---

## 1. Logs IFT Exitosos (Referencia)

### Login Completo Usuario IFT
**Usuario:** dgtic.dds.ext023 (sin @ift.org.mx)
**Fecha:** 2026-01-29 22:44:03
**Resultado:** ✅ EXITOSO

```
Línea 1: 2026-01-29 22:44:03 INFO  LoginMB:136 - Entro LoginMB.login 1
Línea 2: 2026-01-29 22:44:03 INFO  LoginMB:166 - Entro LoginMB.login 3, inicia sesion.
Línea 3: 2026-01-29 22:44:03 INFO  LoginMB:251 - === INICIO LOGIN === Usuario: dgtic.dds.ext023, EsExterno: false
Línea 4: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:67 - ====== AuthenticationServiceImpl.login() INICIO ======
Línea 5: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:68 - Usuario: dgtic.dds.ext023
Línea 6: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:69 - EsExterno: false
Línea 7: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:70 - Sistema Identificador Interno: 0022FEDI
Línea 8: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:71 - Sistema Identificador Externo: 0022FEDI
Línea 9: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:78 - Autenticando como USUARIO INTERNO con sistema: 0022FEDI
Línea 10: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:149 - >>> loginUsuario() - INICIO
Línea 11: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:150 - >>> Sistema: 0022FEDI
Línea 12: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:151 - >>> Username: dgtic.dds.ext023
Línea 13: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:152 - >>> EsExterno: false
Línea 14: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:153 - >>> Token URL: http://apimanager-dev.ift.org.mx/token
Línea 15: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:154 - >>> Login API URL: https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/
Línea 16: 2026-01-29 22:44:03 INFO  MDSeguridadServiceImpl:97 - ****** ObtenTokenDeAcceso() INICIO ******
Línea 17: 2026-01-29 22:44:03 INFO  MDSeguridadServiceImpl:98 - ****** Token URL: http://apimanager-dev.ift.org.mx/token
Línea 18: 2026-01-29 22:44:03 INFO  MDSeguridadServiceImpl:99 - ****** Token ID length: 82
Línea 19: 2026-01-29 22:44:03 INFO  MDSeguridadServiceImpl:123 - ****** Ejecutando llamada al servicio de token...
Línea 20: 2026-01-29 22:44:03 INFO  MDSeguridadServiceImpl:126 - ****** Respuesta recibida - Codigo HTTP: 200
Línea 21: 2026-01-29 22:44:03 INFO  MDSeguridadServiceImpl:136 - ****** Token obtenido exitosamente
Línea 22: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:158 - >>> Token obtenido exitosamente
Línea 23: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:181 - >>> Metodo API construido: 0022FEDI/dgtic.dds.ext023/THhJWFJMOHpQSFVTNERkekZaeTNPVXIvS2w0dnJwVmkxNGpYZDlJUFhKWT0
Línea 24: 2026-01-29 22:44:03 INFO  AuthenticationServiceImpl:182 - >>> URL completa: https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/0022FEDI/dgtic.dds.ext023/THhJWFJMOHpQSFVTNERkekZaeTNPVXIvS2w0dnJwVmkxNGpYZDlJUFhKWT0
Línea 25: 2026-01-29 22:44:03 INFO  MDSeguridadServiceImpl:163 - @@@@@@ EjecutaMetodoGET() INICIO @@@@@@
Línea 26: 2026-01-29 22:44:03 INFO  MDSeguridadServiceImpl:164 - @@@@@@ URL Base: https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/
Línea 27: 2026-01-29 22:44:03 INFO  MDSeguridadServiceImpl:165 - @@@@@@ Metodo: 0022FEDI/dgtic.dds.ext023/THhJWFJMOHpQSFVTNERkekZaeTNPVXIvS2w0dnJwVmkxNGpYZDlJUFhKWT0
Línea 28: 2026-01-29 22:44:03 INFO  MDSeguridadServiceImpl:184 - @@@@@@ URL COMPLETA: https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/0022FEDI/dgtic.dds.ext023/THhJWFJMOHpQSFVTNERkekZaeTNPVXIvS2w0dnJwVmkxNGpYZDlJUFhKWT0
Línea 29: 2026-01-29 22:44:03 INFO  MDSeguridadServiceImpl:191 - @@@@@@ Ejecutando llamada HTTP GET...
Línea 30: 2026-01-29 22:44:04 INFO  MDSeguridadServiceImpl:194 - @@@@@@ Respuesta recibida - Codigo HTTP: 200
Línea 31: 2026-01-29 22:44:04 INFO  MDSeguridadServiceImpl:195 - @@@@@@ Mensaje HTTP:
Línea 32: 2026-01-29 22:44:04 INFO  MDSeguridadServiceImpl:202 - @@@@@@ Autenticacion EXITOSA - respuesta recibida
Línea 33: 2026-01-29 22:44:04 INFO  AuthenticationServiceImpl:85 - ====== AUTENTICACION EXITOSA para usuario: dgtic.dds.ext023 ======
Línea 34: 2026-01-29 22:44:04 INFO  LoginMB:259 - === LOGIN EXITOSO === Usuario: dgtic.dds.ext023
```

---

## 2. Puntos Clave a Comparar con Logs CRT

### 2.1. Username Format
**IFT (Línea 12):**
```
>>> Username: dgtic.dds.ext023
```

**CRT (Esperado):**
```
>>> Username: deid.ext33
```

**Qué Verificar:**
- ✅ Username SIN dominio en ambos
- ❌ Si CRT muestra username CON dominio, indica auto-append de código (Plan B activado)

---

### 2.2. URLs de API Manager
**IFT (Líneas 14-15):**
```
>>> Token URL: http://apimanager-dev.ift.org.mx/token
>>> Login API URL: https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/
```

**CRT (Esperado):**
```
>>> Token URL: http://apimanager-dev.crt.gob.mx/token
>>> Login API URL: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/
```

**Qué Verificar:**
- ✅ URLs correctamente cambiadas a dominio CRT
- ✅ Rutas de API iguales: `/token` y `/autorizacion/login/v1.0/credencial/`

---

### 2.3. Token Acquisition
**IFT (Líneas 16-21):**
```
****** ObtenTokenDeAcceso() INICIO ******
****** Token URL: http://apimanager-dev.ift.org.mx/token
****** Token ID length: 82
****** Ejecutando llamada al servicio de token...
****** Respuesta recibida - Codigo HTTP: 200
****** Token obtenido exitosamente
```

**CRT (Esperado):**
```
****** ObtenTokenDeAcceso() INICIO ******
****** Token URL: http://apimanager-dev.crt.gob.mx/token
****** Token ID length: 82
****** Ejecutando llamada al servicio de token...
****** Respuesta recibida - Codigo HTTP: 200
****** Token obtenido exitosamente
```

**Qué Verificar:**
- ✅ HTTP 200 en obtención de token
- ✅ Token ID length: 82 (mismo Token ID para IFT y CRT)
- ❌ Si HTTP != 200, problema con Token ID o endpoint /token no disponible

---

### 2.4. URL Construction
**IFT (Líneas 23-24):**
```
>>> Metodo API construido: 0022FEDI/dgtic.dds.ext023/THhJWFJMOHpQSFVTNERkekZaeTNPVXIvS2w0dnJwVmkxNGpYZDlJUFhKWT0
>>> URL completa: https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/0022FEDI/dgtic.dds.ext023/THhJWFJMOHpQSFVTNERkekZaeTNPVXIvS2w0dnJwVmkxNGpYZDlJUFhKWT0
```

**Formato:**
```
{API_BASE_URL}/{SISTEMA}/{USERNAME}/{PASSWORD_BASE64}
```

**CRT (Esperado - Escenario A):**
```
>>> Metodo API construido: 0022FEDI/deid.ext33/{PASSWORD_BASE64}
>>> URL completa: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/0022FEDI/deid.ext33/{PASSWORD_BASE64}
```

**CRT (Esperado - Escenario B con Plan B):**
```
>>> Username con dominio CRT agregado: deid.ext33@crt.gob.mx
>>> Metodo API construido: 0022FEDI/deid.ext33@crt.gob.mx/{PASSWORD_BASE64}
>>> URL completa: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/0022FEDI/deid.ext33@crt.gob.mx/{PASSWORD_BASE64}
```

**Qué Verificar:**
- ✅ Sistema: 0022FEDI en ambos
- ✅ Username sin encoding (@ sin convertir a %40)
- ✅ Password Base64 sin caracteres "=" al final
- ⚠️ Si aparece log "Username con dominio CRT agregado", Plan B está activo

---

### 2.5. Authentication HTTP Call
**IFT (Líneas 25-32):**
```
@@@@@@ EjecutaMetodoGET() INICIO @@@@@@
@@@@@@ URL Base: https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/
@@@@@@ Metodo: 0022FEDI/dgtic.dds.ext023/THhJWFJMOHpQSFVTNERkekZaeTNPVXIvS2w0dnJwVmkxNGpYZDlJUFhKWT0
@@@@@@ URL COMPLETA: https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/0022FEDI/dgtic.dds.ext023/THhJWFJMOHpQSFVTNERkekZaeTNPVXIvS2w0dnJwVmkxNGpYZDlJUFhKWT0
@@@@@@ Ejecutando llamada HTTP GET...
@@@@@@ Respuesta recibida - Codigo HTTP: 200
@@@@@@ Mensaje HTTP:
@@@@@@ Autenticacion EXITOSA - respuesta recibida
```

**CRT (Esperado - Exitoso):**
```
@@@@@@ EjecutaMetodoGET() INICIO @@@@@@
@@@@@@ URL Base: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/
@@@@@@ Metodo: 0022FEDI/deid.ext33/{PASSWORD_BASE64}
@@@@@@ URL COMPLETA: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/0022FEDI/deid.ext33/{PASSWORD_BASE64}
@@@@@@ Ejecutando llamada HTTP GET...
@@@@@@ Respuesta recibida - Codigo HTTP: 200
@@@@@@ Mensaje HTTP:
@@@@@@ Autenticacion EXITOSA - respuesta recibida
```

**Qué Verificar:**
- ✅ HTTP 200: Autenticación exitosa (Escenario A confirmado)
- ❌ HTTP 500: Usuario no existe en AD (problema infraestructura)
- ❌ HTTP 404: Backend requiere dominio explícito (activar Plan B)
- ❌ HTTP 502: Backend no disponible (problema conectividad)

---

### 2.6. Final Authentication Result
**IFT (Líneas 33-34):**
```
====== AUTENTICACION EXITOSA para usuario: dgtic.dds.ext023 ======
=== LOGIN EXITOSO === Usuario: dgtic.dds.ext023
```

**CRT (Esperado):**
```
====== AUTENTICACION EXITOSA para usuario: deid.ext33 ======
=== LOGIN EXITOSO === Usuario: deid.ext33
```

**Qué Verificar:**
- ✅ Mensaje "AUTENTICACION EXITOSA" aparece
- ✅ Mensaje "LOGIN EXITOSO" aparece
- ✅ Username correcto sin modificaciones

---

## 3. Tabla de Comparación Rápida

| Componente | IFT | CRT (Esperado) | Verificar |
|------------|-----|----------------|-----------|
| **Username Ingresado** | dgtic.dds.ext023 | deid.ext33 | Sin dominio |
| **Sistema Identificador** | 0022FEDI | 0022FEDI | Igual |
| **Token URL** | apimanager-dev.ift.org.mx | apimanager-dev.crt.gob.mx | Dominio cambiado |
| **Login API URL** | apimanager-dev.ift.org.mx | apimanager-dev.crt.gob.mx | Dominio cambiado |
| **Token ID Length** | 82 | 82 | Igual |
| **Token HTTP Code** | 200 | 200 | Exitoso |
| **Username en URL** | dgtic.dds.ext023 | deid.ext33 | Sin encoding |
| **Auth HTTP Code** | 200 | 200 / 404 / 500 | Diagnóstico |
| **Resultado Final** | LOGIN EXITOSO | LOGIN EXITOSO | Exitoso |

---

## 4. Logs de Errores CRT (Posibles Escenarios)

### Escenario Error A: Usuario No Existe (HTTP 500)
```
2026-01-XX XX:XX:XX INFO  LoginMB:251 - === INICIO LOGIN === Usuario: deid.ext33, EsExterno: false
2026-01-XX XX:XX:XX INFO  AuthenticationServiceImpl:67 - ====== AuthenticationServiceImpl.login() INICIO ======
2026-01-XX XX:XX:XX INFO  AuthenticationServiceImpl:68 - Usuario: deid.ext33
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:126 - ****** Respuesta recibida - Codigo HTTP: 200
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:136 - ****** Token obtenido exitosamente
2026-01-XX XX:XX:XX INFO  AuthenticationServiceImpl:182 - >>> URL completa: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/0022FEDI/deid.ext33/...
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:191 - @@@@@@ Ejecutando llamada HTTP GET...
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:194 - @@@@@@ Respuesta recibida - Codigo HTTP: 500
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:195 - @@@@@@ Mensaje HTTP: Internal Server Error
2026-01-XX XX:XX:XX ERROR MDSeguridadServiceImpl:206 - @@@@@@ Error credenciales de usuario: 500 - Internal Server Error
2026-01-XX XX:XX:XX ERROR MDSeguridadServiceImpl:208 - @@@@@@ Detalle del error: {"code":"500","message":"La autenticación del usuario deid.ext33 no es correcta, validación en el repositorio central"}
2026-01-XX XX:XX:XX ERROR AuthenticationServiceImpl:99 - ====== ERROR AuthenticationServiceImpl.login() ======
2026-01-XX XX:XX:XX ERROR AuthenticationServiceImpl:101 - Codigo Error: 500, Mensaje: La autenticación del usuario deid.ext33 no es correcta
2026-01-XX XX:XX:XX ERROR LoginMB:264 - === LOGIN FALLIDO === Usuario: deid.ext33, Externo: false, Error: 500: La autenticación del usuario deid.ext33 no es correcta
```

**Diferencia con IFT:**
- IFT: HTTP 200 en línea 30
- CRT: HTTP 500 en línea 8

**Diagnóstico:** Usuario no existe en Active Directory CRT

**Acción:** Contactar infraestructura para verificar registro de usuario

---

### Escenario Error B: Backend Requiere Dominio (HTTP 404)
```
2026-01-XX XX:XX:XX INFO  LoginMB:251 - === INICIO LOGIN === Usuario: deid.ext33, EsExterno: false
2026-01-XX XX:XX:XX INFO  AuthenticationServiceImpl:67 - ====== AuthenticationServiceImpl.login() INICIO ======
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:126 - ****** Respuesta recibida - Codigo HTTP: 200
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:136 - ****** Token obtenido exitosamente
2026-01-XX XX:XX:XX INFO  AuthenticationServiceImpl:182 - >>> URL completa: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/0022FEDI/deid.ext33/...
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:191 - @@@@@@ Ejecutando llamada HTTP GET...
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:194 - @@@@@@ Respuesta recibida - Codigo HTTP: 404
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:195 - @@@@@@ Mensaje HTTP: Not Found
2026-01-XX XX:XX:XX ERROR MDSeguridadServiceImpl:206 - @@@@@@ Error credenciales de usuario: 404 - Not Found
2026-01-XX XX:XX:XX ERROR MDSeguridadServiceImpl:208 - @@@@@@ Detalle del error: {"code":"404","message":"No matching resource found for given API Request"}
2026-01-XX XX:XX:XX ERROR AuthenticationServiceImpl:99 - ====== ERROR AuthenticationServiceImpl.login() ======
```

**Diferencia con IFT:**
- IFT: HTTP 200 en línea 30
- CRT: HTTP 404 en línea 7

**Diagnóstico:** Backend CRT no reconoce ruta con username sin dominio

**Acción:** Activar Plan B (lógica condicional para agregar @crt.gob.mx)

---

### Escenario Error C: Backend No Disponible (HTTP 502 o Timeout)
```
2026-01-XX XX:XX:XX INFO  LoginMB:251 - === INICIO LOGIN === Usuario: deid.ext33, EsExterno: false
2026-01-XX XX:XX:XX INFO  AuthenticationServiceImpl:67 - ====== AuthenticationServiceImpl.login() INICIO ======
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:126 - ****** Respuesta recibida - Codigo HTTP: 200
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:136 - ****** Token obtenido exitosamente
2026-01-XX XX:XX:XX INFO  AuthenticationServiceImpl:182 - >>> URL completa: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/0022FEDI/deid.ext33/...
2026-01-XX XX:XX:XX INFO  MDSeguridadServiceImpl:191 - @@@@@@ Ejecutando llamada HTTP GET...
2026-01-XX XX:XX:XX ERROR MDSeguridadServiceImpl:212 - @@@@@@ Error IOException en EjecutaMetodoGET: timeout
```

**Diferencia con IFT:**
- IFT: HTTP 200 en línea 30 (1 segundo después de GET)
- CRT: IOException timeout (sin respuesta HTTP)

**Diagnóstico:** Backend CRT no disponible o problema de red

**Acción:** Verificar conectividad y disponibilidad del servicio

---

## 5. Uso de Esta Comparación

### Cuando Obtenga Logs CRT:

1. **Copiar logs CRT a este documento** (Sección 6)
2. **Comparar línea por línea** con logs IFT (Sección 1)
3. **Identificar primera diferencia** (generalmente en HTTP response code)
4. **Consultar sección de errores** (Sección 4) para diagnóstico
5. **Seguir acción recomendada** en Guía de Migración CRT

### Preguntas a Responder:

1. **¿Token se obtiene exitosamente?**
   - IFT: Línea 20 - HTTP 200
   - CRT: Buscar línea similar con HTTP code

2. **¿Username tiene mismo formato?**
   - IFT: Línea 12 - "dgtic.dds.ext023" (sin dominio)
   - CRT: Buscar línea similar - debe ser "deid.ext33" (sin dominio)

3. **¿URL construida correctamente?**
   - IFT: Línea 24 - Username SIN encoding
   - CRT: Buscar línea similar - verificar formato

4. **¿Qué HTTP code devuelve autenticación?**
   - IFT: Línea 30 - HTTP 200
   - CRT: Buscar línea similar - diagnóstico según código

5. **¿Autenticación exitosa?**
   - IFT: Línea 33-34 - "AUTENTICACION EXITOSA"
   - CRT: Buscar líneas similares

---

## 6. Logs CRT (Placeholder - Completar Después de Pruebas)

**Instrucciones:**
1. Después de migrar a CRT (cambiar URLs en pom.xml)
2. Probar usuario CRT: deid.ext33 (sin dominio)
3. Capturar logs completos de `C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\fedi.log`
4. Pegar logs aquí debajo
5. Comparar con logs IFT (Sección 1)

```
[PEGAR LOGS CRT AQUÍ DESPUÉS DE PRIMERA PRUEBA]
```

---

## 7. Análisis de Diferencias (Completar Después)

### Diferencias Encontradas

| Línea/Componente | IFT | CRT | Análisis |
|------------------|-----|-----|----------|
| Token HTTP Code | 200 | ??? | |
| Token Exitoso | Sí | ??? | |
| Username Format | dgtic.dds.ext023 | ??? | |
| URL Domain | ift.org.mx | ??? | |
| Auth HTTP Code | 200 | ??? | |
| Auth Exitosa | Sí | ??? | |

### Conclusión

```
[COMPLETAR DESPUÉS DE ANÁLISIS:
- ¿CRT funciona igual que IFT?
- ¿Se necesita Plan B?
- ¿Problema de infraestructura?]
```

---

**Última Actualización:** 2026-01-29 23:15
**Autor:** Claude Code
**Versión:** 1.0
**Estado:** LISTO PARA USAR DESPUÉS DE PRUEBAS CRT
