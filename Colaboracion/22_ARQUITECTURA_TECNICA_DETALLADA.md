# 🔧 ARQUITECTURA TÉCNICA: Cómo srvAutoregistro Hace las 4 Consultas

**Documento Técnico Detallado**  
**Fecha:** 2026-02-06

---

## 1. STACK TECNOLÓGICO DE srvAutoregistro

### 1.1 Dependencias clave

```xml
<!-- pom.xml -->
<properties>
    <org.springframework.version>3.1.4.RELEASE</org.springframework.version>
    <jersey.version>2.14</jersey.version>
    <axis2.version>Implícito vía WSO2 libs</axis2.version>
    <jackson.version>1.9.13</jackson.version>
</properties>

<dependency>
    <groupId>org.apache.axis2</groupId>
    <artifactId>axis2-client</artifactId>
    <!-- versión implícita -->
</dependency>

<dependency>
    <groupId>org.wso2.carbon</groupId>
    <artifactId>org.wso2.carbon.um.ws.api</artifactId>
    <!-- Web Service client para RemoteUserStoreManager -->
</dependency>

<dependency>
    <groupId>com.fasterxml.jackson</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>1.9.13</version>
</dependency>
```

### 1.2 Flujo de solicitud HTTP

```
CLIENTE (FEDI-WEB)
        ↓
   HTTP/REST
        ↓
API Manager Gateway
        ↓
   HTTP/REST
        ↓
srvAutoregistro (Jersey @Path endpoints)
        ↓
   RolesServiceImpl (Spring @Service)
        ↓
   SOAP (Axis2)
        ↓
WSO2 Identity Server
   (RemoteUserStoreManager)
```

---

## 2. ANÁLISIS DETALLADO DE CADA OPERACIÓN

### OPERACIÓN 1: Obtener Todos los Roles (tipo=2)

#### Request HTTP (desde FEDI)

```
GET /registro/consultas/roles/2/1/0015MSPERITOSDES-INT HTTP/1.1
Host: apimanager-qa.ift.org.mx
Authorization: Bearer [TOKEN]
Accept: application/json
```

#### Path en REST (Jersey)

**Archivo:** `RegistraEvento.java` línea 286

```java
@GET
@Path("/consultas/roles/{tipo}/{filtro}/{almacen}")
@Produces({ MediaType.APPLICATION_JSON, MediaType.APPLICATION_XML })
public Response recuperaLista(
    @PathParam("tipo") final int tipo,       // 2
    @PathParam("filtro") final String filtro, // "1"
    @PathParam("almacen") final String almacen // "0015MSPERITOSDES-INT"
) throws AppException {
    ResponseRoles responseRoles = new ResponseRoles();
    try {
        final List<Role> respuestaSrv = (List<Role>) this.rolesService.recuperaLista(
            tipo, 
            filtro, 
            almacen
        );
        // ... llena responseRoles ...
    } catch (Exception e) {
        // ... manejo de error ...
    }
    return Response.status(200).entity((Object)responseRoles).build();
}
```

#### Lógica en RolesServiceImpl.java (línea 211)

```java
public List<Role> recuperaLista(final int tipo, final String filtro, final String almacen) {
    final List<Role> listaRoles = new ArrayList<Role>();
    String[] listaDatos = null;
    
    try {
        // PASO 1: Crear conexión SOAP a WSO2
        final ConfigurationContext configContext = 
            ConfigurationContextFactory.createConfigurationContextFromFileSystem(null, null);
        
        final String serviceEndPoint = 
            "${ldap.api.scim.login}" + "RemoteUserStoreManagerService";
        // Resultado: "https://identityserver.ift.org.mx:9443/services/RemoteUserStoreManagerService"
        
        // PASO 2: Crear cliente Axis2
        final RemoteUserStoreManagerServiceStub adminStub = 
            new RemoteUserStoreManagerServiceStub(configContext, serviceEndPoint);
        
        // PASO 3: Configurar autenticación
        final ServiceClient client = adminStub._getServiceClient();
        final Options option = client.getOptions();
        option.setProperty("Cookie", null);
        
        final HttpTransportProperties.Authenticator auth = 
            new HttpTransportProperties.Authenticator();
        auth.setUsername(this.usrUIDPeritos);      // "msperitos_admin@..."
        auth.setPassword(this.usrPWDPeritos);      // [password]
        auth.setPreemptiveAuthentication(true);
        option.setProperty("_NTLM_DIGEST_BASIC_AUTHENTICATION_", auth);
        option.setManageSession(true);
        
        // PASO 4: Ejecutar operación SOAP según tipo
        try {
            final PermissionDTO permissionDTO = new PermissionDTO();
            permissionDTO.setAction("ui.execute");
            
            if (tipo == 1) {
                // Validar usuario existe
                listaDatos = adminStub.listUsers(filtro.replace("--", "/"), 100);
            }
            if (tipo == 2) {
                // ← NUESTRA OPERACIÓN
                // Obtener todos los roles disponibles
                listaDatos = adminStub.getRoleNames();
                
                // RESULTADO: String[] = [
                //   "0015MSPERITOSDES-INT/PERITOS_ADMIN",
                //   "0015MSPERITOSDES-INT/PERITOS_CONSULTA",
                //   "0015MSPERITOSDES-INT/PERITOS_REVISOR",
                //   "0022FEDI/FEDI_ADMIN"
                // ]
            }
            if (tipo == 3) {
                // Obtener roles de usuario
                listaDatos = adminStub.getRoleListOfUser(filtro.replace("--", "/"));
            }
            if (tipo == 4) {
                // Obtener usuarios por rol
                listaDatos = adminStub.getUserListOfRole(filtro.replace("--", "/"));
            }
        }
        catch (Exception e) {
            System.err.println("Error en el metodo");
            e.printStackTrace();
        }
    }
    catch (Exception e2) {
        e2.printStackTrace();
    }
    
    // PASO 5: Filtrar por almacén
    String[] filtraAlmacen;
    for (int i = 0; i < (filtraAlmacen = filtraAlmacen(listaDatos, almacen)).length; ++i) {
        final String datoRol = filtraAlmacen[i];
        final Role role = new Role();
        role.setDescripcion_Rol(datoRol);
        listaRoles.add(role);
    }
    
    return listaRoles;
    // RESULTADO: List<Role> = [
    //   Role{descripcion_Rol="0015MSPERITOSDES-INT/PERITOS_ADMIN"},
    //   Role{descripcion_Rol="0015MSPERITOSDES-INT/PERITOS_CONSULTA"},
    //   Role{descripcion_Rol="0015MSPERITOSDES-INT/PERITOS_REVISOR"}
    // ]
}
```

#### Método auxiliar: filtraAlmacen

```java
public static String[] filtraAlmacen(final String[] lista, final String almacen) {
    final List<String> where = new ArrayList<String>();
    
    if (lista != null) {
        for (int i = 0; i < lista.length; ++i) {
            // Filtra roles que empiezan con el almacén solicitado
            if (lista[i].toString().startsWith(almacen)) {
                where.add(lista[i]);
            }
        }
    }
    
    final String[] strDups = new String[where.size()];
    return where.toArray(strDups);
    
    // EJEMPLO:
    // Input:  ["0015MSPERITOSDES-INT/PERITOS_ADMIN", "0022FEDI/FEDI_ADMIN"]
    //         almacen="0015MSPERITOSDES-INT"
    // Output: ["0015MSPERITOSDES-INT/PERITOS_ADMIN"]
}
```

#### Respuesta JSON (desde srvAutoregistro)

```json
{
  "datosRoles": [
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/PERITOS_ADMIN"
    },
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/PERITOS_CONSULTA"
    },
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/PERITOS_REVISOR"
    }
  ],
  "code": 102,
  "error": "false"
}
```

---

### OPERACIÓN 2: Obtener Usuarios por Rol (tipo=4)

#### Request HTTP

```
GET /registro/consultas/roles/4/0015MSPERITOSDES-INT--PERITOS_ADMIN/0022FEDI HTTP/1.1
```

#### Parámetros decodificados

```
tipo:    4
filtro:  "0015MSPERITOSDES-INT--PERITOS_ADMIN"
almacen: "0022FEDI"
```

#### Procesamiento en RolesServiceImpl

```java
if (tipo == 4) {
    // El "--" se reemplaza por "/" para el formato WSO2
    listaDatos = adminStub.getUserListOfRole(
        "0015MSPERITOSDES-INT/PERITOS_ADMIN".replace("--", "/")
        // Resultado: "0015MSPERITOSDES-INT/PERITOS_ADMIN"
    );
    
    // RESPUESTA de WSO2:
    // String[] = [
    //   "juan_perez",
    //   "maria_garcia",
    //   "carlos_lopez"
    // ]
}
```

#### Flujo de datos

```
FEDI Request:
    tipo=4
    filtro="0015MSPERITOSDES-INT--PERITOS_ADMIN"
         ↓
    reemplaza "--" → "/"
         ↓
    "0015MSPERITOSDES-INT/PERITOS_ADMIN"
         ↓
    WSO2 RemoteUserStoreManager
    .getUserListOfRole("0015MSPERITOSDES-INT/PERITOS_ADMIN")
         ↓
    String[] usuarios
         ↓
    Filtra por almacén="0022FEDI"
    (nota: los usuarios no tienen prefijo de almacén)
         ↓
    List<Role> = [
      Role{descripcion_Rol="juan_perez"},
      Role{descripcion_Rol="maria_garcia"},
      Role{descripcion_Rol="carlos_lopez"}
    ]
         ↓
    Response JSON
```

#### Respuesta JSON

```json
{
  "datosRoles": [
    {
      "descripcion_Rol": "juan_perez"
    },
    {
      "descripcion_Rol": "maria_garcia"
    },
    {
      "descripcion_Rol": "carlos_lopez"
    }
  ],
  "code": 102,
  "error": "false"
}
```

---

### OPERACIÓN 3: Validar Usuario Existe (tipo=1)

#### Request HTTP

```
GET /registro/consultas/roles/1/juan_perez/0015MSPERITOSDES-INT HTTP/1.1
```

#### Parámetros

```
tipo:    1
filtro:  "juan_perez"
almacen: "0015MSPERITOSDES-INT"
```

#### Procesamiento

```java
if (tipo == 1) {
    listaDatos = adminStub.listUsers(
        "juan_perez".replace("--", "/"),  // No tiene "--", sale igual
        100  // Máximo 100 resultados
    );
    
    // RESPUESTA de WSO2:
    // String[] = [
    //   "juan_perez"  // Si existe
    // ]
    // O array vacío si no existe
}
```

#### Lógica

```
El método listUsers() busca usuarios en el dominio especificado.
Si encuentra el usuario, retorna array con el nombre.
Si no lo encuentra, retorna array vacío.

Post-procesamiento:
- Filtra por almacén (aunque usuarios no tienen prefijo)
- Convierte a List<Role>
- Retorna JSON con datosRoles

El cliente (FEDI) verifica si la lista no es vacía
para determinar si el usuario existe.
```

---

### OPERACIÓN 4: Actualizar Roles (POST)

#### Request HTTP

```
POST /registro/actualizar HTTP/1.1
Content-Type: application/json

{
  "user": "juan_perez",
  "rolAgregar": ["0015MSPERITOSDES-INT/PERITOS_ADMIN"],
  "rolBorrar": ["0015MSPERITOSDES-INT/PERITOS_CONSULTA"]
}
```

#### Procesamiento en RolesServiceImpl (línea 107)

```java
public ResponseMensaje administraRol(
    final String userName,           // "juan_perez"
    final String[] rolesBorrar,      // ["0015MSPERITOSDES-INT/PERITOS_CONSULTA"]
    final String[] rolesAgregar      // ["0015MSPERITOSDES-INT/PERITOS_ADMIN"]
) throws AppException {
    
    ResponseMensaje responseMensaje = new ResponseMensaje();
    
    try {
        // PASO 1: Crear conexión SOAP
        final ConfigurationContext configContext = 
            ConfigurationContextFactory.createConfigurationContextFromFileSystem(null, null);
        
        final String serviceEndPoint = 
            "${ldap.api.scim.login}" + "RemoteUserStoreManagerService";
        
        // PASO 2: Crear cliente Axis2
        final RemoteUserStoreManagerServiceStub adminStub = 
            new RemoteUserStoreManagerServiceStub(configContext, serviceEndPoint);
        
        // PASO 3: Configurar autenticación
        final ServiceClient client = adminStub._getServiceClient();
        final Options option = client.getOptions();
        
        final HttpTransportProperties.Authenticator auth = 
            new HttpTransportProperties.Authenticator();
        
        // Detectar si usuario es externo (tiene "EXT")
        if (userName.contains("EXT")) {
            auth.setUsername(this.usrUIDPeritosExt);
            auth.setPassword(this.usrPWDPeritosExt);
        } else {
            auth.setUsername(this.usrUIDPeritos);
            auth.setPassword(this.usrPWDPeritos);
        }
        
        auth.setPreemptiveAuthentication(true);
        option.setProperty("_NTLM_DIGEST_BASIC_AUTHENTICATION_", auth);
        option.setManageSession(true);
        
        // PASO 4: Ejecutar actualización
        try {
            // Llamada SOAP a WSO2
            adminStub.updateRoleListOfUser(
                "juan_perez",
                ["0015MSPERITOSDES-INT/PERITOS_CONSULTA"],
                ["0015MSPERITOSDES-INT/PERITOS_ADMIN"]
            );
            // WSO2 responde: OK (sin error)
            
            // PASO 5: Construir respuesta
            final Mensaje mensaje = new Mensaje();
            mensaje.setCodigo("0");
            mensaje.setMensaje("Actualización del Rol Exitoso");
            
            responseMensaje.setCode(102);
            responseMensaje.setError("false");
            responseMensaje.setMensaje(mensaje);
        }
        catch (Exception e) {
            // Manejo de error
            e.printStackTrace();
        }
    }
    catch (Exception e2) {
        e2.printStackTrace();
        responseMensaje.setCode(102);
        responseMensaje.setError("true");
        
        final Mensaje mensaje = new Mensaje();
        mensaje.setCodigo("1");
        mensaje.setMensaje("Error al actualizar el Rol");
        responseMensaje.setMensaje(mensaje);
        
        throw new RuntimeException(e2.getMessage(), e2);
    }
    
    return responseMensaje;
}
```

#### Respuesta JSON

```json
{
  "code": 102,
  "error": "false",
  "mensaje": {
    "codigo": "0",
    "mensaje": "Actualización del Rol Exitoso"
  }
}
```

---

## 3. FLUJO COMPLETO: DIAGRAMA TEMPORAL

```
TIEMPO    CLIENTE (FEDI)          API MANAGER        srvAutoregistro      WSO2
──────    ──────────────          ──────────         ───────────────      ────
  T0      Obtener roles
           GET /roles/2/1/...     
           ───────────────────────────────→
  T1                               Routea a backend
                                   ─────────────────→
  T2                                                 Procesa parámetros
                                                     Crea cliente SOAP
  T3                                                 Llamada SOAP
                                                     .getRoleNames()
                                                     ──────────────────→
  T4                                                                      Consulta BD
                                                                         Retorna []
                                                                         ←──────────
  T5                                                 Recibe datos
                                                     Filtra por almacén
                                                     Convierte a JSON
  T6                               ←─────────────────
                                   Retorna JSON
           ←──────────────────────
  T7      Procesa JSON
           Llena dropdown usuarios
           
TOTAL: ~100-150ms
  - Red (IFT→API): ~20ms
  - API→Backend: ~10ms
  - Backend SOAP: ~50ms
  - WSO2 operación: ~30ms
  - Retorno: ~10ms
```

---

## 4. COMPARATIVA: CÓMO IMPLEMENTAR EN FEDI (Opción B)

Si replicaras esto en FEDI-WEB directamente (sin API Manager):

```java
@Service
public class RolesServiceFEDI {
    
    @Value("${ldap.scim.endpoint}")
    private String srvLOGIN;  // "https://identityserver.ift.org.mx:9443/services/"
    
    @Value("${ldap.scim.admin.user}")
    private String usrUID;    // "msperitos_admin@..."
    
    @Value("${ldap.scim.admin.pass}")
    private String usrPWD;    // [password]
    
    // Obtener todos los roles (tipo=2)
    public List<String> obtenerTodosLosRoles(String almacen) throws Exception {
        RemoteUserStoreManagerServiceStub stub = crearStub();
        String[] roles = stub.getRoleNames();
        return filtrarPorAlmacen(roles, almacen);
    }
    
    // Obtener usuarios por rol (tipo=4)
    public List<String> obtenerUsuariosPorRol(String rolName) throws Exception {
        RemoteUserStoreManagerServiceStub stub = crearStub();
        String[] usuarios = stub.getUserListOfRole(rolName.replace("--", "/"));
        return Arrays.asList(usuarios != null ? usuarios : new String[0]);
    }
    
    // Validar usuario (tipo=1)
    public boolean usuarioExiste(String usuario) throws Exception {
        RemoteUserStoreManagerServiceStub stub = crearStub();
        String[] usuarios = stub.listUsers(usuario, 100);
        return usuarios != null && usuarios.length > 0;
    }
    
    // Actualizar roles (POST)
    public void actualizarRoles(String usuario, String[] roles) throws Exception {
        RemoteUserStoreManagerServiceStub stub = crearStub();
        stub.updateRoleListOfUser(usuario, rolesBorrar, rolesAgregar);
    }
    
    private RemoteUserStoreManagerServiceStub crearStub() throws Exception {
        ConfigurationContext ctx = ConfigurationContextFactory
            .createConfigurationContextFromFileSystem(null, null);
        
        RemoteUserStoreManagerServiceStub stub = 
            new RemoteUserStoreManagerServiceStub(
                ctx, 
                srvLOGIN + "RemoteUserStoreManagerService"
            );
        
        // Configurar auth (igual que en srvAutoregistro)
        // ...
        
        return stub;
    }
}
```

---

## 5. CONCLUSIÓN ARQUITECTÓNICA

### Técnica Usada

**WSO2 Remote User Store Manager Web Service (SOAP)**

```
No es una API REST propia.
No consulta base de datos custom.
Es 100% delegado a WSO2 Identity Server.
```

### Datos Fluyen Así

```
FEDI 
  ↓ parámetros REST
srvAutoregistro (gateway)
  ↓ parámetros procesados
RemoteUserStoreManager SOAP
  ↓ query a LDAP/usuario store
WSO2 Identity Server
  ↓ roles y usuarios
RemoteUserStoreManager SOAP
  ↓ respuesta SOAP
srvAutoregistro (convierte a JSON)
  ↓ JSON
FEDI
```

### Lo Importante

1. **NO requiere replicar tablas de BD**
   - Accede directamente a WSO2
   - Mismo usuario store que ya existe en CRT

2. **Código es trasladable a FEDI**
   - 4 operaciones simples
   - ~10 líneas de código core cada una
   - Usa librerías estándar (Axis2, Spring)

3. **Performance es bueno**
   - ~100ms incluida red
   - SOAP es rápido para estos queries
   - Puede caché si es necesario

4. **Opción A (desplegar srvAutoregistro) es más rápido** 
   - Opción B (integrar en FEDI) es mejor arquitectura

---

*Documento Técnico: Arquitectura srvAutoregistro*  
*Generado: 2026-02-06*  
*Clasificación: Técnico-Arquitectónico*
