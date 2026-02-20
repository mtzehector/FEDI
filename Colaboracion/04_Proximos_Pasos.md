# Próximos Pasos - Guía de Implementación

## 🎯 Objetivo

Completar la migración del código Java para eliminar las dependencias de PERITOS y autoregistro, utilizando las tablas locales `cat_Roles` y `tbl_UsuarioRol` creadas en la base de datos.

---

## 📋 Checklist General

### ✅ COMPLETADO
- [x] Análisis de dependencias
- [x] Diseño de tablas en BD
- [x] Creación de tablas `cat_Roles` y `tbl_UsuarioRol`
- [x] Inserción de roles iniciales
- [x] Configuración de usuario administrador DEV/QA
- [x] Creación de índices de optimización
- [x] Scripts SQL de validación
- [x] Documentación completa en markdown

### ⏳ PENDIENTE
- [ ] Implementación de código Java (Fase 1)
- [ ] Testing y validación (Fase 2)
- [ ] Despliegue y migración a PROD (Fase 3)

---

## 🚀 FASE 1: Implementación de Código Java

### Paso 1.1: Crear Repository para `cat_Roles`

**Archivo a crear**: `fedi-web/src/main/java/fedi/ift/org/mx/persistence/mapper/RolRepository.java`

```java
package fedi.ift.org.mx.persistence.mapper;

import java.util.List;
import org.apache.ibatis.annotations.Select;
import org.springframework.stereotype.Repository;
import fedi.ift.org.mx.model.AdmRol;

/**
 * Repository para operaciones con cat_Roles
 */
@Repository
public interface RolRepository {

    /**
     * Obtiene todos los roles activos
     */
    @Select({
        "SELECT RolID, Sistema, DescripcionRol, Activo, FechaCreacion",
        "FROM cat_Roles",
        "WHERE Activo = 1",
        "ORDER BY RolID"
    })
    List<AdmRol> obtenerTodosLosRoles();

    /**
     * Obtiene un rol específico por ID
     */
    @Select({
        "SELECT RolID, Sistema, DescripcionRol, Activo, FechaCreacion",
        "FROM cat_Roles",
        "WHERE RolID = #{rolID} AND Activo = 1"
    })
    AdmRol obtenerRolPorID(String rolID);
}
```

**Estimación**: 30 minutos

---

### Paso 1.2: Crear Repository para `tbl_UsuarioRol`

**Archivo a crear**: `fedi-web/src/main/java/fedi/ift/org/mx/persistence/mapper/UsuarioRolRepository.java`

```java
package fedi.ift.org.mx.persistence.mapper;

import java.util.List;
import org.apache.ibatis.annotations.*;
import org.springframework.stereotype.Repository;
import fedi.ift.org.mx.model.AdmUsuario;

/**
 * Repository para operaciones con tbl_UsuarioRol
 */
@Repository
public interface UsuarioRolRepository {

    /**
     * Obtiene todos los usuarios con sus roles
     */
    @Select({
        "SELECT DISTINCT ur.UsuarioID, ur.Sistema",
        "FROM tbl_UsuarioRol ur",
        "WHERE ur.Activo = 1",
        "ORDER BY ur.UsuarioID"
    })
    @Results({
        @Result(property = "idUsuario", column = "UsuarioID"),
        @Result(property = "idSistema", column = "Sistema"),
        @Result(property = "rol", column = "UsuarioID",
                javaType = fedi.ift.org.mx.model.AdmRol.class,
                one = @One(select = "obtenerRolPorUsuario"))
    })
    List<AdmUsuario> obtenerTodosLosUsuarios();

    /**
     * Obtiene los roles de un usuario específico
     */
    @Select({
        "SELECT r.RolID, r.DescripcionRol, r.Sistema",
        "FROM tbl_UsuarioRol ur",
        "INNER JOIN cat_Roles r ON ur.RolID = r.RolID",
        "WHERE ur.UsuarioID = #{usuarioID}",
        "AND ur.Activo = 1",
        "AND r.Activo = 1"
    })
    @Results({
        @Result(property = "idRol", column = "RolID"),
        @Result(property = "descripcionRol", column = "DescripcionRol"),
        @Result(property = "idSistema", column = "Sistema")
    })
    List<fedi.ift.org.mx.model.AdmRol> obtenerRolesPorUsuario(String usuarioID);

    /**
     * Obtiene un usuario específico por ID
     */
    @Select({
        "SELECT DISTINCT UsuarioID, Sistema",
        "FROM tbl_UsuarioRol",
        "WHERE UsuarioID = #{usuarioID} AND Activo = 1"
    })
    @Results({
        @Result(property = "idUsuario", column = "UsuarioID"),
        @Result(property = "idSistema", column = "Sistema")
    })
    AdmUsuario obtenerUsuarioPorID(String usuarioID);

    /**
     * Obtiene usuarios por rol
     */
    @Select({
        "SELECT DISTINCT UsuarioID",
        "FROM tbl_UsuarioRol",
        "WHERE RolID = #{rolID} AND Activo = 1"
    })
    List<String> obtenerUsuariosPorRol(String rolID);

    /**
     * Asigna un rol a un usuario
     */
    @Insert({
        "INSERT INTO tbl_UsuarioRol (UsuarioID, RolID, Sistema, AsignadoPor, Observaciones)",
        "VALUES (#{usuarioID}, #{rolID}, #{sistema}, #{asignadoPor}, #{observaciones})"
    })
    void asignarRol(@Param("usuarioID") String usuarioID,
                    @Param("rolID") String rolID,
                    @Param("sistema") String sistema,
                    @Param("asignadoPor") String asignadoPor,
                    @Param("observaciones") String observaciones);

    /**
     * Desactiva un rol de un usuario (soft delete)
     */
    @Update({
        "UPDATE tbl_UsuarioRol",
        "SET Activo = 0,",
        "    FechaBaja = GETDATE(),",
        "    BajaPor = #{bajaPor}",
        "WHERE UsuarioID = #{usuarioID}",
        "AND RolID = #{rolID}",
        "AND Activo = 1"
    })
    void eliminarRol(@Param("usuarioID") String usuarioID,
                     @Param("rolID") String rolID,
                     @Param("bajaPor") String bajaPor);

    /**
     * Verifica si un usuario tiene un rol específico
     */
    @Select({
        "SELECT COUNT(*)",
        "FROM tbl_UsuarioRol",
        "WHERE UsuarioID = #{usuarioID}",
        "AND RolID = #{rolID}",
        "AND Activo = 1"
    })
    int tieneRol(@Param("usuarioID") String usuarioID,
                 @Param("rolID") String rolID);
}
```

**Estimación**: 1 hora

---

### Paso 1.3: Modificar `AdminUsuariosServiceImpl`

**Archivo a modificar**: `fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/AdminUsuariosServiceImpl.java`

**Cambios necesarios**:

1. **Agregar inyección de dependencias**:
```java
@Autowired
private UsuarioRolRepository usuarioRolRepository;

@Autowired
private RolRepository rolRepository;
```

2. **Modificar `obtenerUsuarios()` (líneas 89-203)**:
```java
@Override
public ResponseUsuarios obtenerUsuarios() throws Exception {
    ResponseUsuarios responseUsuarios = new ResponseUsuarios();
    List<AdmUsuario> resListaUsuarios = new ArrayList();
    List<AdmRol> rolesAplicativo = new ArrayList();

    try {
        LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarios() - Consultando BD local");

        // YA NO consulta PERITOS, consulta BD local
        rolesAplicativo = rolRepository.obtenerTodosLosRoles();
        resListaUsuarios = usuarioRolRepository.obtenerTodosLosUsuarios();

        // Enriquecer usuarios con sus roles
        for (AdmUsuario usuario : resListaUsuarios) {
            List<AdmRol> rolesUsuario = usuarioRolRepository.obtenerRolesPorUsuario(usuario.getIdUsuario());
            if (!rolesUsuario.isEmpty()) {
                usuario.setRol(rolesUsuario.get(0)); // Primer rol para compatibilidad
            }
        }

        responseUsuarios.setCode(0);
        responseUsuarios.setError("false");
        responseUsuarios.setMensaje("Con datos de roles y usuarios desde BD local");
        responseUsuarios.setRolesApp(rolesAplicativo);
        responseUsuarios.setAdmUsuarios(resListaUsuarios);

        LOGGER.info("Usuarios obtenidos: {}, Roles obtenidos: {}",
                   resListaUsuarios.size(), rolesAplicativo.size());

    } catch (Exception e) {
        LOGGER.error("Error al obtener usuarios desde BD local", e);
        throw new Exception("Error al obtener usuarios: " + e.getMessage());
    }

    return responseUsuarios;
}
```

3. **Modificar `obtenerUsuarioInterno()` (líneas 229-287)**:
```java
@Override
public ResponseUsuario obtenerUsuarioInterno(String prmUsuario) throws Exception {
    ResponseUsuario responseUsuario = new ResponseUsuario();

    try {
        LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarioInterno() - Consultando usuario: {} en BD local", prmUsuario);

        // YA NO consulta PERITOS, consulta BD local
        AdmUsuario oUsuario = usuarioRolRepository.obtenerUsuarioPorID(prmUsuario);

        if (oUsuario != null) {
            // Obtener roles del usuario
            List<AdmRol> roles = usuarioRolRepository.obtenerRolesPorUsuario(prmUsuario);
            if (!roles.isEmpty()) {
                oUsuario.setRol(roles.get(0));
            }

            responseUsuario.setCode(0);
            responseUsuario.setError("false");
            responseUsuario.setMensaje("Usuario encontrado en BD local");
            responseUsuario.setUsuarioApp(oUsuario);

            LOGGER.info("Usuario encontrado: {}", prmUsuario);
        } else {
            responseUsuario.setCode(1);
            responseUsuario.setError("true");
            responseUsuario.setMensaje("Usuario no encontrado en BD local");

            LOGGER.warn("Usuario no encontrado: {}", prmUsuario);
        }

    } catch (Exception e) {
        LOGGER.error("Error al obtener usuario desde BD local", e);
        throw new Exception("Error al obtener usuario: " + e.getMessage());
    }

    return responseUsuario;
}
```

4. **Modificar `modificarPermisosAUsuario()` (líneas 290-307)**:
```java
@Override
public ResponseMensaje modificarPermisosAUsuario(CambioUsuarioRequest prmCambioUsuarioRequest) throws Exception {
    ResponseMensaje responseMensaje = new ResponseMensaje();
    Mensaje mensaje = new Mensaje();

    try {
        LOGGER.info("AdminUsuariosServiceImpl.modificarPermisosAUsuario() - Usuario: {}", prmCambioUsuarioRequest.getUser());

        // Extraer usuario del formato "sistema/usuario"
        String usuarioID = prmCambioUsuarioRequest.getUser();
        if (usuarioID.contains("/")) {
            usuarioID = usuarioID.substring(usuarioID.indexOf("/") + 1);
        }

        // Obtener usuario actual de sesión para auditoría
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String usuarioActual = auth != null ? auth.getName() : "SYSTEM";

        // Agregar roles
        if (prmCambioUsuarioRequest.getRolAgregar() != null) {
            for (String rolCompleto : prmCambioUsuarioRequest.getRolAgregar()) {
                String rolID = rolCompleto;
                if (rolID.contains("/")) {
                    rolID = rolID.substring(rolID.indexOf("/") + 1);
                }

                // Verificar si ya tiene el rol
                if (usuarioRolRepository.tieneRol(usuarioID, rolID) == 0) {
                    usuarioRolRepository.asignarRol(usuarioID, rolID, "0022FEDI-INT", usuarioActual, "Rol asignado desde administración");
                    LOGGER.info("Rol {} asignado a usuario {}", rolID, usuarioID);
                }
            }
        }

        // Eliminar roles
        if (prmCambioUsuarioRequest.getRolBorrar() != null) {
            for (String rolCompleto : prmCambioUsuarioRequest.getRolBorrar()) {
                String rolID = rolCompleto;
                if (rolID.contains("/")) {
                    rolID = rolID.substring(rolID.indexOf("/") + 1);
                }

                usuarioRolRepository.eliminarRol(usuarioID, rolID, usuarioActual);
                LOGGER.info("Rol {} eliminado del usuario {}", rolID, usuarioID);
            }
        }

        mensaje.setCodigo("0");
        mensaje.setMensaje("Roles modificados exitosamente");
        responseMensaje.setCode(102);
        responseMensaje.setMensaje(mensaje);

    } catch (Exception e) {
        LOGGER.error("Error al modificar permisos", e);
        mensaje.setCodigo("1");
        mensaje.setMensaje("Error al modificar permisos: " + e.getMessage());
        responseMensaje.setCode(500);
        responseMensaje.setMensaje(mensaje);
    }

    return responseMensaje;
}
```

**Estimación**: 2 horas

---

### Paso 1.4: Modificar `AutoregistroServiceImpl`

**Archivo a modificar**: `fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/AutoregistroServiceImpl.java`

**Cambios necesarios**:

1. **Agregar inyección de dependencias**:
```java
@Autowired
private UsuarioRolRepository usuarioRolRepository;

@Autowired
private AdminUsuariosService adminUsuariosService; // Para validar en LDAP
```

2. **Modificar `creaUsuario()` (líneas 153-176)**:
```java
@Override
public Message creaUsuario(crearUsuario newUser) throws Exception {
    Message mensaje = new Message();

    try {
        LOGGER.info("AutoregistroServiceImpl.creaUsuario() - Usuario: {}", newUser.getUser());

        // 1. Validar que el usuario existe en LDAP
        HeaderBodyLDAP ldapRequest = new HeaderBodyLDAP();
        ldapRequest.setUser(newUser.getUser());
        LDAPInfoResponse ldapInfo = adminUsuariosService.obtenerinformacionDetalleUsuario(ldapRequest);

        if (!ldapInfo.getResult().getMessage().equals("Success")) {
            mensaje.setMensaje("Usuario no encontrado en LDAP");
            mensaje.setCodigo("1");
            return mensaje;
        }

        // 2. Verificar que el correo coincide
        if (!ldapInfo.getResult().getEntry().getMail().equals(newUser.getCorreo())) {
            mensaje.setMensaje("El correo no coincide con el registrado en LDAP");
            mensaje.setCodigo("1");
            return mensaje;
        }

        // 3. Verificar si el usuario ya existe en BD local
        if (usuarioRolRepository.obtenerUsuarioPorID(newUser.getUser()) != null) {
            mensaje.setMensaje("El usuario ya está registrado en el sistema");
            mensaje.setCodigo("1");
            return mensaje;
        }

        // 4. Crear usuario en BD local con rol por defecto
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String usuarioActual = auth != null ? auth.getName() : "SYSTEM";

        usuarioRolRepository.asignarRol(
            newUser.getUser(),
            "ROL_0022FEDI_USER",
            "0022FEDI-INT",
            usuarioActual,
            "Usuario registrado desde formulario de autoregistro"
        );

        mensaje.setMensaje("Usuario registrado exitosamente");
        mensaje.setCodigo("0");

        LOGGER.info("Usuario {} registrado exitosamente", newUser.getUser());

    } catch (Exception e) {
        LOGGER.error("Error al crear usuario", e);
        mensaje.setMensaje("Error al registrar usuario: " + e.getMessage());
        mensaje.setCodigo("1");
    }

    return mensaje;
}
```

3. **Modificar `activaUsuario()` (líneas 121-145)**:
```java
@Override
public Message activaUsuario(String xScim) throws Exception {
    Message mensaje = new Message();

    try {
        LOGGER.info("AutoregistroServiceImpl.activaUsuario() - Token: {}", xScim);

        // Decodificar token SCIM para obtener el usuario
        // Nota: Esto depende de cómo se genere el token en tu sistema
        // Por ahora, simplemente retornamos éxito si el usuario existe

        mensaje.setMensaje("Usuario activado exitosamente");
        mensaje.setCodigo("0");

        LOGGER.info("Usuario activado desde token: {}", xScim);

    } catch (Exception e) {
        LOGGER.error("Error al activar usuario", e);
        mensaje.setMensaje("Error al activar usuario: " + e.getMessage());
        mensaje.setCodigo("1");
    }

    return mensaje;
}
```

**Nota**: El método `registro()` (líneas 61-119) puede ser marcado como `@Deprecated` ya que usa URL hardcodeada a localhost.

**Estimación**: 1.5 horas

---

### Paso 1.5: Actualizar `application.properties`

**Archivo a modificar**: `fedi-web/src/main/resources/application.properties`

**Cambios**:
```properties
# ============================================
# DEPENDENCIAS ELIMINADAS (16/Feb/2026)
# ============================================
# Las siguientes propiedades fueron comentadas porque ya no se usan:
# - autoregistro.url: Gestión de usuarios ahora es local (cat_Roles, tbl_UsuarioRol)
# - peritos.almacen.principal: Catálogo de usuarios ahora es local

#autoregistro.url=${profile.autoregistro.url}
#peritos.almacen.principal=${profile.peritos.almacen.principal:0015MSPERITOS-EXT}

# ============================================
# DEPENDENCIAS CONSERVADAS
# ============================================
# LDAP se mantiene como única dependencia externa
# - Autenticación de usuarios
# - Información detallada (nombre, correo, puesto)
# - Búsqueda de usuarios

ldp.url=${profile.ldp.url}
```

**Estimación**: 10 minutos

---

## 🧪 FASE 2: Testing y Validación

### Test 1: Login con LDAP + Roles Locales
**Objetivo**: Verificar que el login funciona con LDAP y los roles se obtienen de BD local

**Pasos**:
1. Limpiar cookies y caché del navegador
2. Acceder a `http://localhost:9090/FEDIPortalWeb-1.0/`
3. Ingresar usuario: `dgtic.dds.ext023@ift.org.mx`
4. Ingresar contraseña de LDAP
5. Verificar que el login sea exitoso
6. Verificar que aparezcan las opciones de administrador

**Resultado esperado**: Login exitoso con permisos de administrador

---

### Test 2: Consultar Usuarios
**Objetivo**: Verificar que la lista de usuarios se obtiene de BD local

**Pasos**:
1. Navegar a "Administración > Usuarios"
2. Verificar que aparece la lista de usuarios
3. Revisar logs para confirmar que NO se consulta PERITOS
4. Verificar que aparecen los roles correctos

**Resultado esperado**: Lista de usuarios desde BD local sin llamadas a PERITOS

---

### Test 3: Asignar Rol a Usuario
**Objetivo**: Verificar que se pueden asignar roles desde BD local

**Pasos**:
1. Ir a "Administración > Usuarios"
2. Agregar un nuevo usuario: `test.usuario@ift.org.mx`
3. Asignar rol: `ROL_0022FEDI_FIRMANTE`
4. Guardar
5. Verificar en BD:
```sql
SELECT * FROM tbl_UsuarioRol
WHERE UsuarioID = 'test.usuario@ift.org.mx';
```

**Resultado esperado**: Usuario con rol asignado en BD local

---

### Test 4: Firmar Documento con Página Visible
**Objetivo**: Verificar que la firma de documentos sigue funcionando

**Pasos**:
1. Cargar un documento PDF de prueba
2. Asignar como firmante a `dgtic.dds.ext023@ift.org.mx`
3. Firmar el documento
4. Descargar el PDF firmado
5. Verificar que aparece la página de firmas al final

**Resultado esperado**: PDF con página de firmas visible

---

### Test 5: Validar que PERITOS NO es Consultado
**Objetivo**: Confirmar que ya no hay llamadas al sistema PERITOS

**Pasos**:
1. Activar logs de nivel DEBUG
2. Realizar operaciones de usuarios (consultar, agregar, modificar)
3. Buscar en logs la cadena "PERITOS" o "0015MSPERITOS"
4. Buscar en logs la cadena "autoRegistroUrl"

**Resultado esperado**: 0 ocurrencias de PERITOS o autoRegistroUrl en logs

---

## 🚀 FASE 3: Despliegue y Migración a PROD

### Paso 3.1: Respaldo de BD Actual
```sql
-- Hacer respaldo completo de BD FEDI antes de cualquier cambio
BACKUP DATABASE [FEDI]
TO DISK = 'D:\Backups\FEDI_Antes_Migracion_20260216.bak'
WITH FORMAT, INIT, COMPRESSION;
```

### Paso 3.2: Ejecutar Scripts en PROD
1. Conectarse a servidor de PROD
2. Ejecutar `01_DDL_Tablas_UsuariosRoles.sql`
3. Ejecutar `02_DML_Datos_Iniciales.sql` (editar email del admin PROD)
4. Ejecutar `03_Validacion_Estructura.sql`

### Paso 3.3: Cambiar Administrador a Cuenta CRT
```sql
-- Desactivar administrador DEV
UPDATE tbl_UsuarioRol
SET Activo = 0, FechaBaja = GETDATE(), BajaPor = 'SYSTEM'
WHERE UsuarioID = 'dgtic.dds.ext023@ift.org.mx';

-- Activar administrador PROD
INSERT INTO tbl_UsuarioRol (UsuarioID, RolID, AsignadoPor, Observaciones) VALUES
('deid.ext33@crt.gob.mx', 'ROL_0022FEDI_ADMIN', 'SYSTEM', 'Admin PROD'),
('deid.ext33@crt.gob.mx', 'ROL_0022FEDI_USER', 'SYSTEM', 'Rol base'),
('deid.ext33@crt.gob.mx', 'ROL_0022FEDI_FIRMANTE', 'SYSTEM', 'Firmante');
```

### Paso 3.4: Desplegar WAR en PROD
1. Detener Tomcat en PROD
2. Copiar `FEDIPortalWeb-1.0.war` a `webapps/`
3. Verificar `application.properties` (debe tener propiedades comentadas)
4. Iniciar Tomcat
5. Revisar logs de arranque

### Paso 3.5: Smoke Tests en PROD
1. Login con usuario administrador PROD
2. Consultar lista de usuarios
3. Cargar documento de prueba
4. Firmar documento
5. Descargar PDF y verificar página de firmas

---

## ⏱️ Estimación de Tiempos

| Fase | Tarea | Tiempo Estimado |
|------|-------|-----------------|
| 1.1 | Crear RolRepository | 30 min |
| 1.2 | Crear UsuarioRolRepository | 1 hora |
| 1.3 | Modificar AdminUsuariosServiceImpl | 2 horas |
| 1.4 | Modificar AutoregistroServiceImpl | 1.5 horas |
| 1.5 | Actualizar application.properties | 10 min |
| 2 | Testing completo | 2 horas |
| 3 | Despliegue a PROD | 1 hora |
| **TOTAL** | | **8 horas 10 min** |

---

## 📞 Contacto para Dudas

**Desarrollador DEV/QA**: dgtic.dds.ext023@ift.org.mx
**Administrador PROD**: deid.ext33@crt.gob.mx

---

## 📚 Referencias

- `01_Resumen_Migracion_FEDI.md` - Resumen general
- `02_Base_Datos_Cambios.md` - Detalles de BD
- `03_Dependencias_Eliminadas.md` - Análisis de dependencias
- `DOCUMENTACION_Gestion_Usuarios.sql` - Consultas útiles

---

**Última actualización**: 16/Feb/2026
**Versión**: 1.0
**Estado**: Listo para iniciar Fase 1
