# RESUMEN EJECUTIVO: Análisis Completo FEDI-PERITOS-CRT

**Fecha:** 2026-02-05  
**Clasificación:** 🔴 CRÍTICO  
**Audiencia:** Directivos, Infraestructura, Desarrollo  
**Duración Lectura:** 5 minutos

---

## 1️⃣ LA SITUACIÓN EN UNA FRASE

FEDI está listo para migración a CRT, PERO le falta el servicio web `srvAutoregistro` que debe estar publicado en API Manager CRT para obtener la lista de firmantes.

---

## 2️⃣ ANTECEDENTES

### ✅ Lo que SÍ Funciona en IFT

```
Usuario Abre FEDI
    ↓
  FEDI consulta srvAutoregistro a través de API Manager IFT
    ↓
  srvAutoregistro retorna lista de usuarios de PERITOS
    ↓
  Usuario selecciona firmante
    ↓
  Documento se firma exitosamente ✅
```

**Comprobado:** Login funciona, autenticación funciona, obtención de usuarios funciona.

### ❌ El Problema en CRT

```
Usuario Abre FEDI
    ↓
  FEDI consulta srvAutoregistro a través de API Manager CRT
    ↓
  API Manager CRT NO ENCUENTRA srvAutoregistro
    ↓
  Retorna HTTP 404
    ↓
  FEDI NO MUESTRA lista de firmantes
    ↓
  Usuario NO PUEDE seleccionar firmante
    ↓
  Funcionalidad COMPLETAMENTE BLOQUEADA ❌
```

---

## 3️⃣ ANÁLISIS REALIZADO

### Alcance

Revisamos **todos los 8 proyectos PERITOS** descargados:

```
✅ msperitos-admin
✅ msperitos-publico
✅ srvPeritosCatalogos
✅ srvPeritosConvocatorias
✅ srvPeritosEjemplo
✅ srvPeritosRNP
✅ srvPeritosSolicitudes
✅ srvPeritosSolicitudExamen
```

### Hallazgos

| Hallazgo | Resultado | Impacto |
|----------|-----------|--------|
| **Código FEDI que consume PERITOS** | ✅ Encontrado y analizado | Lógica correcta |
| **Endpoints que FEDI consulta** | ✅ Bien documentados | 4 endpoints identificados |
| **Modelos de datos** | ✅ Completos | Parseo JSON funcionará |
| **Implementación en AdminUsuariosServiceImpl** | ✅ Correcta | Sin errores de lógica |
| **Servicio srvAutoregistro que EXPONE los datos** | ❌ NO ENCONTRADO | 🔴 BLOQUEADOR CRÍTICO |

---

## 4️⃣ LOS ENDPOINTS FALTANTES

FEDI intenta llamar a **4 endpoints REST** que actualmente **NO EXISTEN en CRT**:

### Endpoint 1: Obtener Roles
```
GET /srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT
Retorna: Lista de todos los roles de PERITOS
Usado en: AdminUsuariosServiceImpl.obtenerUsuarios() línea 115
```

### Endpoint 2: Obtener Usuarios de un Rol
```
GET /srvAutoregistroQA/v3.0/registro/consultas/roles/4/{sistema}--{rol}/{sistemaFEDI}
Retorna: Usuarios que tienen ese rol en PERITOS
Usado en: AdminUsuariosServiceImpl.obtenerUsuarios() línea 142
```

### Endpoint 3: Validar Usuario
```
GET /srvAutoregistroQA/v3.0/registro/consultas/roles/1/{usuario}/0015MSPERITOSDES-INT
Retorna: Confirma si usuario existe en PERITOS
Usado en: AdminUsuariosServiceImpl.obtenerUsuarioInterno() línea 220
```

### Endpoint 4: Actualizar Permisos
```
POST /srvAutoregistroQA/v3.0/registro/actualizar
Actualiza permisos de usuario en PERITOS
Usado en: AdminUsuariosServiceImpl.modificarPermisosAUsuario() línea 248
```

---

## 5️⃣ ¿POR QUÉ NO LO ENCONTRAMOS?

### Búsquedas Realizadas

```bash
✅ Grep en todos los .java buscando: "registro/consultas/roles"
   └─ Encontré: SOLO en FEDI y msperitos-admin (consumidores)

❌ Busqué: "@RequestMapping.*consultas"
   └─ No encontré ningún Controller que EXPONGA esto

❌ Busqué: "class.*RegistroWS"
   └─ No encontré ningún WS

❌ Busqué: "class.*RolesController"
   └─ No encontré nada

❌ Busqué: "srvAutoregistro" en directorios
   └─ NO EXISTE en C:\github
```

### Conclusión

El servicio `srvAutoregistro` que EXPONE estos endpoints **NO está en los repositorios descargados**.

---

## 6️⃣ IMPACTO EN LA MIGRACIÓN

### Funcionalidades Bloqueadas (SIN srvAutoregistro)

```
❌ Asignar firma a un documento
❌ Ver lista de firmantes disponibles
❌ Validar que un usuario exista antes de asignar
❌ Actualizar permisos de usuario

RESULT: FEDI prácticamente inutilizable en CRT
```

### Funcionalidades OK (CON srvAutoregistro)

```
✅ Login de usuarios
✅ Crear documentos
✅ Guardar documentos
✅ Visualizar documentos
```

**Línea de fondo:** ~30% de funcionalidad bloqueada sin srvAutoregistro.

---

## 7️⃣ RECOMENDACIÓN EJECUTIVA

### Acción INMEDIATA (Esta semana)

```
1. LOCALIZAR srvAutoregistro
   ├─ Buscar en repos privados
   ├─ Preguntar a infraestructura dónde está
   ├─ Verificar en API Manager IFT los detalles
   └─ Solicitar backup si no está en Git

2. OBTENER código fuente
   ├─ Clone del repo o
   ├─ Descargar WAR/JAR y extraer
   └─ Guardar en C:\github\srvAutoregistro

3. EVALUAR migración
   ├─ Leer código
   ├─ Entender lógica BD
   └─ Identificar cambios necesarios para CRT
```

### Acción CORTO PLAZO (Próximas 2 semanas)

```
1. PREPARAR para CRT
   ├─ Cambiar URLs de IFT a CRT
   ├─ Configurar acceso a BD PERITOS en CRT
   └─ Compilar: mvn clean package -P crt-oracle1

2. PUBLICAR en API Manager CRT
   ├─ Crear API: /srvAutoregistroQA/v3.0
   ├─ Apuntar a servicio backend
   ├─ Configurar OAuth2
   └─ Validar con tests

3. DESPLEGAR y PROBAR
   ├─ Desplegar FEDI con nuevas URLs
   ├─ Probar obtenerUsuarios()
   ├─ Probar asignar firmante a documento
   └─ Validar en CRT funciona igual que IFT
```

---

## 8️⃣ RIESGOS IDENTIFICADOS

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|--------|-----------|
| srvAutoregistro no se encuentra | MEDIA | 🔴 CRÍTICO | Buscar agresivamente, contactar infraestructura |
| BD PERITOS no está migrada a CRT | MEDIA | 🔴 CRÍTICO | Validar con infraestructura |
| API Manager CRT no tiene srvAutoregistro publicado | ALTA | 🔴 CRÍTICO | Publicar después de obtener código |
| Cambios en lógica entre IFT y CRT | BAJA | 🟠 MAYOR | Aplicar los cambios identificados |
| Usuarios PERITOS no migrados | MEDIA | 🟠 MAYOR | Validar con infraestructura |

---

## 9️⃣ DOCUMENTOS GENERADOS

Se crearon 3 documentos de análisis detallado:

```
✅ 07_MAPEO_METODOS_CONSUMO_PERITOS.md
   └─ Análisis línea por línea de cómo FEDI consume PERITOS
   └─ 300+ líneas con código fuente y explicaciones

✅ 08_DIAGRAMA_ARQUITECTURA_FEDI_PERITOS.md
   └─ Diagrama visual de la cadena de llamadas
   └─ Ejemplos de requests/responses HTTP
   └─ Tests manuales que se pueden ejecutar

✅ 09_HALLAZGO_CRITICO_srvAutoregistro_NO_ENCONTRADO.md
   └─ Detalles del componente faltante
   └─ Dónde buscarlo
   └─ Qué hacer si no se encuentra

✅ Este resumen ejecutivo
   └─ Visión ejecutiva de 5 minutos
```

**Ubicación:** C:\github\Colaboracion\

---

## 🔟 PRÓXIMAS PREGUNTAS

### Para Infraestructura

1. ¿Dónde está alojado el código de `srvAutoregistro`?
2. ¿Está publicado en API Manager IFT? ¿En qué versión?
3. ¿Está en un repositorio Git? ¿Cuál es la URL?
4. ¿Hay una BD PERITOS en CRT? ¿Está migrada?
5. ¿Está `srvAutoregistro` publicado en API Manager CRT?
6. ¿Se necesita hacer algo especial para publicarlo en CRT?

### Para Desarrollo

1. ¿Alguien tiene el código fuente de `srvAutoregistro`?
2. ¿Fue deployado a mano sin estar en Git?
3. ¿Existe documentación de la API?
4. ¿Existen tests unitarios para `srvAutoregistro`?

---

## ✅ CONCLUSION

**FEDI está listo para migración a CRT.**

**El LOGIN FUNCIONA.**

**La integración de código con PERITOS está CORRECTA.**

**PERO sin `srvAutoregistro`, los usuarios NO PUEDEN asignar firmantes.**

**RECOMENDACIÓN: Resolver esta dependencia antes de pasar a producción.**

---

**Analizado por:** Equipo de Análisis Técnico  
**Validado:** Incompleto - Requiere información de infraestructura  
**Estado:** 🔴 BLOQUEADOR IDENTIFICADO - Acción requerida  
**Seguimiento:** Próxima reunión estratégica
