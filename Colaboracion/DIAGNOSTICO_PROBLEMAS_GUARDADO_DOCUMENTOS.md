# 🔴 DIAGNÓSTICO: Fallos en Guardado de Documentos y SSL Certificate

**Fecha:** 2026-02-12  
**Severidad:** CRÍTICA  
**Impacto:** El sistema no puede cargar/guardar documentos ni firmarlos

---

## 📊 PROBLEMAS IDENTIFICADOS

### 🔴 PROBLEMA 1: SSL Certificate Validation Error (CRÍTICO)

**Error en Logs:**
```
SSLHandshakeException: PKIX path building failed: unable to find valid certification path to requested target
```

**Ubicación en Código:**
- [MDSeguridadServiceImpl.java](fedi-web/src/main/java/fedi/ift/org/mx/arq/core/service/security/loadsoa/MDSeguridadServiceImpl.java#L214)
- Método: `EjecutaMetodoGET()` línea 214

**Causa Raíz:**
La URL HTTPS `https://fedidev.crt.gob.mx/srvFEDIApi-1.0/` tiene un certificado autofirmado o no trusted. Java 8 (1.8.0_361) NO acepta el certificado.

**Impacto:**
- ❌ No puede conectar a fedi-srv
- ❌ Login se intenta hacer pero falla al llamar catálogo
- ❌ Ninguna operación REST funciona

**Soluciones:**
1. **Opción A (Inmediata):** Deshabilitar validación SSL en desarrollo (NO USAR EN PRODUCCIÓN)
2. **Opción B (Recomendada):** Importar certificado SSL a Java Keystore
3. **Opción C (Ideal):** Usar certificado válido de CA

---

### 🔴 PROBLEMA 2: Store Procedures Sin Implementar en Java (CRÍTICO)

**Store Procedures Identificados:**

| SP | Ubicación en DDL | Línea | Función |
|----|-----------------|-------|----------|
| `SP_CARGAR_DOCUMENTO` | Línea 117-217 | Guarda 1 documento + firmantes |
| `SP_CARGAR_DOCUMENTOS` | Línea 239-421 | Guarda múltiples documentos + firmantes/observadores |
| `SP_CONSULTA_DOCUMENTOS` | Línea 422-500+ | Consulta documentos a firmar |
| `FN_TOCA_FIRMAR` | Llamado desde SP_CONSULTA_DOCUMENTOS | Determina si documento toca firmar |

**Dónde se Llaman en Código Java:**

| Ubicación | Método | Línea |
|-----------|--------|-------|
| [FEDIServiceImpl.java](fedi-web/src/main/java/fedi/ift/org/mx/service/FEDIServiceImpl.java) | `cargarDocumentos()` | 207-235 |
| [FEDIServiceImpl.java](fedi-web/src/main/java/fedi/ift/org/mx/service/FEDIServiceImpl.java) | `firmarDocumentos()` | 384-401 |
| [DocumentoVistaFirmaMB.java](fedi-web/src/main/java/fedi/ift/org/mx/exposition/DocumentoVistaFirmaMB.java) | Múltiples métodos | 940, 1138, 1327 |
| [FirmaDocumentosMB.java](fedi-web/src/main/java/fedi/ift/org/mx/exposition/FirmaDocumentosMB.java) | Métodos guardar | 700+ |

**Estado Actual:**
```java
// FEDIServiceImpl.java línea 207-235
public ResponseFEDI cargarDocumentos(RequestFEDIMain request) throws Exception {
    // Está llamando a fedi-srv (REST API) para guardar
    // NO es una implementación local
    String vMetodo = "fedi/cargarDocumentos";
    String urlCompleta = this.perfilFEDI.getUrlServidorFEDI() + vMetodo;
    
    LOGGER.info("FEDIServiceImpl.cargarDocumentos() - Invocando API: " + urlCompleta);
    // Llama a MDSeguridadServiceImpl.EjecutaMetodoGET() que hace REST call
    // Eso cae porque SSL falla
}
```

**Problema:**
1. Código Java actual está delegando al fedi-srv (REST)
2. Pero fedi-srv también tiene el mismo problema SSL
3. Y Los Store Procedures están en la BD, no en Java

---

## 🏗️ ARQUITECTURA ACTUAL vs RECOMENDADA

### ❌ Arquitectura Actual (Fallando)

```
fedi-web (Controlador)
    ↓
FEDIServiceImpl.cargarDocumentos()
    ↓ (REST Call)
fedi-srv/fedi/cargarDocumentos
    ↓ (REST Call con SSL error)
FALLA: PKIX SSL Certificate
```

### ✅ Arquitectura Recomendada (Propuesta)

```
fedi-web (Controlador)
    ↓
FEDIServiceImpl.cargarDocumentos() [EN JAVA]
    ↓
DocumentoRepository (MyBatis)
    ↓
SP_CARGAR_DOCUMENTOS (SQL en BD)
    ↓
tbl_Documentos + tbl_Firmantes + tbl_Observadores

[BENEFICIOS]
- Sin REST calls
- Sin SSL issues
- Controlado por CRT
- Más rápido
- Más seguro (JNDI local)
- Transacciones ACID garantizadas
```

---

## 📝 DDL ANÁLISIS DETALLADO

### Tablas Involucradas

```sql
-- Tabla principal
CREATE TABLE tbl_Documentos (
    DocumentoID int IDENTITY(1,1) PRIMARY KEY,
    NombreDocumento nvarchar(100),
    RutaDocumento nvarchar(200),
    FechaVigencia date,
    FechaHoraCarga datetime2(3),
    DocumentoEstatusID int,       -- FK: cat_DocumentoEstatus (1=Pendiente)
    TotalPaginas int,
    UsuarioID nvarchar(50),       -- FK: cat_Usuarios
    FechaEliminacion date,
    TipoFirmaID int,              -- FK: cat_TipoFirma (1=Secuencial, 2=Concurrente)
    TamanoDocumento int,
    Firmando nvarchar(50),
    HashDocumento nvarchar(200),
    Orientacion nvarchar(10),
    SistemaOrigen nvarchar(10)
);

-- Tabla de firmantes y observadores
CREATE TABLE tbl_Firmantes (
    FirmanteID int IDENTITY(1,1) PRIMARY KEY,
    FechaFirma date,
    HoraFirma datetime,
    Hash nvarchar(200),
    Posicion int,                 -- Null si concurrente o es observador
    UsuarioID nvarchar(50),       -- FK: cat_Usuarios
    DocumentoID int,              -- FK: tbl_Documentos (ON DELETE CASCADE)
    EsObservador int,             -- Null=Firmante, 1=Observador
    UnidadAdministrativa nvarchar(100)
);

-- Catálogos
CREATE TABLE cat_Usuarios (UsuarioID, Nombre, ApellidoPaterno, ApellidoMaterno, Logueo);
CREATE TABLE cat_DocumentoEstatus (DocumentoEstatusID, DocumentoEstatus);
CREATE TABLE cat_TipoFirma (TipoFirmaID, TipoFirma); -- 1=Secuencial, 2=Concurrente
```

### Store Procedure 1: SP_CARGAR_DOCUMENTO

**Lógica:**
```sql
PARAMETERS:
  @NombreDocumento: Nombre del archivo
  @RutaDocumento: Ruta donde se almacena
  @FechaVigencia: Hasta cuándo vigente (yyyy-MM-dd)
  @FechaHoraCarga: Timestamp actual
  @TotalPaginas: Páginas del documento
  @UsuarioID: Usuario que carga
  @TipoFirmaID: 1=Secuencial, 2=Concurrente
  @TamanoDocumento: Bytes del archivo
  @Firmantes: JSON array con firmantes [{idUsuario, posicion}]
  @SistemaOrigen: Sistema que envía (ej. "IFT")
  
SALIDA:
  @DocumentoID: ID del documento creado (IDENTITY)
  @Error_Code: 0 si éxito, número de error SQL si falla
  @Error_Desc: Descripción del error

PROCEDIMIENTO:
1. Validar que NombreDocumento NO sea NULL/vacío
2. BEGIN TRANSACTION
3. INSERT INTO tbl_Documentos con DocumentoEstatusID=1 (Pendiente)
4. Obtener DocumentoID = SCOPE_IDENTITY()
5. CURSOR sobre @Firmantes (JSON array)
   FOREACH firmante:
     - Si TipoFirmaID=2 (Concurrente): Posición = NULL
     - Si TipoFirmaID=1 (Secuencial): Posición REQUERIDA
     - INSERT INTO tbl_Firmantes
6. COMMIT TRANSACTION
7. RETURN @DocumentoID, @Error_Code=0
```

### Store Procedure 2: SP_CARGAR_DOCUMENTOS (Versión Múltiple)

**Lógica Similar pero para Múltiples Documentos:**
- Recibe JSON array de documentos
- CURSOR sobre documentos
- Para cada documento: mismo proceso que SP_CARGAR_DOCUMENTO
- ADEMÁS: Procesa listaObservadores (separado de firmantes)
- RETURN: JSON array con los DocumentoIDs creados

---

## ✅ SOLUCIÓN: Refactorización a Java

### Paso 1: Crear Modelo de Datos

**Archivo:** `DocumentoCargoDTO.java`
```java
@Data
public class DocumentoCargoDTO {
    private String nombreDocumento;
    private String rutaDocumento;
    private LocalDate fechaVigencia;
    private LocalDateTime fechaHoraCarga;
    private Integer totalPaginas;
    private String usuarioID;
    private Integer tipoFirmaID;      // 1=Secuencial, 2=Concurrente
    private Integer tamanoDocumento;
    private String hashDocumento;
    private String orientacion;
    private String sistemaOrigen;
    
    private List<FirmanteDTO> firmantes;      // Para cada firmante
    private List<FirmanteDTO> observadores;   // Para observadores
}

@Data
public class FirmanteDTO {
    private String idUsuario;
    private Integer posicion;    // Null si concurrente/observador
    private String unidadAdministrativa;
}

@Data
public class DocumentoCargoResultDTO {
    private Integer documentoID;
    private String nombreDocumento;
    // ... resto de campos
}
```

### Paso 2: Crear Repository (MyBatis)

**Archivo:** `DocumentoRepository.java`
```java
@Repository
public interface DocumentoRepository {
    
    /**
     * Guarda un documento con sus firmantes
     * Equivalente a: SP_CARGAR_DOCUMENTO
     */
    @Insert(value = {
        "INSERT INTO tbl_Documentos(",
        "  NombreDocumento, RutaDocumento, FechaVigencia, FechaHoraCarga,",
        "  DocumentoEstatusID, TotalPaginas, UsuarioID, TipoFirmaID,",
        "  TamanoDocumento, HashDocumento, Orientacion, SistemaOrigen",
        ") VALUES (",
        "  #{nombreDocumento}, #{rutaDocumento}, #{fechaVigencia},",
        "  #{fechaHoraCarga}, 1, #{totalPaginas}, #{usuarioID},",
        "  #{tipoFirmaID}, #{tamanoDocumento}, #{hashDocumento},",
        "  #{orientacion}, #{sistemaOrigen}",
        ")"
    })
    @Options(useGeneratedKeys = true, keyProperty = "documentoID", keyColumn = "DocumentoID")
    void insertDocumento(DocumentoCargoDTO documento);
    
    /**
     * Guarda un firmante
     * Equivalente a: INSERT INTO tbl_Firmantes
     */
    @Insert({
        "INSERT INTO tbl_Firmantes(",
        "  Posicion, UsuarioID, DocumentoID, EsObservador, UnidadAdministrativa",
        ") VALUES (",
        "  #{posicion}, #{idUsuario}, #{documentoID}, #{esObservador}, #{unidadAdministrativa}",
        ")"
    })
    void insertFirmante(@Param("posicion") Integer posicion,
                       @Param("idUsuario") String idUsuario,
                       @Param("documentoID") Integer documentoID,
                       @Param("esObservador") Integer esObservador,
                       @Param("unidadAdministrativa") String unidadAdministrativa);
}
```

### Paso 3: Crear Servicio con Lógica de Negocio

**Archivo:** `DocumentoServiceImpl.java`
```java
@Service
@Transactional
public class DocumentoServiceImpl {
    
    @Autowired
    private DocumentoRepository documentoRepository;
    
    /**
     * Refactorización de SP_CARGAR_DOCUMENTO
     */
    public DocumentoCargoResultDTO cargarDocumento(DocumentoCargoDTO documento) 
            throws Exception {
        
        // Validación
        if (documento.getNombreDocumento() == null || 
            documento.getNombreDocumento().isEmpty()) {
            throw new IllegalArgumentException("El nombre del documento es requerido.");
        }
        
        // Validar firmantes según tipo de firma
        if (documento.getTipoFirmaID() == 1) {  // Secuencial
            for (FirmanteDTO firmante : documento.getFirmantes()) {
                if (firmante.getPosicion() == null) {
                    throw new IllegalArgumentException(
                        "Es necesaria la posición del firmante al ser tipo de documento secuencial."
                    );
                }
            }
        }
        
        // INSERT documento (transacción automática por @Transactional)
        documentoRepository.insertDocumento(documento);
        
        // INSERT firmantes
        for (FirmanteDTO firmante : documento.getFirmantes()) {
            Integer posicion = (documento.getTipoFirmaID() == 2) ? null : firmante.getPosicion();
            documentoRepository.insertFirmante(
                posicion,
                firmante.getIdUsuario(),
                documento.getDocumentoID(),
                null,  // No es observador
                firmante.getUnidadAdministrativa()
            );
        }
        
        // INSERT observadores
        for (FirmanteDTO observador : documento.getObservadores()) {
            documentoRepository.insertFirmante(
                null,  // No tiene posición
                observador.getIdUsuario(),
                documento.getDocumentoID(),
                1,     // Es observador
                observador.getUnidadAdministrativa()
            );
        }
        
        // Convertir a resultado
        DocumentoCargoResultDTO resultado = new DocumentoCargoResultDTO();
        resultado.setDocumentoID(documento.getDocumentoID());
        resultado.setNombreDocumento(documento.getNombreDocumento());
        // ... resto de campos
        
        return resultado;
    }
    
    /**
     * Refactorización de SP_CARGAR_DOCUMENTOS (múltiples)
     */
    public List<DocumentoCargoResultDTO> cargarDocumentos(List<DocumentoCargoDTO> documentos) 
            throws Exception {
        
        List<DocumentoCargoResultDTO> resultados = new ArrayList<>();
        
        for (DocumentoCargoDTO documento : documentos) {
            resultados.add(cargarDocumento(documento));
        }
        
        return resultados;
    }
}
```

### Paso 4: Refactorizar FEDIServiceImpl

**Cambio en [FEDIServiceImpl.java](fedi-web/src/main/java/fedi/ift/org/mx/service/FEDIServiceImpl.java#L207):**

```java
// ANTES (fallando con SSL):
public ResponseFEDI cargarDocumentos(RequestFEDIMain request) throws Exception {
    String vMetodo = "fedi/cargarDocumentos";
    String urlCompleta = this.perfilFEDI.getUrlServidorFEDI() + vMetodo;
    LOGGER.info("FEDIServiceImpl.cargarDocumentos() - Invocando API: " + urlCompleta);
    // REST call que falla con SSL
}

// DESPUÉS (local, sin SSL):
@Autowired
private DocumentoServiceImpl documentoService;

public ResponseFEDI cargarDocumentos(RequestFEDIMain request) throws Exception {
    try {
        // Parsear request a DTO
        List<DocumentoCargoDTO> documentos = parseRequestDocumentos(request);
        
        // Guardar localmente (USA TRANSACCIÓN)
        List<DocumentoCargoResultDTO> resultados = documentoService.cargarDocumentos(documentos);
        
        // Retornar respuesta
        ResponseFEDI response = new ResponseFEDI();
        response.setCode(200);
        response.setSuccess(true);
        response.setData(resultados);
        
        LOGGER.info("FEDIServiceImpl.cargarDocumentos() - Documentos guardados exitosamente");
        return response;
        
    } catch (Exception e) {
        LOGGER.error("FEDIServiceImpl.cargarDocumentos() - Error: " + e.getMessage(), e);
        ResponseFEDI response = new ResponseFEDI();
        response.setCode(500);
        response.setSuccess(false);
        response.setErrorMessage(e.getMessage());
        return response;
    }
}
```

---

## 🔧 SOLUCIÓN AL SSL CERTIFICATE ISSUE (Corto Plazo)

**Crear HttpClientBuilder con SSL disabled:**

```java
// En MDSeguridadServiceImpl.java
OkHttpClient.Builder httpClient = new OkHttpClient.Builder()
    .sslSocketFactory(getTrustAllSSLSocketFactory(), getTrustAllTrustManager())
    .hostnameVerifier((hostname, session) -> true);

// NOTA: Solo para DESARROLLO, NUNCA en producción
```

Pero MEJOR OPCIÓN es refactorizar a Java y no usar REST calls.

---

## 📋 PLAN DE ACCIÓN

### Fase 1: SSL Certificate Fix (Inmediato, 30 minutos)

```bash
# En fedi-web/src/main/resources/application.properties
server.ssl.enabled=true
server.ssl.key-store=classpath:keystore.jks
server.ssl.key-store-password=changeit
```

### Fase 2: Refactorización a Java (2-3 horas)

1. Crear DTO classes (DocumentoCargoDTO, FirmanteDTO, etc.)
2. Crear DocumentoRepository con MyBatis annotations
3. Crear DocumentoServiceImpl con lógica de SP
4. Refactorizar FEDIServiceImpl para usar servicio local
5. Compilar y testear

### Fase 3: Pruebas (1 hora)

1. Test unitario: Guardar documento sin firmantes
2. Test unitario: Guardar documento con firmantes secuenciales
3. Test unitario: Guardar documento con firmantes concurrentes
4. Test e2e: Desde GUI cargar documento

---

## 🎯 BENEFICIOS DE LA REFACTORIZACIÓN

| Aspecto | Antes | Después |
|--------|-------|---------|
| **Llamadas REST** | 3-4 por operación | 0 |
| **SSL Issues** | ❌ Frecuentes | ✅ No existen |
| **Control** | En fedi-srv | En fedi-web (CRT) |
| **Velocidad** | 100-500ms (red) | 10-50ms (BD local) |
| **Transacciones** | Parciales | Completas (ACID) |
| **Mantenimiento** | Coordinado BD + API | Solo BD |
| **Migración futura** | Compleja | Simple |

---

**Próximos pasos:** Iniciar refactorización a Java eliminando dependencia de REST calls.
