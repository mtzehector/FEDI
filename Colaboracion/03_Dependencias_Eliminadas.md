# Dependencias Eliminadas - Análisis Detallado

## 📋 Resumen de Dependencias

Este documento detalla qué métodos del FEDI dependían de los sistemas PERITOS y autoregistro, y cómo fueron eliminadas estas dependencias.

---

## ❌ DEPENDENCIA 1: Sistema PERITOS (0015MSPERITOSDES-INT)

### Propósito Original
El sistema PERITOS proporcionaba el catálogo de usuarios y roles disponibles para el FEDI. Era una dependencia crítica para:
- Obtener la lista de usuarios que pueden ser firmantes
- Validar que un usuario existe en el sistema
- Consultar qué roles tiene un usuario

### Métodos Afectados

#### 1. `AdminUsuariosServiceImpl.obtenerUsuarios()`
**Ubicación**: `fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/AdminUsuariosServiceImpl.java:89-203`

**Qué hacía**:
```java
// Consultaba roles del sistema PERITOS
vMetodo = "registro/consultas/roles/2/1/0015MSPERITOSDES-INT";
LOGGER.info("Consultando roles de PERITOS: " + this.autoRegistroUrl + vMetodo);
vCadenaResultado = this.mDSeguridadService.EjecutaMetodoGET(
    this.tokenAcceso.getAccess_token(),
    this.autoRegistroUrl,
    vMetodo,
    lstParametros
);

// Procesaba respuesta JSON con lista de roles
responseRoles = gson.fromJson(vCadenaResultado, ResponseRoles.class);

// Por cada rol, consultaba usuarios
vMetodo = "registro/consultas/roles/4/"+nombreSistema+"--"+nombreRol+"/"+this.sistemaIdentificadorInt;
vCadenaResultado = this.mDSeguridadService.EjecutaMetodoGET(...);
```

**Endpoint usado**:
```
GET {autoRegistroUrl}/registro/consultas/roles/2/1/0015MSPERITOSDES-INT
GET {autoRegistroUrl}/registro/consultas/roles/4/{sistema}--{rol}/{sistemaFEDI}
```

**Comentario crítico en el código** (líneas 112-113):
```java
//IMPORTANTE: FEDI depende del sistema PERITOS (0015MSPERITOSDES-INT) para obtener el catálogo de usuarios firmantes
//Si este endpoint falla con 401, significa que el sistema PERITOS no está registrado en el API Manager
```

**Usado por**:
- `AdminRolMB.iniciarObjetos()` - línea 186 (comentado pero presente)
- Interfaz de administración de usuarios

**Cómo se eliminó**:
- ✅ Creada tabla `cat_Roles` en BD local
- ✅ Creada tabla `tbl_UsuarioRol` en BD local
- ⏳ Pendiente: Modificar método para consultar BD local en lugar de PERITOS

---

#### 2. `AdminUsuariosServiceImpl.obtenerUsuarioInterno(String prmUsuario)`
**Ubicación**: `AdminUsuariosServiceImpl.java:229-287`

**Qué hacía**:
```java
// Validaba si un usuario específico existe en PERITOS
vMetodo = "registro/consultas/roles/1/"+prmUsuario+"/"+"0015MSPERITOSDES-INT";
LOGGER.info("Consultando usuario: " + prmUsuario + " en sistema PERITOS");
vCadenaResultado = this.mDSeguridadService.EjecutaMetodoGET(
    this.tokenAcceso.getAccess_token(),
    this.autoRegistroUrl,
    vMetodo,
    lstParametros
);
```

**Endpoint usado**:
```
GET {autoRegistroUrl}/registro/consultas/roles/1/{usuarioID}/0015MSPERITOSDES-INT
```

**Usado por**:
- `AdminRolMB.buscaUsuarioInterno()` - línea 329

**Cómo se eliminó**:
- ✅ Tabla `tbl_UsuarioRol` permite verificar si usuario existe localmente
- ⏳ Pendiente: Modificar método para consultar BD local

---

### Configuración en `application.properties`

**Propiedad relacionada** (línea 126):
```properties
peritos.almacen.principal=${profile.peritos.almacen.principal:0015MSPERITOS-EXT}
```

**Archivo**: `security-roles.properties` (línea 21):
```properties
peritos.almacen.principal=0015MSPERITOSDES-INT
```

**Acción requerida**:
- ⏳ Comentar o eliminar estas propiedades después de migrar el código

---

## ❌ DEPENDENCIA 2: Servicio autoregistro

### Propósito Original
El servicio autoregistro manejaba:
- Registro de nuevos usuarios en el sistema
- Activación de cuentas mediante token de correo
- Modificación de permisos y roles de usuarios

### Métodos Afectados

#### 1. `AutoregistroServiceImpl.registro(String xUsuario, String xPassword, String xCorreo)`
**Ubicación**: `AutoregistroServiceImpl.java:61-119`

**Qué hacía**:
```java
// Llamada directa al servicio autoregistro en localhost
URL obj = new URL("http://localhost:7001/srvAutoregistro/registro/validarUsuario");
HttpURLConnection postConnection = (HttpURLConnection) obj.openConnection();
postConnection.setRequestMethod("POST");
postConnection.setRequestProperty("weblogic", "iftw2019");
postConnection.setRequestProperty("Content-Type", "application/json");

String POST_PARAMS = "{\n" +
    "    \"user\":\"" + xUsuario + "\",\r\n" +
    "    \"pass\":\"" + xPassword + "\",\r\n" +
    "    \"correo\":\"" + xCorreo + "\"" +
    "\n}";

// Envía POST y procesa respuesta
os.write(POST_PARAMS.getBytes());
BufferedReader in = new BufferedReader(new InputStreamReader(postConnection.getInputStream()));
```

**Endpoint usado**:
```
POST http://localhost:7001/srvAutoregistro/registro/validarUsuario
Headers: weblogic: iftw2019
Body: {"user": "...", "pass": "...", "correo": "..."}
```

**Usado por**:
- `RegistroMB.log()` - línea 88

**Problemas**:
- ❌ URL hardcodeada a localhost:7001
- ❌ Servicio debe estar corriendo localmente
- ❌ No hay validación de disponibilidad

**Cómo se eliminó**:
- ✅ Tabla `tbl_UsuarioRol` permite registrar usuarios localmente
- ⏳ Pendiente: Modificar método para insertar en BD local
- ⏳ Pendiente: Validar usuario contra LDAP primero

---

#### 2. `AutoregistroServiceImpl.activaUsuario(String xScim)`
**Ubicación**: `AutoregistroServiceImpl.java:121-145`

**Qué hacía**:
```java
// Activaba usuario mediante token SCIM
String vMetodo = "registro/activarUsuario/" + xScim;
respuestaServicioPost = mDSeguridadService.EjecutaMetodoPOST(
    this.tokenAcceso.getAccess_token(),
    this.autoRegistroUrl + vMetodo,
    "",
    lstParametros,
    null
);
```

**Endpoint usado**:
```
POST {autoRegistroUrl}/registro/activarUsuario/{scimToken}
```

**Usado por**:
- `ActivaUsuarioMB.activar()` - línea 58

**Cómo se eliminó**:
- ✅ Campo `Activo` en tabla `tbl_UsuarioRol` controla estado
- ⏳ Pendiente: Modificar método para actualizar BD local

---

#### 3. `AutoregistroServiceImpl.creaUsuario(crearUsuario newUser)`
**Ubicación**: `AutoregistroServiceImpl.java:153-176`

**Qué hacía**:
```java
// Creaba usuario con datos completos
String vMetodo = "registro/validarUsuario";
respuestaServicioPost = mDSeguridadService.EjecutaMetodoPOST(
    this.tokenAcceso.getAccess_token(),
    this.autoRegistroUrl + vMetodo,
    "",
    lstParametros,
    newUser  // Objeto con datos del formulario
);
```

**Endpoint usado**:
```
POST {autoRegistroUrl}/registro/validarUsuario
Body: objeto crearUsuario (JSON)
```

**Usado por**:
- `RegistroMB.updateUsuario()` - línea 114

**Cómo se eliminó**:
- ✅ Tabla `tbl_UsuarioRol` permite crear usuarios localmente
- ⏳ Pendiente: Modificar método para insertar en BD local

---

#### 4. `AdminUsuariosServiceImpl.modificarPermisosAUsuario(CambioUsuarioRequest prmCambioUsuarioRequest)`
**Ubicación**: `AdminUsuariosServiceImpl.java:290-307`

**Qué hacía**:
```java
// Modificaba permisos de usuario (agregar/eliminar roles)
String vMetodo = "registro/actualizar";
respuestaServicioPost = mDSeguridadService.EjecutaMetodoPOST(
    this.tokenAcceso.getAccess_token(),
    this.autoRegistroUrl + vMetodo,
    "",
    lstParametros,
    prmCambioUsuarioRequest
);
```

**Endpoint usado**:
```
POST {autoRegistroUrl}/registro/actualizar
Body: CambioUsuarioRequest con roles a agregar/eliminar
```

**Usado por**:
- `AdminRolMB.actualizarRolesUsuario()` - línea 404
- `AdminRolMB.eliminaRolesUsuario()` - línea 488

**Cómo se eliminó**:
- ✅ Tabla `tbl_UsuarioRol` permite modificar roles con INSERT/UPDATE
- ⏳ Pendiente: Modificar método para actualizar BD local

---

### Configuración en `application.properties`

**Propiedad relacionada** (línea 102):
```properties
autoregistro.url=${profile.autoregistro.url}
```

**Acción requerida**:
- ⏳ Comentar o eliminar esta propiedad después de migrar el código

---

## ✅ DEPENDENCIA CONSERVADA: LDAP

### Propósito
LDAP es la **fuente de verdad** para:
- Autenticación de usuarios (login)
- Información detallada de usuarios (nombre, correo, puesto, activo/inactivo)
- Búsqueda de usuarios por nombre

### Métodos que DEBEN seguir usando LDAP

#### 1. `AdminUsuariosServiceImpl.obtenerinformacionDetalleUsuario(HeaderBodyLDAP prmHeaderBodyLDAP)`
**Ubicación**: `AdminUsuariosServiceImpl.java:310-343`

**Qué hace**:
```java
// Obtiene información completa de un usuario desde LDAP
String vMetodo = "OBTENER_INFO";
LOGGER.info("Consultando info LDAP para usuario: " + prmHeaderBodyLDAP.getUser());
respuestaServicioPost = mDSeguridadService.EjecutaMetodoPOST(
    this.tokenAcceso.getAccess_token(),
    this.ldpUrl + vMetodo,
    "",
    lstParametros,
    prmHeaderBodyLDAP
);
```

**Endpoint usado**:
```
POST {ldpUrl}/OBTENER_INFO
Body: {"user": "usuario@ift.org.mx"}
```

**Usado por**:
- `AdminRolMB.obtenerDetalleUsuario()` - línea 534

**Estado**: ✅ **CONSERVAR** - LDAP es la fuente de verdad para datos de usuarios

---

#### 2. `AdminUsuariosServiceImpl.obtenerListaBusqueda(HeaderBodyLDAP prmHeaderBodyLDAP)`
**Ubicación**: `AdminUsuariosServiceImpl.java:346-371`

**Qué hace**:
```java
// Busca usuarios por nombre en LDAP
String vMetodo = "Obtener_Por_Nombre_usuarioID/" + prmHeaderBodyLDAP.getUser();
respuestaServicioPost = mDSeguridadService.EjecutaMetodoGET(
    this.tokenAcceso.getAccess_token(),
    this.ldpUrl,
    vMetodo,
    lstParametros
);
```

**Endpoint usado**:
```
GET {ldpUrl}/Obtener_Por_Nombre_usuarioID/{busqueda}
```

**Usado por**:
- `AdminRolMB.buscarUsuarios()` - línea 607

**Estado**: ✅ **CONSERVAR** - LDAP es la fuente de verdad para búsqueda de usuarios

---

### Configuración en `application.properties`

**Propiedad relacionada** (línea 106):
```properties
ldp.url=${profile.ldp.url}
```

**Acción requerida**:
- ✅ **MANTENER** - Esta configuración debe permanecer

---

## 📊 Resumen Comparativo

### ANTES de la migración

```
┌─────────────────────────────────────────────────────────────┐
│                        FEDI                                  │
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │  AdminUsuariosServiceImpl                      │         │
│  └────────────────────────────────────────────────┘         │
│       │                    │                  │              │
│       ↓                    ↓                  ↓              │
│  ┌─────────┐         ┌──────────┐      ┌──────────┐        │
│  │ PERITOS │         │autoregis.│      │   LDAP   │        │
│  │  (API)  │         │  (local) │      │  (Info)  │        │
│  └─────────┘         └──────────┘      └──────────┘        │
│       │                    │                  │              │
│  - Roles             - Registro        - Nombre             │
│  - Usuarios          - Activación      - Email              │
│  - Permisos          - Modificación    - Búsqueda           │
└─────────────────────────────────────────────────────────────┘

DEPENDENCIAS: 3 (PERITOS, autoregistro, LDAP)
PUNTOS DE FALLA: 3
```

### DESPUÉS de la migración

```
┌─────────────────────────────────────────────────────────────┐
│                        FEDI                                  │
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │  AdminUsuariosServiceImpl (MODIFICADO)         │         │
│  └────────────────────────────────────────────────┘         │
│       │                                   │                  │
│       ↓                                   ↓                  │
│  ┌──────────────┐                  ┌──────────┐            │
│  │  BD FEDI     │                  │   LDAP   │            │
│  │  (Local)     │                  │  (Info)  │            │
│  └──────────────┘                  └──────────┘            │
│       │                                   │                  │
│  - cat_Roles                       - Nombre                 │
│  - tbl_UsuarioRol                  - Email                  │
│  - Transacciones locales           - Búsqueda               │
│  - Alta disponibilidad             - Autenticación          │
└─────────────────────────────────────────────────────────────┘

DEPENDENCIAS: 1 (LDAP)
PUNTOS DE FALLA: 1
```

---

## 🔄 Plan de Migración del Código

### Paso 1: Crear Repositorios MyBatis ⏳
```
Archivo: fedi-web/src/main/java/fedi/ift/org/mx/persistence/mapper/UsuarioRolRepository.java

public interface UsuarioRolRepository {
    List<AdmRol> obtenerTodosLosRoles();
    List<AdmUsuario> obtenerUsuariosPorRol(String rolID);
    AdmUsuario obtenerUsuarioPorID(String usuarioID);
    void insertarUsuario(AdmUsuario usuario);
    void asignarRol(String usuarioID, String rolID);
    void eliminarRol(String usuarioID, String rolID);
}
```

### Paso 2: Modificar AdminUsuariosServiceImpl ⏳
```java
@Override
public ResponseUsuarios obtenerUsuarios() throws Exception {
    ResponseUsuarios responseUsuarios = new ResponseUsuarios();

    try {
        // YA NO consulta PERITOS, consulta BD local
        List<AdmUsuario> usuarios = usuarioRolRepository.obtenerTodosLosUsuarios();
        List<AdmRol> roles = usuarioRolRepository.obtenerTodosLosRoles();

        responseUsuarios.setAdmUsuarios(usuarios);
        responseUsuarios.setRolesApp(roles);
        responseUsuarios.setCode(0);
        responseUsuarios.setError("false");

    } catch (Exception e) {
        throw new Exception("Error al obtener usuarios locales: " + e.getMessage());
    }

    return responseUsuarios;
}
```

### Paso 3: Modificar AutoregistroServiceImpl ⏳
```java
@Override
public Message registrarUsuario(String usuario, String password, String correo) {
    Message mensaje = new Message();

    try {
        // 1. Validar que el usuario existe en LDAP (CONSERVAR)
        HeaderBodyLDAP ldapRequest = new HeaderBodyLDAP();
        ldapRequest.setUser(usuario);
        LDAPInfoResponse ldapInfo = adminUsuariosService.obtenerinformacionDetalleUsuario(ldapRequest);

        if (!ldapInfo.getResult().getMessage().equals("Success")) {
            mensaje.setMensaje("Usuario no encontrado en LDAP");
            return mensaje;
        }

        // 2. Crear usuario en BD local (NUEVO)
        usuarioRolRepository.insertarUsuario(usuario);
        usuarioRolRepository.asignarRol(usuario, "ROL_0022FEDI_USER");

        mensaje.setMensaje("Usuario registrado exitosamente");
        mensaje.setCodigo("0");

    } catch (Exception e) {
        mensaje.setMensaje("Error al registrar usuario: " + e.getMessage());
        mensaje.setCodigo("1");
    }

    return mensaje;
}
```

### Paso 4: Actualizar application.properties ⏳
```properties
# Comentar propiedades obsoletas
#autoregistro.url=${profile.autoregistro.url}
#peritos.almacen.principal=${profile.peritos.almacen.principal:0015MSPERITOS-EXT}

# Conservar LDAP
ldp.url=${profile.ldp.url}
```

---

## 📝 Checklist de Migración

### Código Java
- [ ] Crear `UsuarioRolRepository.java`
- [ ] Crear mappers XML para `cat_Roles` y `tbl_UsuarioRol`
- [ ] Modificar `AdminUsuariosServiceImpl.obtenerUsuarios()`
- [ ] Modificar `AdminUsuariosServiceImpl.obtenerUsuarioInterno()`
- [ ] Modificar `AdminUsuariosServiceImpl.modificarPermisosAUsuario()`
- [ ] Modificar `AutoregistroServiceImpl.registro()`
- [ ] Modificar `AutoregistroServiceImpl.activaUsuario()`
- [ ] Modificar `AutoregistroServiceImpl.creaUsuario()`
- [ ] Conservar llamadas a LDAP (no modificar)

### Configuración
- [ ] Comentar `autoregistro.url` en `application.properties`
- [ ] Comentar `peritos.almacen.principal` en `application.properties`
- [ ] Verificar que `ldp.url` sigue configurado

### Testing
- [ ] Probar login con LDAP + roles locales
- [ ] Probar asignación de roles
- [ ] Probar consulta de usuarios
- [ ] Probar administración de usuarios
- [ ] Validar que PERITOS ya no es consultado
- [ ] Validar que autoregistro ya no es consultado

---

**Última actualización**: 16/Feb/2026
**Versión**: 1.0
**Estado**: Análisis completado, implementación pendiente
