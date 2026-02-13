# ⚠️ HALLAZGO CRÍTICO: Servicio srvAutoregistro NO ENCONTRADO

**Fecha:** 2026-02-05  
**Criticidad:** 🔴 BLOQUEADOR TOTAL  
**Estado:** INVESTIGACIÓN EN CURSO

---

## Resumen Ejecutivo

Durante el análisis de los 8 proyectos de PERITOS descargados, se identificó que:

✅ **FEDI y msperitos-admin consumen correctamente**  
✅ **Los endpoints están bien documentados**  
✅ **La lógica de integración es correcta**  

❌ **PERO... El servicio que EXPONE esos endpoints NO está en el repositorio**  
❌ **NO está publicado en API Manager CRT**  
❌ **Esto bloquea COMPLETAMENTE la funcionalidad de asignar firmantes**

---

## El Problema en una Frase

> FEDI y los proyectos PERITOS están programados para **consumir** un servicio REST llamado `srvAutoregistro`, pero ese servicio **no existe en los repos descargados** y **no está publicado en API Manager CRT**.

---

## 📍 Dónde Está el Problema

### Consumidores Identificados (SÍ EXISTEN):

```
✅ FEDI
   └─ AdminUsuariosServiceImpl.java
      ├─ obtenerUsuarios()              línea 94-180
      ├─ obtenerUsuarioInterno()        línea 191-242
      └─ modificarPermisosAUsuario()    línea 243-256

✅ msperitos-admin
   └─ AdminUsuariosServiceImpl.java
      ├─ obtenerUsuarios()              línea 80-150
      ├─ obtenerUsuarioInterno()        línea 215-260
      └─ modificarPermisosAUsuario()    línea 280-295
```

### Proveedor NO ENCONTRADO (NO EXISTE):

```
❌ srvAutoregistro (?)
   └─ Controlador REST @RequestMapping("/registro")
      ├─ GET /consultas/roles/2/1/{sistema}          ← FALTA
      ├─ GET /consultas/roles/4/{sistema}--{rol}/{sistemaConsultor}  ← FALTA
      ├─ GET /consultas/roles/1/{usuario}/{sistema}  ← FALTA
      ├─ POST /actualizar                            ← FALTA
      └─ POST /validarUsuario                        ← FALTA
```

---

## 🔍 Búsqueda Exhaustiva

### Directorios Descargados (8 Proyectos PERITOS):

```
c:\github\msperitos-admin\
c:\github\msperitos-publico\
c:\github\srvPeritosCatalogos\
c:\github\srvPeritosConvocatorias\
c:\github\srvPeritosEjemplo\
c:\github\srvPeritosRNP\
c:\github\srvPeritosSolicitudes\
c:\github\srvPeritosSolicitudExamen\
```

### Búsquedas Realizadas:

```bash
# ❌ Sin resultados
grep -r "registro/consultas/roles" . --include="*Controller*"
grep -r "registro/consultas/roles" . --include="*WS*"
grep -r "@RequestMapping.*consultas" . --include="*.java"
grep -r "class.*RegistroWS" . --include="*.java"
grep -r "class.*RolesController" . --include="*.java"

# ✅ SÍ encontró
grep -r "registro/consultas/roles" . --include="*.java"
# Resultado: SOLO en código CONSUMIDOR (FEDI y msperitos-admin)
```

### Conclusión:

**El código que EXPONE los endpoints `registro/consultas/roles/` NO EXISTE en los repos descargados.**

---

## 🗂️ Estructura de Proyectos PERITOS Encontrada

### msperitos-admin (Típico)

```
msperitos-admin/
├── pom.xml
├── src/main/java/
│   └── msperitos/adm/ift/org/mx/
│       ├── arq/core/
│       │   ├── exposition/           ← Managed Beans (MB) - UI
│       │   │   ├── AdminRolMB.java
│       │   │   └── LoginMB.java
│       │   ├── service/
│       │   │   ├── security/
│       │   │   │   ├── AdminUsuariosServiceImpl.java ← CONSUMIDOR ✅
│       │   │   │   └── AuthenticationServiceImpl.java
│       │   │   └── bitacora/
│       │   └── model/
│       │       ├── IS/
│       │       │   ├── ResponseRoles.java
│       │       │   ├── ResponseUsuario.java
│       │       │   ├── ResponseUsuarios.java
│       │       │   └── Role.java
│       │       └── Usuario.java
│       └── model/
│           └── Rol.java
└── target/
```

**Patrón:** Todos son CONSUMIDORES de API, NO PROVEEDORES de REST endpoints.

---

## 🎯 Puntos de Consumo en FEDI

### 1. AdminRolMB.java (Managed Bean)

```java
@Controller
@Scope("session")
public class AdminRolMB {
    @Autowired
    private AdminUsuariosService adminUsuariosService;  // ← Inyecta service
    
    @PostConstruct
    public void init() {
        // ... llama directamente al service
        adminUsuariosService.obtenerUsuarios();  ← HACE LA LLAMADA
    }
}
```

**UI que dispara:** Cuando se carga la página de asignar firmantes.

### 2. DocumentoVistaFirmaMB.java

```java
public void guardarSinNotificacion() {
    // ... obtiene lista de usuarios
    this.observadores = adminRolMB.getObservadores();  ← USA DATOS DE AdminRolMB
}
```

**UI que dispara:** Cuando se guarda documento con firmantes asignados.

### 3. FirmaDocumentosMB.java

```java
public void cargarFirmantes() {
    // ... probablemente llama a obtenerUsuarios() indirectamente
}
```

**UI que dispara:** Cuando se cargan documentos para firmar.

---

## 💾 Los Datos que FALTA

### ¿Qué endpoint debería retornar?

**Cuando FEDI llama:**
```
GET /srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT
```

**Debería responder (JSON):**
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

**¿De dónde saca esos datos?**
- Base de Datos PERITOS (Oracle)
- Tabla: tbl_usuario_rol
- Tabla: tbl_roles
- Tabla: tbl_usuarios

**¿Quién debe proporcionar esos datos?**
- ❓ No sé. El código srvAutoregistro NO ESTÁ DISPONIBLE.

---

## 🚨 El Impacto en CRT

### Hoy en IFT (FUNCIONA):

```
Usuario abre FEDI
    ↓
FEDI llama: GET /srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT
    ↓
API Manager IFT enruta a srvAutoregistro
    ↓
srvAutoregistro consulta BD PERITOS
    ↓
Retorna roles y usuarios ✅
    ↓
UI muestra combo desplegable "Seleccione Firmante" ✅
```

### En CRT (ROTO):

```
Usuario abre FEDI
    ↓
FEDI llama: GET /srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT
    ↓
API Manager CRT busca ruta /srvAutoregistroQA/v3.0/...
    ↓
NO ENCUENTRA LA RUTA ❌
    ↓
Retorna HTTP 404: Not Found
    ↓
FEDI captura error y no muestra usuarios
    ↓
UI NO muestra combo desplegable ❌
    ↓
Usuario NO PUEDE asignar firmantes ❌
```

**Consecuencia:** Funcionalidad COMPLETAMENTE BLOQUEADA.

---

## 📋 Checklist: Dónde Buscar

- [ ] ¿Existe proyecto `srvAutoregistro` en Git?
  - URL: https://github.com/XXXXX/srvAutoregistro.git (?)
  - Rama: ?
  - Estado: ?

- [ ] ¿Está en PREANALISIS_CPCREL/WAR*?
  - Revisar: `/WAR2026/`, `/WAR2025/`, etc.
  - Buscar: `srvAutoregistro*.war`, `srvAutoregistro*.jar`

- [ ] ¿Está deployado en IFT pero no en código?
  - Preguntar a infraestructura
  - Pedir backup de WAR/JAR original

- [ ] ¿Está en repositorio privado?
  - Contactar administrador GIT
  - Solicitar acceso o copia

- [ ] ¿Se compiló custom para IFT?
  - Pedir documentación de build
  - Solicitar código fuente archivado

---

## ✅ Lo que SÍ está en los repos

```
✅ Interfaces de consumidor
   ├─ fedi-web/AdminUsuariosServiceImpl.java
   └─ msperitos-admin/AdminUsuariosServiceImpl.java

✅ Modelos de datos
   ├─ ResponseRoles.java
   ├─ ResponseUsuario.java
   ├─ ResponseUsuarios.java
   ├─ Role.java
   └─ AdmUsuario.java

✅ UIs que usan los datos
   ├─ AdminRolMB.java
   ├─ DocumentoVistaFirmaMB.java
   └─ FirmaDocumentosMB.java

✅ Service layer que orquesta
   ├─ AdminUsuariosServiceImpl.java
   └─ MDSeguridadServiceImpl.java
```

## ❌ Lo que NO está en los repos

```
❌ El PROVEEDOR de API
   └─ srvAutoregistro (servicio REST desconocido)
      ├─ Controller.java ← FALTA
      ├─ Service.java    ← FALTA
      ├─ DAO.java        ← FALTA
      └─ pom.xml         ← FALTA
```

---

## 🎬 Próximos Pasos

### INMEDIATO (Hoy)

1. **Buscar en PREANALISIS_CPCREL:**
   ```bash
   cd c:\github\PREANALISIS_CPCREL
   find . -name "*srvAuto*" -o -name "*Autoregistro*"
   unzip -l "WAR2026/*.war" | grep -i autoregistro
   ```

2. **Preguntar a infraestructura:**
   - ¿Dónde está srvAutoregistro?
   - ¿Está publicado en API Manager IFT?
   - ¿Está en un repo separado?
   - ¿Es código generado o deployado?

3. **Revisar API Manager IFT:**
   - Entrar a https://apimanager-dev.ift.org.mx
   - Buscar API: "srvAutoregistro"
   - Ver detalles de versión y endponit backend

### CORTO PLAZO (Esta semana)

1. **Si se encuentra srvAutoregistro:**
   - Obtener código fuente
   - Analizarlo
   - Preparar migración a CRT
   - Compilar para CRT
   - Publicar en API Manager CRT

2. **Si NO se encuentra:**
   - Desarrollar srvAutoregistro desde cero basándose en:
     - Especificación de endpoints (ya definida)
     - Modelos de datos (ya existen)
     - Lógica de consultas (se infiere de uso en FEDI)

### MEDIANO PLAZO (Próximas 2 semanas)

1. **Compilar:**
   ```bash
   cd srvAutoregistro (si se encuentra)
   mvn clean package -P crt-oracle1
   ```

2. **Publicar en API Manager CRT:**
   - Crear API en WSO2
   - Apuntar a endpoint backend
   - Configurar OAuth2
   - Activar policies

3. **Desplegar FEDI con nuevas URLs:**
   ```xml
   <!-- pom.xml -->
   <profile.autoregistro.url>https://apimanager-qa.crt.gob.mx/srvAutoregistroQA/v3.0/</profile.autoregistro.url>
   ```

---

## 📊 Resumen de Estado

| Aspecto | Status | Ubicación |
|---------|--------|-----------|
| **Código FEDI** | ✅ Completo | fedi-web/ |
| **Código msperitos-admin** | ✅ Completo | msperitos-admin/ |
| **Otros 6 proyectos PERITOS** | ✅ Descargados | srvPeritos*/ |
| **Modelos de Datos** | ✅ Encontrados | */model/IS/ |
| **Service Layer** | ✅ Encontrado | */service/security/ |
| **UI Components** | ✅ Encontrados | */exposition/ |
| **srvAutoregistro (Proveedor)** | ❌ **NO ENCONTRADO** | **DESCONOCIDO** |

---

## 🎯 Conclusión

**El análisis de los 8 proyectos PERITOS reveló que FEDI y sus dependencias están correctamente integradas, pero la cadena de suministro de datos está ROTA en CRT porque falta el componente que EXPONE los datos: srvAutoregistro.**

**Acción Urgente:** Localizar, obtener y migrar srvAutoregistro a CRT.

---

**Documento:** 07 Mapeo Métodos de Consumo PERITOS  
**Documento:** 08 Diagrama Arquitectura FEDI-PERITOS  
**Estado:** BLOQUEADOR CRÍTICO IDENTIFICADO  
**Requiere:** Acción inmediata del equipo de infraestructura
