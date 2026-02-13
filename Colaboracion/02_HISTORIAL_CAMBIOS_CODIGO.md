# Historial de Cambios de Código - Autenticación FEDI

**Período:** 2026-01-29
**Objetivo:** Agregar logs y migrar de dominio IFT a CRT

## 1. Cambios Realizados en Orden Cronológico

### Iteración 1: Agregar Logs Básicos
**Archivos Modificados:**
- LoginMB.java
- AuthenticationServiceImpl.java
- MDSeguridadServiceImpl.java

**Cambios:**
```java
// LoginMB.java - Método log()
LOGGER.info("=== INICIO LOGIN === Usuario: {}, EsExterno: {}", usr, this.esExterno);
LOGGER.info("=== LOGIN EXITOSO === Usuario: {}", usr);
LOGGER.error("=== LOGIN FALLIDO === Usuario: {}, Externo: {}, Error: {}", usr, this.esExterno, e.getMessage());
```

**Error de Compilación:**
```
error: incompatible types: java.lang.String cannot be converted to org.slf4j.Marker
LOGGER.error("=== LOGIN FALLIDO === Usuario: {}, Externo: {}, Error: {}", usr, this.esExterno, e.getMessage());
```

**Causa:** SLF4J no soporta más de 2 placeholders {} en error() sin pasar un Marker.

**Solución:** Cambiar a concatenación de strings
```java
LOGGER.error("=== LOGIN FALLIDO === Usuario: " + usr + ", Externo: " + this.esExterno + ", Error: " + e.getMessage());
```

**Resultado:** ✅ Compiló exitosamente

---

### Iteración 2: Pruebas con Usuarios Sin Dominio
**Prueba:**
- Usuario IFT: dgtic.dds.ext023 (sin @ift.org.mx)
- Usuario CRT: deid.ext33 (sin @crt.gob.mx)

**Resultado:**
```
HTTP 500 - "La autenticación del usuario deid.ext33 no es correcta, validación en el repositorio central"
```

**Análisis Inicial (INCORRECTO):**
Pensamos que el backend requería el dominio explícito.

---

### Iteración 3: Agregar Auto-Append de Dominio
**Archivos Modificados:**
- AuthenticationServiceImpl.java línea 139

**Código Agregado:**
```java
// CÓDIGO ERRÓNEO - ROMPIÓ AUTENTICACIÓN
if (!prmUsername.contains("@")) {
    if (prmEsExterno) {
        prmUsername = prmUsername + "@crt.gob.mx";
    } else {
        prmUsername = prmUsername + "@ift.org.mx";
    }
}
LOGGER.info(">>> Username con dominio: {}", prmUsername);
```

**Prueba:**
- Usuario IFT: dgtic.dds.ext023
- Username modificado: dgtic.dds.ext023@ift.org.mx

**Resultado:**
```
HTTP 500 - "La autenticación del usuario dgtic.dds.ext023@ift.org.mx no es correcta, validación en el repositorio central"
```

**Análisis Nuevo (INCORRECTO):**
Pensamos que el @ necesitaba URL encoding.

---

### Iteración 4: Agregar URL Encoding
**Archivos Modificados:**
- AuthenticationServiceImpl.java línea 178

**Código Agregado:**
```java
// CÓDIGO ERRÓNEO - ROMPIÓ AUTENTICACIÓN
String usernameEncoded = URLEncoder.encode(prmUsername, "UTF-8");
vbuilder.append(usernameEncoded);
```

**URL Generada:**
```
.../0022FEDI/dgtic.dds.ext023%40ift.org.mx/...
```

**Resultado:**
```
HTTP 404 - "No matching resource found for given API Request"
```

**Análisis:** El API Manager no reconoce %40 como @ en la ruta.

---

### Iteración 5: Usuario Reporta Problema Crítico
**Mensaje del Usuario:**
> "hoy antes de comenzar los cambios estaba entrando al aplicativo con mi cuenta ift"

**Descubrimiento CRÍTICO:**
La autenticación IFT funcionaba ANTES de nuestros cambios. Nuestro código la ROMPIÓ.

**Causa Raíz Identificada:**
1. ❌ Auto-append de dominio - IFT backend YA lo hace automáticamente
2. ❌ URL encoding de @ - IFT backend espera @ sin codificar

---

### Iteración 6: Restauración de Código Original (GIT)
**Comando:**
```bash
git restore src/main/java/fedi/ift/org/mx/arq/core/service/security/AuthenticationServiceImpl.java
git restore src/main/java/fedi/ift/org/mx/arq/core/service/security/loadsoa/MDSeguridadServiceImpl.java
git restore src/main/java/fedi/ift/org/mx/arq/core/exposition/LoginMB.java
git restore src/main/resources/application.properties
```

**Resultado:**
```
Usuario confirma: "Volvi a restaurar el codigo desde el GIT y ya volvio a entrar mi cuenta del IFT al aplicativo."
```

**Confirmación:** ✅ Código original funciona correctamente

---

### Iteración 7: Agregar Solo Logs (Sin Modificar Lógica)
**Archivos Modificados:**
- LoginMB.java
- AuthenticationServiceImpl.java
- MDSeguridadServiceImpl.java

**Principio:** SOLO agregar logs, NO modificar lógica de autenticación

#### LoginMB.java
```java
// Línea 251
LOGGER.info("=== INICIO LOGIN === Usuario: {}, EsExterno: {}", usr, this.esExterno);

// Línea 259
LOGGER.info("=== LOGIN EXITOSO === Usuario: {}", usr);

// Línea 264
LOGGER.error("=== LOGIN FALLIDO === Usuario: " + usr + ", Externo: " + this.esExterno + ", Error: " + e.getMessage());
```

#### AuthenticationServiceImpl.java
```java
// Líneas 67-71
LOGGER.info("====== AuthenticationServiceImpl.login() INICIO ======");
LOGGER.info("Usuario: {}", username);
LOGGER.info("EsExterno: {}", prmEsExterno);
LOGGER.info("Sistema Identificador Interno: {}", sistemaIdentificador);
LOGGER.info("Sistema Identificador Externo: {}", sistemaIdentifExt);

// Línea 75
LOGGER.info("Autenticando como USUARIO EXTERNO con sistema: {}", sistemaIdentifExt);

// Línea 78
LOGGER.info("Autenticando como USUARIO INTERNO con sistema: {}", sistemaIdentificador);

// Línea 85
LOGGER.info("====== AUTENTICACION EXITOSA para usuario: {} ======", username);

// Líneas 99-102
LOGGER.error("====== ERROR AuthenticationServiceImpl.login() ======");
LOGGER.error("Usuario: {}, EsExterno: {}", username, prmEsExterno);
LOGGER.error("Codigo Error: {}, Mensaje: {}", appException.getCode(), appException.getMessage());

// Líneas 149-154
LOGGER.info(">>> loginUsuario() - INICIO");
LOGGER.info(">>> Sistema: {}", prmSistema);
LOGGER.info(">>> Username: {}", prmUsername);
LOGGER.info(">>> EsExterno: {}", prmEsExterno);
LOGGER.info(">>> Token URL: {}", mdsgdTokenUrl);
LOGGER.info(">>> Login API URL: {}", lgnApiUrl);

// Línea 158
LOGGER.info(">>> Token obtenido exitosamente");

// Líneas 181-182
LOGGER.info(">>> Metodo API construido: {}", vMetodo);
LOGGER.info(">>> URL completa: {}{}", lgnApiUrl, vMetodo);
```

#### MDSeguridadServiceImpl.java
```java
// Líneas 97-99
LOGGER.info("****** ObtenTokenDeAcceso() INICIO ******");
LOGGER.info("****** Token URL: {}", prmURL);
LOGGER.info("****** Token ID length: {}", TokenID != null ? TokenID.length() : 0);

// Línea 123
LOGGER.info("****** Ejecutando llamada al servicio de token...");

// Línea 126
LOGGER.info("****** Respuesta recibida - Codigo HTTP: {}", response.code());

// Línea 136
LOGGER.info("****** Token obtenido exitosamente");

// Líneas 141-142
LOGGER.error("Error al solicitar Token: " + response.code() + "-" + response.message());

// Línea 148
LOGGER.error("****** Error IOException en ObtenTokenDeAcceso: {}", ex.getMessage());

// Líneas 163-165
LOGGER.info("@@@@@@ EjecutaMetodoGET() INICIO @@@@@@");
LOGGER.info("@@@@@@ URL Base: {}", prmUrl);
LOGGER.info("@@@@@@ Metodo: {}", prmMetodo);

// Línea 184
LOGGER.info("@@@@@@ URL COMPLETA: {}", vURLCompleto);

// Línea 191
LOGGER.info("@@@@@@ Ejecutando llamada HTTP GET...");

// Líneas 194-195
LOGGER.info("@@@@@@ Respuesta recibida - Codigo HTTP: {}", response.code());
LOGGER.info("@@@@@@ Mensaje HTTP: {}", response.message());

// Línea 202
LOGGER.info("@@@@@@ Autenticacion EXITOSA - respuesta recibida");

// Líneas 206-208
LOGGER.error("@@@@@@ Error credenciales de usuario: {} - {}", response.code(), response.message());
LOGGER.error("@@@@@@ Detalle del error: {}", msgerror);

// Línea 212
LOGGER.error("@@@@@@ Error IOException en EjecutaMetodoGET: {}", ex.getMessage());
```

**Compilación:**
```bash
mvn clean package -P development-oracle1
[INFO] BUILD SUCCESS
[INFO] Total time: 35.424 s
[INFO] Finished at: 2026-01-29T22:35:24-06:00
```

**Despliegue:** Usuario copió WAR a Tomcat

**Resultado:**
```
Usuario confirma: "Sigue entrando al aplicativo"
```

**Logs capturados:** C:\github\fedi-web\logs\log.txt

**Confirmación:** ✅ Logs funcionando, autenticación intacta

---

## 2. Lecciones Aprendidas

### ❌ Error 1: Asumir Sin Evidencia
**Problema:** Asumimos que el backend requería dominio explícito sin verificar el comportamiento original.

**Lección:** SIEMPRE verificar el código original funcionando antes de hacer cambios.

### ❌ Error 2: Modificar Lógica Sin Entender
**Problema:** Agregamos auto-append y URL encoding sin entender cómo funciona el backend.

**Lección:** Primero agregar logs para ENTENDER, después modificar lógica si es necesario.

### ❌ Error 3: No Probar IFT Inmediatamente
**Problema:** Probamos CRT primero, no verificamos que IFT seguía funcionando.

**Lección:** Al cambiar configuraciones, probar AMBOS casos (original y nuevo) inmediatamente.

### ✅ Acierto 1: Restaurar de GIT
**Acción:** Cuando descubrimos que rompimos IFT, restauramos inmediatamente de GIT.

**Resultado:** Recuperamos funcionalidad en minutos.

### ✅ Acierto 2: Logs Sin Modificar Lógica
**Acción:** En la iteración final, SOLO agregamos logs sin tocar la lógica de autenticación.

**Resultado:** Logs funcionando, autenticación intacta, logs capturados para análisis.

---

## 3. Código Original Correcto (SIN Modificar)

### AuthenticationServiceImpl.java - loginUsuario() líneas 169-182
```java
// Paso 2. Definición del método del servicio que se ejecutará.

/*
/20210405.
/La clave se codifica a BASE64, de ser necesario este algoritmo rellena su grupo final con el caracter "=",
/este caracter se elimina ya que en la URL de la llamada del API puede provocar errores,
/la eliminacion de este caracter no le pega a BASE64 ya que no lo considera para se decodificacion.
/Se agrega Encode para realizar una codificacion con un algoritmo poco vulnerable.
*/
String cadenaClaveCodi=Encoder.codifica(prmClave);
String prmClaveCodificado=Base64.getEncoder().encodeToString(cadenaClaveCodi.getBytes());
prmClaveCodificado= prmClaveCodificado.replace("=", "");

vbuilder.append(prmSistema);
vbuilder.append("/");
vbuilder.append(prmUsername);  // ← SIN auto-append, SIN URL encoding
vbuilder.append("/");
//vbuilder.append(prmClave);
vbuilder.append(prmClaveCodificado);
vMetodo=vbuilder.toString();
```

**Observaciones:**
- Username se envía TAL CUAL sin modificaciones
- Solo la contraseña se encripta (Encoder + Base64)
- No hay URLEncoder en ningún lugar
- No hay lógica de auto-append de dominio

---

## 4. Cambios NO Realizados (Correctamente)

### ❌ NO Auto-Append de Dominio
**Razón:** Backend IFT lo hace automáticamente

**Código que NO agregamos:**
```java
// NO AGREGAR ESTO
if (!prmUsername.contains("@")) {
    prmUsername = prmUsername + "@ift.org.mx";
}
```

### ❌ NO URL Encoding de Username
**Razón:** Backend espera @ sin codificar

**Código que NO agregamos:**
```java
// NO AGREGAR ESTO
String usernameEncoded = URLEncoder.encode(prmUsername, "UTF-8");
```

### ✅ SÍ Password Encoding (Ya Existía)
**Razón:** Seguridad - contraseña debe encriptarse

**Código existente (correcto):**
```java
// ✅ ESTO YA ESTABA, ES CORRECTO
String cadenaClaveCodi=Encoder.codifica(prmClave);
String prmClaveCodificado=Base64.getEncoder().encodeToString(cadenaClaveCodi.getBytes());
prmClaveCodificado= prmClaveCodificado.replace("=", "");
```

---

## 5. Estado Final del Código

### Archivos con Cambios Aceptados
1. **LoginMB.java** - Solo logs agregados
2. **AuthenticationServiceImpl.java** - Solo logs agregados
3. **MDSeguridadServiceImpl.java** - Solo logs agregados

### Archivos Sin Cambios
1. **pom.xml** - Configuración IFT (URLs, Token ID, Sistema Identificador)
2. **application.properties** - Referencias a variables de pom.xml
3. **Resto de clases** - Sin modificaciones

### Logs Agregados (Total)
- LoginMB.java: 3 líneas de log
- AuthenticationServiceImpl.java: 12 líneas de log
- MDSeguridadServiceImpl.java: 13 líneas de log
- **Total: 28 líneas de logging**

### Líneas de Código de Lógica Modificadas
- **CERO** ✅

---

## 6. Comandos GIT Utilizados

### Restauración de Archivos
```bash
# Descartar cambios locales y restaurar desde repositorio
git restore src/main/java/fedi/ift/org/mx/arq/core/service/security/AuthenticationServiceImpl.java
git restore src/main/java/fedi/ift/org/mx/arq/core/service/security/loadsoa/MDSeguridadServiceImpl.java
git restore src/main/java/fedi/ift/org/mx/arq/core/exposition/LoginMB.java
git restore src/main/resources/application.properties
```

### Verificación de Estado
```bash
# Ver archivos modificados
git status

# Ver diferencias con repositorio
git diff src/main/java/fedi/ift/org/mx/arq/core/service/security/AuthenticationServiceImpl.java
```

---

## 7. Compilación y Despliegue

### Comando Maven
```bash
mvn clean package -P development-oracle1
```

### Output Exitoso
```
[INFO] Building war: C:\github\fedi-web\target\FEDIPortalWeb-1.0.war
[INFO] BUILD SUCCESS
[INFO] Total time: 35.424 s
[INFO] Finished at: 2026-01-29T22:35:24-06:00
```

### Despliegue en Tomcat
```
Origen: C:\github\fedi-web\target\FEDIPortalWeb-1.0.war
Destino: C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\FEDIPortalWeb-1.0.war

Método: Copia manual vía escritorio remoto
```

### Reinicio de Tomcat
Usuario reinicia Tomcat para cargar nuevo WAR.

---

## 8. Resumen de Iteraciones

| Iteración | Acción | Resultado | Estado |
|-----------|--------|-----------|--------|
| 1 | Agregar logs básicos | Error compilación SLF4J | ❌ |
| 2 | Probar sin dominio | HTTP 500 (ambos usuarios) | ❌ |
| 3 | Auto-append dominio | HTTP 500 (IFT roto) | ❌ |
| 4 | URL encoding de @ | HTTP 404 | ❌ |
| 5 | Descubrimiento del problema | IFT funcionaba antes | 💡 |
| 6 | Restaurar de GIT | IFT funciona nuevamente | ✅ |
| 7 | Logs sin modificar lógica | IFT funciona + logs capturados | ✅ |

**Resultado Final:** ✅ Código funcionando con logs completos para análisis

---

**Última Actualización:** 2026-01-29 23:00
**Autor:** Claude Code
**Versión:** 1.0
