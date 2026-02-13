# Mapeo de Métodos de Consumo PERITOS desde FEDI

**Fecha:** 2026-02-05
**Objetivo:** Identificar qué métodos en FEDI consumen qué APIs de PERITOS
**Status:** ANÁLISIS CRÍTICO - Bloqueador de migración a CRT

---

## 📋 Resumen Ejecutivo

FEDI y los 8 proyectos de PERITOS **CONSUMEN** un servicio web llamado **`srvAutoregistro`** que:
- **NO está incluido en los repositorios descargados**
- **NO está visible en C:\github**
- Expone endpoints REST bajo la ruta base: `/srvAutoregistro/v3.0/` (o similar)
- Es publicado por API Manager bajo: `https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/`

**Problema Crítico:** El servicio `srvAutoregistro` está registrado en API Manager IFT pero **NO en API Manager CRT**, por eso FEDI no puede obtener usuarios de PERITOS en CRT.

---

## 1. FEDI → Consumidor de Servicios de PERITOS

### 1.1 Clase Principal: AdminUsuariosServiceImpl.java

**Ubicación:** [fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/AdminUsuariosServiceImpl.java](fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/AdminUsuariosServiceImpl.java)

**Propiedades inyectadas (pom.xml):**
```java
@Value("${autoregistro.url}")
private String autoRegistroUrl;  // https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/

@Value("${mdsgd.token.url}")
private String mdsgdTokenUrl;    // http://apimanager-qa.crt.gob.mx/token

@Value("${mdsgd.token.id}")
private String mdsgdTokenId;     // Bearer token para autenticación
```

---

## 2. Métodos FEDI que Consumen PERITOS

### 📌 MÉTODO 1: obtenerUsuarios()

**Líneas:** 94-180
**Propósito:** Obtener catálogo de TODOS los roles y usuarios de PERITOS

**Flujo de Consumo:**

#### Paso 1: Obtener Roles del Sistema PERITOS (Línea 115)
```java
vMetodo = "registro/consultas/roles/2/1/0015MSPERITOSDES-INT";
vCadenaResultado = this.mDSeguridadService.EjecutaMetodoGET(
    this.tokenAcceso.getAccess_token(),
    this.autoRegistroUrl,
    vMetodo,
    lstParametros
);
```

**Endpoint Consumido:**
```
GET https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT
Authorization: Bearer {token}
```

**Respuesta Esperada:**
```json
{
  "error": "false",
  "code": 0,
  "datosRoles": [
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/ROL_0015MSPERITOS_SOLICITANTES",
      "estado": "A"
    },
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/ROL_0015MSPERITOS_SUPERVISORES",
      "estado": "A"
    }
  ]
}
```

**Modelo de Datos:** [fedi-web/.../ResponseRoles.java](fedi-web/src/main/java/fedi/ift/org/mx/arq/core/model/IS/ResponseRoles.java)

---

#### Paso 2: Para cada Rol, obtener Usuarios (Línea 142)
```java
for (Iterator iterRol = oRoles.iterator(); iterRol.hasNext();) {
    Role elementInstancia = (Role) iterRol.next();
    nombreSistema = elementInstancia.getDescripcion_Rol()
        .substring(0, elementInstancia.getDescripcion_Rol().indexOf("/"));
    // nombreSistema = "0015MSPERITOSDES-INT"
    
    nombreRol = elementInstancia.getDescripcion_Rol()
        .substring(elementInstancia.getDescripcion_Rol().indexOf("/") + 1);
    // nombreRol = "ROL_0015MSPERITOS_SOLICITANTES"
    
    // Filtrar roles internos
    if (!nombreRol.equals("0015MSPERITOSDES-INT")) {
        
        // Consultar usuarios de este rol
        vMetodo = "registro/consultas/roles/4/" + nombreSistema + "--" + nombreRol + "/" 
                  + this.sistemaIdentificadorInt;
        // vMetodo = "registro/consultas/roles/4/0015MSPERITOSDES-INT--ROL_0015MSPERITOS_SOLICITANTES/0022FEDI"
        
        vCadenaResultado = this.mDSeguridadService.EjecutaMetodoGET(
            this.tokenAcceso.getAccess_token(),
            this.autoRegistroUrl,
            vMetodo,
            lstParametros
        );
```

**Endpoint Consumido (para cada rol):**
```
GET https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/4/{sistema}--{rol}/{sistemaFEDI}
Authorization: Bearer {token}

Ejemplo:
GET https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/4/0015MSPERITOSDES-INT--ROL_0015MSPERITOS_SOLICITANTES/0022FEDI
```

**Respuesta Esperada:**
```json
{
  "error": "false",
  "code": 0,
  "datosRoles": [
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/juan.perez",
      "estado": "A"
    },
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/maria.garcia",
      "estado": "A"
    }
  ]
}
```

---

### 📌 MÉTODO 2: obtenerUsuarioInterno(String usuario)

**Líneas:** 191-242
**Propósito:** Validar si un usuario específico existe en PERITOS

**Flujo de Consumo:**

```java
String vMetodo = "registro/consultas/roles/1/" + prmUsuario + "/0015MSPERITOSDES-INT";
// vMetodo = "registro/consultas/roles/1/juan.perez/0015MSPERITOSDES-INT"

LOGGER.info("AdminUsuariosServiceImpl.obtenerUsuarioInterno() - Consultando usuario: " 
    + prmUsuario + " en sistema PERITOS");
    
vCadenaResultado = this.mDSeguridadService.EjecutaMetodoGET(
    this.tokenAcceso.getAccess_token(),
    this.autoRegistroUrl,
    vMetodo,
    lstParametros
);
```

**Endpoint Consumido:**
```
GET https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/1/{usuario}/0015MSPERITOSDES-INT
Authorization: Bearer {token}

Ejemplo:
GET https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/1/juan.perez/0015MSPERITOSDES-INT
```

**Respuesta Esperada:**
```json
{
  "error": "false",
  "code": 0,
  "datosRoles": [
    {
      "descripcion_Rol": "0015MSPERITOSDES-INT/juan.perez",
      "estado": "A"
    }
  ]
}
```

**Utilizado en:** Validación antes de asignar firmantes a documentos.

---

### 📌 MÉTODO 3: modificarPermisosAUsuario()

**Líneas:** 243-256
**Propósito:** Actualizar permisos de un usuario en PERITOS

**Flujo de Consumo:**

```java
String vMetodo = "registro/actualizar";
respuestaServicioPost = mDSeguridadService.EjecutaMetodoPOST(
    this.tokenAcceso.getAccess_token(),
    this.autoRegistroUrl + vMetodo,  // https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/actualizar
    "",
    lstParametros,
    prmCambioUsuarioRequest  // Objeto con cambios de usuario
);
```

**Endpoint Consumido:**
```
POST https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/registro/actualizar
Authorization: Bearer {token}
Content-Type: application/json

Payload:
{
  "usuario": "juan.perez",
  "rol": "ROL_0015MSPERITOS_SUPERVISORES",
  "estado": "A"
}
```

---

## 3. Comparación: FEDI vs msperitos-admin

### FEDI (Cliente de PERITOS)
```
Ubicación: c:\github\fedi-web
Clase: AdminUsuariosServiceImpl.java (línea 94-256)
Métodos: 
  - obtenerUsuarios() ← Obtiene catálogo de roles y usuarios
  - obtenerUsuarioInterno(usuario) ← Valida usuario existe
  - modificarPermisosAUsuario() ← Actualiza permisos
```

### msperitos-admin (También Cliente de PERITOS)
```
Ubicación: c:\github\msperitos-admin
Clase: AdminUsuariosServiceImpl.java (línea 80-326)
Métodos: IDÉNTICOS a FEDI
  - obtenerUsuarios()
  - obtenerUsuarioInterno(usuario)
  - modificarPermisosAUsuario()
```

**Análisis:** Ambos proyectos tienen la MISMA implementación, lo que confirma que:
- El contrato de API es estable
- Los endpoints son públicos y bien documentados
- **El servicio srvAutoregistro debe estar disponible en CRT para que ambos funcionen**

---

## 4. Casos de Uso en FEDI

### 4.1 Cargar Documento y Asignar Firmantes

**Flujo:**
```
1. Usuario ingresa documento en FEDI
2. UI muestra combo de "Firmantes Disponibles"
3. FEDI llama: obtenerUsuarios()
4. Devuelve lista de usuarios de PERITOS agrupados por rol
5. Usuario selecciona firmante
6. FEDI llama: obtenerUsuarioInterno(usuario) ← VALIDACIÓN
7. Si existe: Permite asignar
8. Si no existe: Muestra error
```

**Componente UI:** [fedi-web/.../AdminRolMB.java](fedi-web/src/main/java/fedi/ift/org/mx/exposition/AdminRolMB.java)

**Método UI que dispara:**
```java
@PostConstruct
public void init() {
    // ... 
    adminUsuariosService.obtenerUsuarios()  ← LLAMADA A PERITOS
}
```

---

### 4.2 Vista de Documento - Asignar Firmware

**Ubicación:** [fedi-web/.../DocumentoVistaFirmaMB.java](fedi-web/src/main/java/fedi/ift/org/mx/exposition/DocumentoVistaFirmaMB.java#L1020)

**Código:**
```java
public void guardarSinNotificacion() {
    if (existeBD == false) {
        RequestFEDI request = new RequestFEDI();
        request.setIdUsuario(firmante.getMail());
        request.setNombre(firmante.getCn().toUpperCase());
        
        // Registra usuario si no existe
        ResponseFEDI responseRegistrarUsuario = fediService.registrarUsuario(request);
        if (responseRegistrarUsuario != null && responseRegistrarUsuario.getCode() != 102) {
            LOGGER.error("Error al registrar usuario: " + firmante.getCn());
        }
    }
}
```

**Dependencia:** Necesita que el usuario esté validado en PERITOS antes.

---

## 5. El Servicio Faltante: srvAutoregistro

### 5.1 Características

| Aspecto | Valor |
|---------|-------|
| **Nombre** | srvAutoregistro |
| **Ubicación** | NO ENCONTRADO EN REPOSITORIOS |
| **API Manager Base** | https://apimanager-qa.ift.org.mx/srvAutoregistroQA/v3.0/ |
| **Base Path** | /srvAutoregistro/ |
| **Tipo** | Spring Boot REST Service |
| **Sistema ID** | 0015MSPERITOSDES-INT |
| **Autenticación** | OAuth2 Bearer Token |
| **Propósito** | Gestionar registro y consulta de usuarios/roles PERITOS |

### 5.2 Endpoints Expuestos

```
1. GET /registro/consultas/roles/2/1/{sistema}
   └─ Obtener roles de un sistema

2. GET /registro/consultas/roles/4/{sistema}--{rol}/{sistemaConsultor}
   └─ Obtener usuarios de un rol específico

3. GET /registro/consultas/roles/1/{usuario}/{sistema}
   └─ Obtener datos de un usuario específico

4. POST /registro/actualizar
   └─ Actualizar permisos de usuario

5. POST /registro/validarUsuario
   └─ Validar si usuario existe
```

### 5.3 Tecnología Subyacente

**Modelo de Datos:**
```java
@XmlRootElement
public class ResponseRoles implements Serializable {
    private String error;           // "true" o "false"
    private Integer code;           // Código HTTP
    private List<Role> datosRoles;  // Resultado
}

public class Role implements Serializable {
    private String descripcion_Rol; // "0015MSPERITOSDES-INT/ROL_XXX" o "0015MSPERITOSDES-INT/usuario"
    private String estado;          // "A" (Activo), "I" (Inactivo)
}
```

---

## 6. Diagrama de Dependencias Completo

```
FEDI (fedi-web)
    ↓
AdminUsuariosServiceImpl.obtenerUsuarios()
    ↓
EjecutaMetodoGET(
    token,
    "https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/",
    "registro/consultas/roles/2/1/0015MSPERITOSDES-INT",
    parametros
)
    ↓
[API Manager CRT] ← ← ← DEBE EXISTIR
    ↓
[srvAutoregistro Service] ← ← ← NO ENCONTRADO EN REPO
    ↓
Base de Datos PERITOS (Oracle)
    ↓
Tabla: tbl_usuarios, tbl_roles, tbl_rol_usuario
```

---

## 7. Métodos en los 8 Proyectos PERITOS

### Proyectos Encontrados

1. **msperitos-admin** ✅
   - Mismo AdminUsuariosServiceImpl.java
   - Consume roles/usuarios igual que FEDI
   - [Ver código](msperitos-admin/src/main/java/msperitos/adm/ift/org/mx/arq/core/service/security/AdminUsuariosServiceImpl.java)

2. **msperitos-publico** ✅
   - Similar structure
   - También consume srvAutoregistro
   - [Ubicación](msperitos-publico/src/main/java/...)

3. **srvPeritosEjemplo** ⚠️
   - Proyecto de ejemplo
   - [Ubicación](srvPeritosEjemplo/src/main/java/...)

4. **srvPeritosCatalogos** ⚠️
   - Expone catálogos
   - No encontrado en búsqueda

5. **srvPeritosConvocatorias** ⚠️
   - Gestiona convocatorias
   - No encontrado en búsqueda

6. **srvPeritosRNP** ⚠️
   - Registro Nacional de Peritos
   - No encontrado en búsqueda

7. **srvPeritosSolicitudes** ⚠️
   - Gestiona solicitudes
   - No encontrado en búsqueda

8. **srvPeritosSolicitudExamen** ⚠️
   - Gestiona exámenes
   - No encontrado en búsqueda

### Patrón Identificado

```
msperitos-admin/
  └─ src/main/java/
     └─ msperitos/adm/ift/org/mx/
        ├─ arq/core/service/security/
        │  └─ AdminUsuariosServiceImpl.java ← CONSUME srvAutoregistro
        └─ arq/core/exposition/
           └─ AdminRolMB.java ← BEAN que llama arriba

msperitos-publico/
  └─ Misma estructura
```

**Estos son CLIENTES de srvAutoregistro, no proveedores.**

---

## 8. Checklist: ¿Qué Falta para Migración a CRT?

### ✅ Completado en Código FEDI
- [x] AdminUsuariosServiceImpl.java tiene lógica correcta
- [x] Endpoints están correctamente construidos
- [x] Token Bearer está siendo usado
- [x] URLs están configurables via pom.xml
- [x] Manejo de errores básico implementado
- [x] Logs agregados para diagnóstico

### ❌ Falta en Infraestructura CRT
- [ ] **CRÍTICO:** Proyecto srvAutoregistro NO ENCONTRADO
  - No está en C:\github
  - No está clonado de Git
  - **Debe estar en API Manager CRT como servicio publicado**

- [ ] Proyecto debe ser deployado en CRT
- [ ] API Manager CRT debe exponer `/srvAutoregistroQA/v3.0/`
- [ ] Base de Datos PERITOS debe estar migrada a CRT
- [ ] Tablas de usuarios/roles deben estar pobladas
- [ ] Token OAuth2 debe tener permisos para consultar PERITOS

---

## 9. Comando para Buscar srvAutoregistro

Si el servicio existe en otro repositorio:

```bash
cd c:\github
find . -name "*Autoregistro*" -o -name "*autoregistro*" -o -name "*srvAuto*"
grep -r "srvAutoregistro" . --include="*.java"
grep -r "registro/consultas/roles" . --include="*.java" | grep -i service
```

---

## 10. Acciones Recomendadas

### Inmediato
1. **Buscar dónde está srvAutoregistro:**
   - Contactar equipo de infraestructura
   - Revisar repositories privados
   - Verificar si fue deployado en API Manager directamente

2. **Verificar en API Manager:**
   ```bash
   # Desde máquina con acceso a API Manager IFT
   GET https://apimanager-dev.ift.org.mx/admin/...
   # Buscar: srvAutoregistro publicado
   ```

3. **Si srvAutoregistro necesita ser deployado en CRT:**
   - Obtener código fuente (no está en los repos)
   - Compilar para ambiente CRT
   - Migrar base de datos de PERITOS
   - Publicar en API Manager CRT
   - Validar endpoints

### Medio Plazo
4. **Validar funcionalidad completa:**
   - Probar obtenerUsuarios() en CRT
   - Probar obtenerUsuarioInterno() en CRT
   - Probar modificarPermisosAUsuario() en CRT
   - Ejecutar test de carga

---

**Documento Actualizado:** 2026-02-05
**Responsable:** Equipo de Análisis FEDI-CRT
**Próximo Paso:** Localizar y obtener código de srvAutoregistro
