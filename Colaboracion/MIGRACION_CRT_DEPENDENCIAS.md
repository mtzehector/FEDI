# Migración FEDI a CRT - Dependencias de Sistemas

## Resumen Ejecutivo

Durante las pruebas de migración del aplicativo **FEDI** (Firma Electrónica de Documentos) del dominio IFT a CRT, se identificó que **FEDI tiene una dependencia funcional crítica con el sistema PERITOS** (`0015MSPERITOSDES-INT`).

## Problema Identificado

### Error en QA-CRT
Al hacer clic en la sección "Cargar documento y asignar firma" con las URLs configuradas para CRT, el sistema muestra:

```
Error al obtener el detalle del usuario, AdminRolMB.obtenerDetalleUsuario:
AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario(): Failed : HTTP error code : 401
```

### Causa Raíz
El aplicativo **FEDI** consulta el catálogo de usuarios firmantes desde el sistema **PERITOS** a través de los siguientes endpoints:

1. **Consulta de roles de PERITOS:**
   ```
   GET https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT
   ```

2. **Consulta de usuarios por rol:**
   ```
   GET https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/4/{sistema}--{rol}/0022FEDI
   ```

3. **Consulta de información LDAP:**
   ```
   POST https://apimanager-qa.crt.gob.mx/ldp.inf.ift.org.mx/v3.0/OBTENER_INFO
   ```

## Validación Realizada

### Prueba con IFT (FUNCIONA ✅)
- **Configuración:** URLs apuntando a `apimanager-qa.ift.org.mx`
- **Resultado:** Login exitoso y carga de firmantes correcta
- **Conclusión:** El sistema PERITOS está disponible y configurado en el API Manager de IFT

### Prueba con CRT (FALLA ❌)
- **Configuración:** URLs apuntando a `apimanager-qa.crt.gob.mx`
- **Resultado:** Login exitoso pero error 401 al consultar PERITOS
- **Conclusión:** El sistema PERITOS NO está registrado en el API Manager de CRT

## Arquitectura de Dependencias

```
┌─────────────────────┐
│   FEDI (0022FEDI)   │
│  (Login de FEDI)    │
└──────────┬──────────┘
           │
           │ Consulta catálogo de firmantes
           ▼
┌─────────────────────────────┐
│ PERITOS (0015MSPERITOSDES-INT) │
│  (Roles y usuarios)         │
└──────────┬──────────────────┘
           │
           │ Consulta información de usuario
           ▼
┌─────────────────────┐
│ LDP (LDAP Services) │
│ ldp.inf.?.gob.mx    │
└─────────────────────┘
```

## Ubicación del Código

**Archivo:** `src/main/java/fedi/ift/org/mx/arq/core/service/security/AdminUsuariosServiceImpl.java`

### Métodos que consultan PERITOS:
- **Línea 112-117:** `obtenerUsuarios()` - Consulta roles de PERITOS
- **Línea 140-147:** `obtenerUsuarios()` - Consulta usuarios por rol
- **Línea 239-248:** `obtenerUsuarioInterno()` - Busca usuario en PERITOS
- **Línea 314-322:** `obtenerinformacionDetalleUsuario()` - Consulta info LDAP

### Logs Agregados
Se agregaron logs informativos para facilitar el diagnóstico:
```java
LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarios() - Consultando roles de PERITOS: " + this.autoRegistroUrl + vMetodo);
LOGGER.info("AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario() - Consultando info LDAP para usuario: " + prmHeaderBodyLDAP.getUser() + " en: " + this.ldpUrl + vMetodo);
```

## Acciones Requeridas para Infraestructura/API Manager

### 1. Registrar sistema PERITOS en API Manager CRT
- **Identificador:** `0015MSPERITOSDES-INT`
- **APIs requeridas:**
  - Servicio de autoregistro/consultas de roles
  - Debe permitir consultas desde FEDI (`0022FEDI`)

### 2. Configurar servicio LDAP en CRT
- **URL actual (IFT):** `https://apimanager-qa.ift.org.mx/ldp.inf.ift.org.mx/v3.0/`
- **URL esperada (CRT):** `https://apimanager-qa.crt.gob.mx/ldp.inf.crt.gob.mx/v3.0/`
  - O confirmar cuál es el path correcto en CRT
- **Endpoint:** `OBTENER_INFO` (método POST)

### 3. Actualizar servicio de bitácora
- **URL actual:** `https://apimanager-qa.crt.gob.mx/bit.reg.ift.org.mx/registroBitacora/`
- **URL esperada:** `https://apimanager-qa.crt.gob.mx/bit.reg.crt.gob.mx/registroBitacora/`

### 4. Validar token y permisos
- El token generado para FEDI (`0022FEDI`) debe tener permisos para:
  - Consultar roles del sistema PERITOS
  - Consultar usuarios del sistema PERITOS
  - Acceder al servicio LDAP

## Configuración del pom.xml (Perfil QA)

### Actual (líneas 799-810):
```xml
<profile.mdsgd.token.url>http://apimanager-qa.crt.gob.mx:8280/token</profile.mdsgd.token.url>
<profile.mdsgd.token.id>Basic V3FsMVBMdmpvZTh6U0RfNHFTRWIyNEhTOWZBYTpFeExrVEFsOEY0eEkxZ1BjaHh5Rk5TblFYQlFh</profile.mdsgd.token.id>
<profile.lgn.api.url>https://apimanager-qa.crt.gob.mx/autorizacion/login/v3.0/credencial/</profile.lgn.api.url>
<profile.autoregistro.url>https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/</profile.autoregistro.url>
<profile.ldp.url>https://apimanager-qa.crt.gob.mx/ldp.inf.ift.org.mx/v3.0/</profile.ldp.url>
<profile.sistema.identificador>0022FEDI</profile.sistema.identificador>
```

### Pendiente de confirmar:
- ¿El path `ldp.inf.ift.org.mx` es correcto o debe ser `ldp.inf.crt.gob.mx`?
- ¿El sistema PERITOS existe en CRT o debe migrarse desde IFT?

## Plan de Pruebas

1. **Validar disponibilidad de PERITOS en CRT**
   - Intentar consulta directa al endpoint de roles PERITOS
   - Verificar response code

2. **Verificar servicio LDAP**
   - Probar endpoint `OBTENER_INFO` con token de FEDI
   - Validar que devuelve información de usuarios

3. **Prueba end-to-end**
   - Login en FEDI
   - Navegación a "Cargar documento y asignar firma"
   - Verificar que carga lista de firmantes sin errores

## Contacto para Dudas Técnicas

- Revisar logs del servidor en: `BitacoraFEDIPortalWeb`
- Buscar líneas que contengan: `AdminUsuariosServiceImpl.obtenerUsuarios()`
- Los logs ahora incluyen las URLs completas consultadas

## Última Actualización
Fecha: 2026-01-30
Rama: QA
Versión: QA:20260214-1
