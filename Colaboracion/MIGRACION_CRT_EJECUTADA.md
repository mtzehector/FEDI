# Migración a CRT - Ejecutada

**Fecha:** 2026-01-29 23:11
**Estado:** ✅ Compilación Exitosa - Listo para Desplegar

---

## Cambios Realizados

### 1. Backup de Configuración IFT
**Archivo:** `C:\github\Colaboracion\backups\pom.xml.IFT.backup`
**Estado:** ✅ Respaldado

### 2. Cambios en pom.xml (development-oracle1)

#### URLs Cambiadas de IFT a CRT:

| Propiedad | Antes (IFT) | Después (CRT) |
|-----------|-------------|---------------|
| `profile.mdsgd.token.url` | http://apimanager-dev.ift.org.mx/token | http://apimanager-dev.crt.gob.mx/token |
| `profile.lgn.api.url` | https://apimanager-dev.ift.org.mx/autorizacion/login/v1.0/credencial/ | https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/ |
| `profile.mdsgd.bit.url` | http://apimanager.ift.org.mx/bit.reg.ift.org.mx/registroBitacora/ | http://apimanager.crt.gob.mx/bit.reg.crt.gob.mx/registroBitacora/ |
| `profile.fedi.url` | https://apimanager-dev.ift.org.mx/FEDI/v1.0/ | https://apimanager-dev.crt.gob.mx/FEDI/v1.0/ |
| `profile.autoregistro.url` | https://apimanager-dev.ift.org.mx/srvAutoregistroQA/v1.0/ | https://apimanager-dev.crt.gob.mx/srvAutoregistroQA/v1.0/ |
| `profile.ldp.url` | https://apimanager-dev.ift.org.mx/ldp.inf.ift.org.mx/v1.0/ | https://apimanager-dev.crt.gob.mx/ldp.inf.crt.gob.mx/v1.0/ |
| `profile.fedi.notificaciones.url` | https://apimanager-dev.ift.org.mx/REGISTRO/CORREOS/FEDI/v1.0/firmaUsuarios/ | https://apimanager-dev.crt.gob.mx/REGISTRO/CORREOS/FEDI/v1.0/firmaUsuarios/ |

#### Valores SIN CAMBIOS (Correctos):
- `profile.mdsgd.token.id`: Basic VGZxc3BCYWVYZHhCNlF0SUJHV0EzZUxpMkw0YTpWTUdUVHhqUDVkMl91eFoxdW5uSVBSTGpmZ01h
- `profile.sistema.identificador`: 0022FEDI
- `profile.sistema.identif.ext`: 0022FEDI

---

## Compilación

### Comando Ejecutado:
```bash
mvn clean package -P development-oracle1
```

### Resultado:
```
[INFO] BUILD SUCCESS
[INFO] Total time:  42.559 s
[INFO] Finished at: 2026-01-29T23:11:03-06:00
[INFO] Building war: C:\github\fedi-web\target\FEDIPortalWeb-1.0.war
```

**WAR Generado:**
- Ruta: `C:\github\fedi-web\target\FEDIPortalWeb-1.0.war`
- Tamaño: ~90 MB (estimado)
- Estado: ✅ Listo para despliegue

---

## Próximos Pasos (Usuario)

### 1. Desplegar WAR en Tomcat
```
Origen: C:\github\fedi-web\target\FEDIPortalWeb-1.0.war
Destino: C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\FEDIPortalWeb-1.0.war
```

### 2. Reiniciar Tomcat
- Detener servicio
- Copiar WAR
- Iniciar servicio

### 3. Probar Usuario CRT
**URL:** https://fedidev.crt.gob.mx/FEDIPortalWeb-1.0/content/common/Login.jsf

**Credenciales:**
- Usuario: `deid.ext33` (sin @crt.gob.mx)
- Contraseña: (contraseña del usuario)
- Externo: (marcar si aplica)

### 4. Capturar Logs
**Ruta:** `C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\logs\fedi.log`

**Guardar en:** `C:\github\fedi-web\logs\log.txt`

---

## Qué Buscar en los Logs

### Escenario A: Éxito (HTTP 200) ✅
```
>>> Token URL: http://apimanager-dev.crt.gob.mx/token
****** Respuesta recibida - Codigo HTTP: 200
****** Token obtenido exitosamente
>>> URL completa: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/0022FEDI/deid.ext33/...
@@@@@@ Respuesta recibida - Codigo HTTP: 200
@@@@@@ Autenticacion EXITOSA - respuesta recibida
====== AUTENTICACION EXITOSA para usuario: deid.ext33 ======
=== LOGIN EXITOSO === Usuario: deid.ext33
```

**Diagnóstico:** ✅ CRT funciona igual que IFT - Migración exitosa

---

### Escenario B: HTTP 404 ⚠️
```
>>> URL completa: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/0022FEDI/deid.ext33/...
@@@@@@ Respuesta recibida - Codigo HTTP: 404
@@@@@@ Detalle del error: {"code":"404","message":"No matching resource found for given API Request"}
```

**Diagnóstico:** Backend CRT requiere dominio explícito (@crt.gob.mx)

**Acción:** Activar Plan B - Agregar lógica condicional en código

---

### Escenario C: HTTP 500 ❌
```
>>> URL completa: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/0022FEDI/deid.ext33/...
@@@@@@ Respuesta recibida - Codigo HTTP: 500
@@@@@@ Detalle del error: {"code":"500","message":"La autenticación del usuario deid.ext33 no es correcta, validación en el repositorio central"}
```

**Diagnóstico:** Usuario no existe en Active Directory CRT

**Acción:** Contactar infraestructura para verificar registro

---

### Escenario D: HTTP 502 o Timeout ❌
```
>>> URL completa: https://apimanager-dev.crt.gob.mx/autorizacion/login/v1.0/credencial/0022FEDI/deid.ext33/...
@@@@@@ Error IOException en EjecutaMetodoGET: timeout
```

**Diagnóstico:** Backend CRT no disponible o problema de conectividad

**Acción:** Verificar disponibilidad del servicio con infraestructura

---

## Rollback (Si es Necesario)

### Opción 1: Restaurar pom.xml
```bash
cd C:\github\fedi-web
cp C:\github\Colaboracion\backups\pom.xml.IFT.backup pom.xml
mvn clean package -P development-oracle1
```

### Opción 2: Usar Backup de WAR IFT
```
Origen: (WAR anterior de IFT si lo guardaste)
Destino: C:\Program Files\Apache Software Foundation\Tomcat 9.0_FEDIDEV\webapps\FEDIPortalWeb-1.0.war
```

---

**Creado por:** Claude Code
**Timestamp:** 2026-01-29T23:11:03-06:00
