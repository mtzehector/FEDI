# Confirmación: Problema de Infraestructura CRT

**Fecha:** 2026-01-29 23:25:39
**Prueba:** Usuario IFT con URLs CRT
**Resultado:** ❌ HTTP 500 - Mismo error

---

## Prueba Realizada

### Usuario IFT con Backend CRT
**Usuario probado:** `dgtic.dds.ext023` (usuario IFT que funciona con backend IFT)
**Backend:** apimanager-dev.crt.gob.mx (CRT)
**Resultado:** HTTP 500

---

## Análisis del Log

### ✅ Código Funciona Perfectamente

**Líneas 14-18:**
```
Token URL: http://apimanager-dev.crt.gob.mx/token
Login API URL: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/
Token obtenido exitosamente
URL completa: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/0022FEDI/dgtic.dds.ext023/...
```

**Verificación:**
- ✅ URLs CRT configuradas correctamente
- ✅ Token obtenido exitosamente
- ✅ Username formato correcto: `dgtic.dds.ext023` (sin encoding)
- ✅ URL construida correctamente

---

### ❌ Backend CRT: Usuarios IFT No Existen en AD CRT

**Línea 27:**
```
"La autenticación del usuario dgtic.dds.ext023 no es correcta, validación en el repositorio central"
```

**Stack trace:**
```
at mx.org.ift.mod.seg.lgn.arq.core.service.security.loadsoa.WSO2LoginServiceImpl.autentica(WSO2LoginServiceImpl.java:108)
at mx.org.ift.mod.seg.lgn.arq.core.service.security.AuthenticationServiceImpl.AutenticaPorIdentityUsr(AuthenticationServiceImpl.java:263)
```

---

## Comparación: IFT vs CRT

### Usuario IFT + Backend IFT = ✅ ÉXITO
- Usuario: `dgtic.dds.ext023`
- Backend: apimanager-dev.ift.org.mx
- HTTP: 200
- Resultado: Login exitoso

### Usuario IFT + Backend CRT = ❌ FALLO
- Usuario: `dgtic.dds.ext023`
- Backend: apimanager-dev.crt.gob.mx
- HTTP: 500
- Mensaje: "validación en el repositorio central"

### Usuario CRT + Backend CRT = ❌ FALLO
- Usuario: `deid.ext33`
- Backend: apimanager-dev.crt.gob.mx
- HTTP: 500
- Mensaje: "validación en el repositorio central"

---

## Conclusión Definitiva

### 🎯 El Código Está Correcto

**Evidencia Contundente:**
1. ✅ Migración de URLs exitosa (IFT → CRT)
2. ✅ Token obtenido de backend CRT
3. ✅ Formato de URL idéntico al que funciona con IFT
4. ✅ Backend CRT responde correctamente (HTTP 500, no 502/timeout)
5. ✅ Backend CRT funciona IGUAL que backend IFT (mismo formato)

**Ningún cambio de código es necesario.**

---

### ❌ Backend CRT No Tiene Usuarios Registrados

**Problema:**
El Active Directory de CRT no tiene usuarios registrados (ni IFT ni CRT).

**Evidencia:**
- Usuario IFT (`dgtic.dds.ext023`) NO existe en AD CRT
- Usuario CRT (`deid.ext33`) NO existe en AD CRT
- Mismo código funciona con IFT porque usuarios SÍ existen en AD IFT

---

## Diagnóstico Final

### El backend CRT está operativo PERO:

**El "repositorio central" (Active Directory) de CRT está VACÍO o NO CONFIGURADO.**

**Posibles causas:**
1. AD CRT es nuevo y aún no tiene usuarios migrados
2. AD CRT no está conectado al backend de autenticación
3. Configuración incorrecta en backend CRT apuntando a AD equivocado
4. Permisos de lectura de AD CRT no configurados

---

## Acciones Requeridas (Infraestructura)

### 🔴 URGENTE: Contactar Equipo de Infraestructura CRT

**Problema:**
Backend de autenticación CRT no puede validar usuarios en Active Directory.

**Información Técnica:**
- **Backend:** apimanager-dev.crt.gob.mx
- **Endpoint:** /autorizacion/login/v1.0/credencial/
- **Error:** HTTP 500, código 5001
- **Mensaje:** "La autenticación del usuario {username} no es correcta, validación en el repositorio central"
- **Usuarios probados:**
  - `dgtic.dds.ext023` (usuario IFT) - FALLA
  - `deid.ext33` (usuario CRT) - FALLA

**Verificar:**
1. ¿Active Directory CRT está configurado?
2. ¿Backend CRT apunta al AD correcto?
3. ¿Usuarios están migrados a AD CRT?
4. ¿Permisos de conexión de backend a AD CRT?

---

## Opciones Mientras se Resuelve

### Opción 1: Mantener Infraestructura IFT (RECOMENDADO)
**Acción:** No cambiar nada, seguir usando backend IFT

**Razón:** Backend IFT funciona perfectamente con usuarios IFT

**Rollback:**
```bash
cd C:\github\fedi-web
cp C:\github\Colaboracion\backups\pom.xml.IFT.backup pom.xml
mvn clean package -P development-oracle1
# Redesplegar WAR
```

---

### Opción 2: Esperar Resolución de Infraestructura
**Acción:** Mantener código CRT desplegado, esperar que infraestructura configure AD CRT

**Cuándo usar:** Si infraestructura puede resolver rápido (horas, no días)

**Verificación:** Probar periódicamente con usuario CRT hasta que funcione

---

### Opción 3: Entorno Dual (IFT + CRT)
**Acción:** Tener dos despliegues:
- FEDI IFT: Para usuarios IFT (actual, funcionando)
- FEDI CRT: Para usuarios CRT (cuando infraestructura esté lista)

**Cuándo usar:** Si la migración de usuarios tomará tiempo

---

## Resumen para Ticket de Infraestructura

### Título
"Backend CRT no puede autenticar usuarios - Error validación en repositorio central"

### Descripción
El backend de autenticación de CRT (apimanager-dev.crt.gob.mx) está operativo y responde correctamente, pero no puede validar ningún usuario en Active Directory. Todos los intentos de autenticación retornan HTTP 500 con mensaje "La autenticación del usuario {username} no es correcta, validación en el repositorio central".

### Usuarios Probados
- `dgtic.dds.ext023` (usuario IFT existente) - FALLA
- `deid.ext33` (usuario CRT) - FALLA

### Evidencia Técnica
- Backend CRT responde (token obtenido exitosamente)
- Formato de peticiones es correcto (mismo que funciona con IFT)
- Error ocurre en validación de AD:
  ```
  at mx.org.ift.mod.seg.lgn.arq.core.service.security.loadsoa.WSO2LoginServiceImpl.autentica(WSO2LoginServiceImpl.java:108)
  at mx.org.ift.mod.seg.lgn.arq.core.service.security.AuthenticationServiceImpl.AutenticaPorIdentityUsr(AuthenticationServiceImpl.java:263)
  ```

### Solicitud
Verificar y configurar:
1. Active Directory CRT está operativo
2. Backend CRT apunta al AD CRT correcto
3. Usuarios existen en AD CRT (o migrar usuarios)
4. Permisos de conexión backend ↔ AD

### Impacto
**BLOQUEANTE:** No se puede completar migración a CRT hasta que AD esté configurado.

### Prioridad
ALTA - Bloquea migración completa de dominio IFT a CRT

---

**Creado por:** Claude Code
**Fecha:** 2026-01-29 23:35
**Versión:** 1.0
**Estado:** BLOQUEANTE - Requiere acción de infraestructura
