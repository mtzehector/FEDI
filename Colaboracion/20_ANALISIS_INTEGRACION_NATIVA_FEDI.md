# 🏗️ ANÁLISIS ARQUITECTÓNICO: Opción de Integración Nativa en FEDI

**Propuesta:** Replicar la lógica de srvAutoRegistroPerito en FEDI-WEB para eliminar dependencia externa

**Fecha Análisis:** 2026-02-06

---

## 1. ANÁLISIS DEL CÓDIGO srvAutoRegistroPerito

### 1.1 Operación 1: Obtener Todos los Roles (tipo=2)

**Código:** [RolesServiceImpl.java](srvAutoRegistroPerito/src/main/java/mx/org/ift/mod/seg/scim/service/RolesServiceImpl.java#L235)

```java
if (tipo == 2) {
    listaDatos = adminStub.getRoleNames();
}
```

**Qué hace:**
- Llama a `RemoteUserStoreManagerServiceStub.getRoleNames()`
- Retorna array de roles del servidor de identidad WSO2
- Luego filtra por `almacen` (prefijo de rol)

**Tecnología:** WSO2 RemoteUserStoreManager Web Service
```java
RemoteUserStoreManagerServiceStub adminStub = new RemoteUserStoreManagerServiceStub(
    configContext, 
    "${ldap.api.scim.login}" + "RemoteUserStoreManagerService"
);
```

**Autenticación:** HTTP Basic Auth con credenciales inyectadas
```java
HttpTransportProperties.Authenticator auth = new HttpTransportProperties.Authenticator();
auth.setUsername(this.usrUIDPeritos);        // ← Parámetro
auth.setPassword(this.usrPWDPeritos);        // ← Parámetro
auth.setPreemptiveAuthentication(true);
```

---

### 1.2 Operación 2: Obtener Usuarios por Rol (tipo=4)

**Código:** [RolesServiceImpl.java](srvAutoRegistroPerito/src/main/java/mx/org/ift/mod/seg/scim/service/RolesServiceImpl.java#L243)

```java
if (tipo == 4) {
    listaDatos = adminStub.getUserListOfRole(filtro.replace("--", "/"));
}
```

**Qué hace:**
- Llamada a `RemoteUserStoreManagerServiceStub.getUserListOfRole(roleName)`
- Retorna usuarios asignados a un rol específico
- Usa la misma autenticación

---

### 1.3 Operación 3: Validar Usuario Existe (tipo=1)

**Código:** [RolesServiceImpl.java](srvAutoRegistroPerito/src/main/java/mx/org/ift/mod/seg/scim/service/RolesServiceImpl.java#L238)

```java
if (tipo == 1) {
    listaDatos = adminStub.listUsers(filtro.replace("--", "/"), 100);
}
```

**Qué hace:**
- Llamada a `RemoteUserStoreManagerServiceStub.listUsers(domain, count)`
- Busca usuarios en un dominio específico
- Parámetro 100 es el máximo de resultados

---

### 1.4 Operación 4: Actualizar Roles (POST)

**Código:** [RolesServiceImpl.java](srvAutoRegistroPerito/src/main/java/mx/org/ift/mod/seg/scim/service/RolesServiceImpl.java#L107-L140)

```java
public ResponseMensaje administraRol(
    String userName, 
    String[] rolesBorrar, 
    String[] rolesAgregar
) throws AppException {
    // ... setup conexión ...
    adminStub.updateRoleListOfUser(userName, rolesBorrar, rolesAgregar);
}
```

**Qué hace:**
- Actualiza roles en WSO2 Identity Server
- Usa RemoteUserStoreManager Web Service

---

## 2. DIAGRAMA DE DEPENDENCIAS: ACTUAL vs PROPUESTO

### Arquitectura ACTUAL (con srvAutoRegistroPerito separado)

```
┌──────────────────┐
│   FEDI-WEB       │
│  (Spring 4.0)    │
│                  │
│ AdminUsuarios    │
│ ServiceImpl       │
└────────┬─────────┘
         │
         │ HTTP REST
         ↓
┌──────────────────────┐
│ API Manager (WSO2)   │
└────────┬─────────────┘
         │
         │ HTTP REST
         ↓
┌──────────────────┐
│ srvAutoregistro  │
│ (Spring 3.1.4)   │
│                  │
│ RolesServiceImpl  │
│ (Jersey 2.14)    │
└────────┬─────────┘
         │
         │ SOAP (Axis2)
         ↓
┌──────────────────────┐
│ WSO2 Identity Server │
│ RemoteUserStoreManager
│ Web Service          │
└──────────────────────┘

PROBLEMAS:
❌ 2 deployments (srvAutoRegistroPerito + FEDI-WEB)
❌ 2 WAR files en WebLogic
❌ Dependencia en cadena (FEDI → API Manager → srvAutoregistro → WSO2)
❌ CRT debe desplegar ambos
❌ Punto de fallo adicional
```

### Arquitectura PROPUESTA (integración nativa)

```
┌──────────────────┐
│   FEDI-WEB       │
│  (Spring 4.0)    │
│                  │
│ AdminUsuarios    │
│ ServiceImpl       │
│         ↓        │
│ RolesService     │
│ (NUEVO)          │
└────────┬─────────┘
         │
         │ SOAP (Axis2) - DIRECTO
         ↓
┌──────────────────────┐
│ WSO2 Identity Server │
│ RemoteUserStoreManager
│ Web Service          │
└──────────────────────┘

VENTAJAS:
✅ 1 deployment (solo FEDI-WEB)
✅ 1 WAR file
✅ Dependencia directa a WSO2 (sin intermediarios)
✅ Menor latencia (sin API Manager)
✅ CRT solo deplega FEDI
✅ Mismo código manejable por equipo FEDI
```

---

## 3. ANÁLISIS TÉCNICO DE VIABILIDAD

### ✅ A FAVOR: Por qué es viable

**3.1 Lógica es simple y reutilizable**
```
Operación 1: getRoleNames()         - 1 línea
Operación 2: getUserListOfRole()    - 1 línea
Operación 3: listUsers()            - 1 línea
Operación 4: updateRoleListOfUser() - 1 línea
Post-procesamiento: filtros         - ~30 líneas
```

**3.2 Sin dependencias de base de datos custom**
- No hace SELECT en tablas srvAutoregistro
- 100% consulta a WSO2 Identity Server
- NO REQUIERE "replicar tablas" de srvAutoregistro
- ✅ Se usa SOLO lo que ya existe en WSO2 CRT

**3.3 Spring 4.0 en FEDI puede invocar Axis2**
```java
// En FEDI ya usa HttpClient (pom.xml):
<dependency>
    <groupId>org.apache.httpcomponents</groupId>
    <artifactId>httpclient</artifactId>
    <version>4.4.1</version>
</dependency>

// Solo faltaría agregar:
<dependency>
    <groupId>org.apache.axis2</groupId>
    <artifactId>axis2-client</artifactId>
    <version>1.8.0</version>  // O compatible con 4.0
</dependency>
```

**3.4 Credenciales disponibles en propiedades**
```java
// Ya en FEDI pom.xml:
<profile.mdsgd.token.url>http://apimanager-qa.ift.org.mx:8280/token</profile.mdsgd.token.url>

// Solo agregar:
<profile.ldap.admin.user>usrUID_peritos</profile.ldap.admin.user>
<profile.ldap.admin.pass>password_peritos</profile.ldap.admin.pass>
<profile.ldap.scim.endpoint>https://identityserver.ift.org.mx:9443/services/</profile.ldap.scim.endpoint>
```

**3.5 Sin cambios a AdminUsuariosServiceImpl**
```java
// AdminUsuariosServiceImpl.java no cambia:
String vMetodo = "registro/consultas/roles/2/1/" + sistemaId;
respuesta = mdSeguridadService.EjecutaMetodoGET(url, vMetodo);

// mdSeguridadService ahora: 
//   Si es HTTP REST → API Manager (para otros métodos)
//   Si es directo WSO2 → llamada SOAP local
```

---

### ❌ EN CONTRA: Desafíos potenciales

**3.1 Overhead de validación de credenciales**
- Cada operación crea conexión SOAP nueva
- ⚠️ Impacto: +2-3ms por operación
- ✅ Mitigación: Cache de conexiones o connection pool

**3.2 Certificado SSL en WSO2**
- Endpoint: `https://identityserver.ift.org.mx:9443/services/`
- ⚠️ Si es self-signed, requiere importar certificado
- ✅ Mitigación: Ya en srvAutoregistro (copiar estrategia)

**3.3 Usuario de servicio LDAP**
- Necesita credenciales con permisos en WSO2
- ⚠️ Que Sean distintas a las de FEDI actual
- ✅ Mitigación: Solicitar a Daniel (nuevas credenciales LDAP en CRT)

**3.4 Cambios en arquitectura futura**
- Si WSO2 cambia arquitectura (migración a Keycloak, etc.)
- ⚠️ Requeriría cambios en FEDI
- ✅ Mitigación: Interface bien definida, fácil de adaptar

---

## 4. REQUISITOS DE INFORMACIÓN A SOLICITAR A DANIEL

Para implementar integración nativa en FEDI, necesitamos:

```
╔═══════════════════════════════════════════════════════════════════╗
║                  INFORMACIÓN REQUERIDA - CRT                     ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  1. WSO2 IDENTITY SERVER                                         ║
║  ─────────────────────────────────────                           ║
║     □ URL Base: https://identityserver-crt.ift.org.mx:9443/     ║
║     □ Usuario de servicio LDAP: ?                               ║
║     □ Contraseña de servicio: ?                                 ║
║     □ Almacén de peritos: 0015MSPERITOSDES-INT (confirmar)     ║
║     □ ¿Certificado SSL self-signed? (SÍ/NO)                    ║
║     □ Si SÍ, ruta del certificado: ?                            ║
║                                                                   ║
║  2. ROLES Y PERMISOS EN WSOOF                                    ║
║  ─────────────────────────────────────                           ║
║     □ Rol prefijo para PERITOS: ? (ej: "PERITOS_*")            ║
║     □ Rol prefijo para FEDI: ? (ej: "FEDI_*")                   ║
║     □ ¿Pueden coexistir permisos de ambos sistemas?            ║
║                                                                   ║
║  3. CONFIGURACIÓN LDAP EN CRT                                    ║
║  ─────────────────────────────────────                           ║
║     □ ¿Active Directory integrado con WSO2?                     ║
║     □ ¿Usuarios importados manualmente o sincronizados?        ║
║     □ Punto de sincronización LDAP ↔ WSO2: ?                   ║
║                                                                   ║
║  4. CARACTERÍSTICAS WSO2                                         ║
║  ─────────────────────────────────────                           ║
║     □ Versión de WSO2 Identity Server: ?                        ║
║     □ ¿Tiene RemoteUserStoreManager habilitado?                ║
║     □ Endpoint SOAP: [...]/services/RemoteUserStoreManagerService
║                                                                   ║
║  5. EQUIVALENTE A USUARIOS DE SERVICIO                           ║
║  ─────────────────────────────────────                           ║
║     □ Usuario actual en IFT: msperitos_admin@msperitos-int....  ║
║     □ Usuario equivalente en CRT: ?                             ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## 5. COMPARATIVA: 3 OPCIONES DE MIGRACIÓN

### Opción A: DESPLEGAR srvAutoRegistroPerito (Original Plan)

**Ventajas:**
- ✅ Migración directa (código ya existe)
- ✅ Sin cambios en FEDI
- ✅ Uso de API Manager (ya consolidado)

**Desventajas:**
- ❌ 2 WAR files en CRT
- ❌ 2 procesos de despliegue
- ❌ Latencia API Manager
- ❌ Equipo FEDI no controla el código

**Esfuerzo CRT:**
- Compilar srvAutoRegistroPerito
- Desplegar WAR
- Crear API en API Manager
- Actualizar FEDI URLs
- **Total: ~2 horas**

**Riesgo:** BAJO (código productivo ya existe)

---

### Opción B: INTEGRACIÓN NATIVA EN FEDI (PROPUESTA USUARIO)

**Ventajas:**
- ✅ 1 WAR file (solo FEDI)
- ✅ Llamada SOAP directa (menor latencia)
- ✅ Equipo FEDI controla el código
- ✅ Elimina dependencia externa
- ✅ Mantenimiento centralizado

**Desventajas:**
- ❌ Cambios en FEDI (agregar dependencias Axis2)
- ❌ Requiere testing adicional
- ❌ Versión Spring 4.0 con Axis2 (validar compatibilidad)

**Esfuerzo CRT:**
- Crear RolesService en FEDI (~3 horas)
- Copiar lógica de RolesServiceImpl (~2 horas)
- Testing integración (~4 horas)
- Desplegar solo FEDI WAR (~30 min)
- **Total: ~9-10 horas**

**Riesgo:** MEDIO (cambios en FEDI, requiere validación)

---

### Opción C: HÍBRIDA - USAR srvAutoregistro COMO LIBRERÍA

**Ventajas:**
- ✅ Código reutilizable (JAR)
- ✅ srvAutoregistro como dependencia Maven
- ✅ 1 WAR (FEDI) pero con capacidades de srvAutoregistro

**Desventajas:**
- ❌ Requiere empaquetar srvAutoregistro como JAR
- ❌ Versionado de dependencias
- ❌ Compleja de mantener

**Esfuerzo CRT:**
- Preparar JAR de srvAutoregistro (~2 horas)
- Agregar como dependencia en FEDI (~1 hora)
- Integración y testing (~4 horas)
- **Total: ~7 horas**

**Riesgo:** MEDIO-ALTO (empaquetado y versionado)

---

## 6. RECOMENDACIÓN: ANÁLISIS COSTE-BENEFICIO

### Matriz de Decisión

| Factor | Opción A | Opción B | Opción C |
|--------|----------|----------|----------|
| **Esfuerzo** | 2h | 10h | 7h |
| **Complejidad** | BAJA | MEDIA | MEDIA-ALTA |
| **Mantenibilidad** | Media (2 servicios) | Alta (1 servicio) | Media |
| **Latencia** | Media (API Manager) | BAJA (directo) | Baja |
| **Riesgo** | Bajo | Medio | Medio-Alto |
| **Escalabilidad** | Buena | Excelente | Buena |
| **Futuro** | srvAutoregistro existe | Integrado en FEDI | Depende de FEDI |

---

### 🎯 MI OPINIÓN (Análisis Técnico)

**Conclusión:** **OPCIÓN B (Integración Nativa) es la mejor a LARGO PLAZO, pero OPCIÓN A es mejor INMEDIATAMENTE.**

#### Recomendación Escalonada:

**FASE 1 (INMEDIATO - CRT Go-Live):** 
- ✅ **Usar Opción A**: Desplegar srvAutoRegistroPerito original
  - Por qué: CRT necesita migración AHORA, no en 2 semanas
  - Menor riesgo, código validado
  - Tiempo: 2 horas vs 10 horas
  - FEDI en CRT funciona de inmediato

**FASE 2 (POST Go-Live - Optimización):**
- 🔄 **Evaluar Opción B**: Si surgen issues con 2 WAR files o latencia
  - Experiencia de usuarios en CRT dirá si vale la pena invertir 10h
  - Código de Opción B será más simple de escribir CON Opción A ya funcionando
  - Menos presión de tiempo

---

## 7. PROPUESTA TÉCNICA DE OPCIÓN B (SI DECIDES IMPLEMENTARLA)

### 7.1 Nuevo archivo: RolesServiceFEDI.java (en FEDI-WEB)

```java
package fedi.ift.org.mx.arq.core.service.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.apache.axis2.client.Options;
import org.apache.axis2.client.ServiceClient;
import org.apache.axis2.context.ConfigurationContext;
import org.apache.axis2.context.ConfigurationContextFactory;
import org.apache.axis2.transport.http.HttpTransportProperties;
import org.wso2.carbon.um.ws.api.stub.RemoteUserStoreManagerServiceStub;
import java.util.ArrayList;
import java.util.List;

@Service("rolesServiceFEDI")
public class RolesServiceFEDI {
    
    @Value("${ldap.scim.endpoint}")
    private String ldapEndpoint;
    
    @Value("${ldap.scim.admin.user}")
    private String adminUser;
    
    @Value("${ldap.scim.admin.password}")
    private String adminPassword;
    
    /**
     * Obtiene todos los roles disponibles en el almacén
     * Equivalente: tipo=2 en srvAutoregistro
     */
    public List<String> obtenerTodosLosRoles(String almacen) throws Exception {
        RemoteUserStoreManagerServiceStub stub = crearStub();
        String[] roles = stub.getRoleNames();
        return filtrarPorAlmacen(roles, almacen);
    }
    
    /**
     * Obtiene usuarios por rol específico
     * Equivalente: tipo=4 en srvAutoregistro
     */
    public List<String> obtenerUsuariosPorRol(String rolName) throws Exception {
        RemoteUserStoreManagerServiceStub stub = crearStub();
        String[] usuarios = stub.getUserListOfRole(rolName.replace("--", "/"));
        return java.util.Arrays.asList(usuarios != null ? usuarios : new String[0]);
    }
    
    /**
     * Valida si usuario existe
     * Equivalente: tipo=1 en srvAutoregistro
     */
    public boolean validarUsuarioExiste(String usuario, String dominio) throws Exception {
        RemoteUserStoreManagerServiceStub stub = crearStub();
        String[] usuarios = stub.listUsers(dominio.replace("--", "/"), 100);
        if (usuarios == null) return false;
        for (String u : usuarios) {
            if (u.equals(usuario)) return true;
        }
        return false;
    }
    
    /**
     * Actualiza roles de usuario
     * Equivalente: POST /actualizar en srvAutoregistro
     */
    public void actualizarRolesUsuario(
        String usuario, 
        String[] rolesBorrar, 
        String[] rolesAgregar
    ) throws Exception {
        RemoteUserStoreManagerServiceStub stub = crearStub();
        stub.updateRoleListOfUser(usuario, rolesBorrar, rolesAgregar);
    }
    
    // ============ PRIVADOS ============
    
    private RemoteUserStoreManagerServiceStub crearStub() throws Exception {
        ConfigurationContext context = 
            ConfigurationContextFactory.createConfigurationContextFromFileSystem(null, null);
        
        String endpoint = ldapEndpoint + "RemoteUserStoreManagerService";
        RemoteUserStoreManagerServiceStub stub = 
            new RemoteUserStoreManagerServiceStub(context, endpoint);
        
        // Configurar autenticación
        ServiceClient client = stub._getServiceClient();
        Options options = client.getOptions();
        options.setProperty("Cookie", null);
        
        HttpTransportProperties.Authenticator auth = 
            new HttpTransportProperties.Authenticator();
        auth.setUsername(adminUser);
        auth.setPassword(adminPassword);
        auth.setPreemptiveAuthentication(true);
        
        options.setProperty("_NTLM_DIGEST_BASIC_AUTHENTICATION_", auth);
        options.setManageSession(true);
        
        return stub;
    }
    
    private List<String> filtrarPorAlmacen(String[] roles, String almacen) {
        List<String> filtrados = new ArrayList<>();
        if (roles != null) {
            for (String rol : roles) {
                if (rol.startsWith(almacen)) {
                    filtrados.add(rol);
                }
            }
        }
        return filtrados;
    }
}
```

### 7.2 Actualizar AdminUsuariosServiceImpl.java

```java
@Autowired
private RolesServiceFEDI rolesServiceFEDI;  // ← AGREGAR

public List<Usuario> obtenerUsuarios() {
    // En lugar de llamar vía HTTP a srvAutoregistro:
    
    // ANTES:
    // String vMetodo = "registro/consultas/roles/2/1/...";
    // List<?> respuesta = mdSeguridadService.EjecutaMetodoGET(...);
    
    // DESPUÉS:
    try {
        List<String> roles = rolesServiceFEDI.obtenerTodosLosRoles("0015MSPERITOSDES-INT");
        // Procesar roles...
    } catch (Exception e) {
        LOGGER.error("Error obteniendo roles", e);
    }
}
```

### 7.3 pom.xml - Agregar dependencias

```xml
<!-- Agregar a FEDI pom.xml -->
<dependency>
    <groupId>org.apache.axis2</groupId>
    <artifactId>axis2-client</artifactId>
    <version>1.8.0</version>
</dependency>

<dependency>
    <groupId>org.wso2.carbon</groupId>
    <artifactId>org.wso2.carbon.um.ws.api</artifactId>
    <version>4.6.0</version>
</dependency>
```

---

## 8. CHECKLIST: INFORMACIÓN NECESARIA PARA DECIDIR

Antes de elegir Opción A o B, completar:

- [ ] ¿Cuál es el timeline crítico de FEDI en CRT?
- [ ] ¿Hay disponibilidad de 10h de desarrollo en las próximas 2 semanas?
- [ ] ¿WSO2 en CRT tiene RemoteUserStoreManager Web Service habilitado?
- [ ] ¿Hay certificados SSL en WSO2 CRT (self-signed o CA)?
- [ ] ¿Equipo FEDI prefiere mantener 1 WAR o 2 WAR?
- [ ] ¿Performance (latencia) es crítica en CRT?

---

## CONCLUSIÓN FINAL

| Aspecto | Veredicto |
|---------|-----------|
| **¿Es viable Opción B (integración nativa)?** | ✅ SÍ, 100% técnicamente viable |
| **¿Es mejor que Opción A (desplegar srvAutoregistro)?** | 🔄 A LARGO PLAZO SÍ, pero CORTO PLAZO NO |
| **¿Qué recomiendo ahora?** | **Opción A** (2h, go-live rápido) + **Opción B** (upgrade futura) |
| **¿Necesita "replicar tablas" como dijiste?** | ❌ NO, uso directo de WSO2 sin base de datos custom |
| **¿Elimina dependencia srvAutoregistro?** | ✅ SÍ, si implementas Opción B |

---

**Próximo Paso:** 
1. Decidir timeline CRT (¿2 semanas o 2 meses?)
2. Solicitar información a Daniel (requerimientos Sección 4)
3. Si timeline es apretado → Opción A
4. Si hay flexibilidad → Opción B (mejor arquitectura)

---

*Análisis técnico completo: 2026-02-06*  
*Autor: GitHub Copilot (evaluación arquitectónica)*
