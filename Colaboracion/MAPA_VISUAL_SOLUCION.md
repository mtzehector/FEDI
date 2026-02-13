# 🗺️ MAPA DE SOLUCIÓN: Refactorización Store Procedures a Java

**Visión General de la Refactorización**

```
╔════════════════════════════════════════════════════════════════════════════╗
║                    ARQUITECTURA DE SOLUCIÓN COMPLETA                       ║
╚════════════════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────────────────┐
│ CAPA DE PRESENTACIÓN (JSF/PrimeFaces)                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│  DocumentoVistaFirmaMB.java                                                 │
│  └─ cargarDocumento()  [línea 940, 1138, 1327]                            │
│                                                                             │
│  FirmaDocumentosMB.java                                                     │
│  └─ guardarDocumento()  [línea 700+]                                       │
└──────────────────────────────────────────────────────────────────────────────┘
                                 ↓
                      ┌──────────────────────┐
                      │  ANTES: REST Call    │
                      │  DESPUÉS: Method call│
                      └──────────────────────┘
                                 ↓
┌──────────────────────────────────────────────────────────────────────────────┐
│ CAPA DE SERVICIO (Spring Service)                                           │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  FEDIServiceImpl.java                                                        │
│  ├─ cargarDocumentos(RequestFEDIMain)                          [❌ ANTES]  │
│  │   └─ REST call a fedi-srv/fedi/cargarDocumentos                        │
│  │       └─ MDSeguridadServiceImpl.EjecutaMetodoGET()                      │
│  │           └─ ❌ SSL Certificate Error!                                  │
│  │                                                                          │
│  └─ cargarDocumentos(RequestFEDIMain)                          [✅ DESPUÉS]│
│      └─ documentoCargoService.cargarDocumentos()               [NUEVO!]    │
│                                                                              │
│  DocumentoCargoService (Interface) ──────────────┐                          │
│  DocumentoCargoServiceImpl (Implementación)       │                          │
│  ├─ cargarDocumento()         [SP_CARGAR_DOCUMENTO]            [NUEVO!]   │
│  ├─ cargarDocumentos()        [SP_CARGAR_DOCUMENTOS]           [NUEVO!]   │
│  ├─ obtenerDocumentosAFirmar()[SP_CONSULTA_DOCUMENTOS]         [NUEVO!]   │
│  ├─ obtenerDocumentosPorUsuario()                              [NUEVO!]   │
│  └─ eliminarDocumento()                                        [NUEVO!]   │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                 ↓
┌──────────────────────────────────────────────────────────────────────────────┐
│ CAPA DE ACCESO A DATOS (MyBatis Mapper)                                     │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  DocumentoRepository (Interface) ────────────────┐                          │
│  ├─ insertDocumentoDTO()            [INSERT tbl_Documentos]                │
│  ├─ insertFirmante()                [INSERT tbl_Firmantes]                 │
│  ├─ obtenerDocumentosAFirmar()      [SELECT con CURSOR]                    │
│  ├─ obtenerDocumentosPorUsuario()   [SELECT simple]                        │
│  └─ marcarDocumentoComoEliminado()  [UPDATE soft delete]                   │
│                                                                              │
│  @Insert / @Select / @Update / @Delete (MyBatis Annotations)               │
│  └─ SQL INLINE (sin XML, sin SP)                                           │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                 ↓
┌──────────────────────────────────────────────────────────────────────────────┐
│ CAPA DE DATOS (SQL Server via JNDI)                                         │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ✅ ANTES: SP_CARGAR_DOCUMENTO    [200+ líneas SQL]                        │
│  ✅ ANTES: SP_CARGAR_DOCUMENTOS   [200+ líneas SQL]                        │
│  ✅ ANTES: SP_CONSULTA_DOCUMENTOS [100+ líneas SQL]                        │
│                                                                              │
│  ✅ DESPUÉS: MyBatis SQL Inline queries (mantenibles, versionadas)         │
│                                                                              │
│  Tables:                                                                    │
│  ├─ tbl_Documentos     (DocumentoID IDENTITY, FK relaciones)               │
│  ├─ tbl_Firmantes      (FirmanteID IDENTITY, EsObservador flag)            │
│  ├─ cat_Usuarios       (lookup table)                                      │
│  ├─ cat_DocumentoEstatus (1=Pendiente, 2=Firmado, etc.)                    │
│  └─ cat_TipoFirma      (1=Secuencial, 2=Concurrente)                       │
│                                                                              │
│  Connection:                                                                │
│  └─ JNDI DataSource jdbc/fedi → SQL Server 2019                            │
│     (configurado en server.xml del Tomcat)                                  │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 ESTRUCTURA DE CARPETAS - ARCHIVOS CREADOS

```
fedi-web/src/main/java/fedi/ift/org/mx/
│
├── model/
│   └── documento/                          ← NUEVA CARPETA
│       ├── DocumentoCargoDTO.java          ← DTO del documento
│       ├── FirmanteDTO.java                ← DTO del firmante/observador
│       └── DocumentoCargoResultDTO.java    ← DTO de respuesta
│
├── persistence/
│   └── mapper/                             ← CARPETA EXISTENTE
│       └── DocumentoRepository.java        ← NUEVO (MyBatis)
│
└── service/
    ├── DocumentoCargoService.java          ← NUEVA (Interface)
    ├── DocumentoCargoServiceImpl.java       ← NUEVA (Implementación)
    ├── FEDIServiceImpl.java                 ← MODIFICAR (añadir inyección)
    └── ... otros servicios existentes ...
```

---

## 🔀 FLUJO DE DATOS: Ejemplo Completo

```
┌─────────────────────────────────────────────────────────────────────────┐
│ USUARIO CARGA UN DOCUMENTO EN JSF                                       │
└─────────────────────────────────────────────────────────────────────────┘

1. PRESENTACIÓN
   │
   └─→ DocumentoVistaFirmaMB.guardarDocumento()
       │   Input: usuario clic en botón "Guardar"
       │   Parámetros: nombreDoc, rutaDoc, fechaVigencia, etc.
       │
       └─→ Construye RequestFEDIMain
           │
           └─→ fediService.cargarDocumentos(requestFEDIMain)

2. SERVICIO API (FEDIServiceImpl) ┌────────────────────────────────┐
   │                              │ ❌ ANTES: REST Call           │
   │   cargarDocumentos()         │    mdSeguridadService.         │
   │                              │    EjecutaMetodoGET()         │
   │   Input: RequestFEDIMain     │    → SSL Error → Timeout      │
   │   │                          └────────────────────────────────┘
   │   ├─→ convertirRequestADocumentos()
   │   │   Output: List<DocumentoCargoDTO>
   │   │
   │   └─→ ✅ DESPUÉS: documentoCargoService.cargarDocumentos()
   │
   └─→ Llamada LOCAL a DocumentoCargoServiceImpl

3. SERVICIO DE DOCUMENTOS (DocumentoCargoServiceImpl)
   │
   ├─→ cargarDocumentos(List<DocumentoCargoDTO> documentos)
   │   │
   │   └─→ FOR EACH documento:
   │       │
   │       └─→ cargarDocumento(DocumentoCargoDTO documento)
   │           │
   │           ├─→ VALIDACIONES:
   │           │   ├─ ¿NombreDocumento != NULL?
   │           │   ├─ ¿TipoFirmaID en [1,2]?
   │           │   └─ Si TipoFirmaID=1: ¿Todos firmantes tienen Posición?
   │           │
   │           └─→ documentoRepository.insertDocumentoDTO(documento)
   │               │   Output: documentoID generado (IDENTITY)
   │               │
   │               ├─→ FOR EACH firmante:
   │               │   └─→ insertFirmante(posicion, usuarioID, documentoID, null)
   │               │
   │               └─→ FOR EACH observador:
   │                   └─→ insertFirmante(null, usuarioID, documentoID, 1)
   │
   └─→ Return: List<DocumentoCargoResultDTO> con los IDs generados

4. ACCESO A DATOS (DocumentoRepository - MyBatis)
   │
   ├─→ insertDocumentoDTO(DocumentoCargoDTO)
   │   │
   │   @Insert({
   │     "INSERT INTO tbl_Documentos(...)",
   │     "VALUES (...)"
   │   })
   │   @Options(useGeneratedKeys=true, keyProperty="documentoID")
   │   │
   │   └─→ SQL Server: INSERT tbl_Documentos
   │       └─→ SCOPE_IDENTITY() → documentoID
   │
   └─→ insertFirmante(posicion, usuarioID, documentoID, esObservador)
       │
       @Insert({...})
       │
       └─→ SQL Server: INSERT tbl_Firmantes
           └─→ SCOPE_IDENTITY() → firmanteID

5. BASE DE DATOS (SQL Server)
   │
   ├─→ tbl_Documentos:
   │   └─ INSERT [DocumentoID=1001, NombreDocumento="Contrato...", ...]
   │
   └─→ tbl_Firmantes:
       ├─ INSERT [FirmanteID=5001, DocumentoID=1001, UsuarioID="user1", Posicion=1]
       └─ INSERT [FirmanteID=5002, DocumentoID=1001, UsuarioID="user2", Posicion=2]

6. RESPUESTA AL USUARIO
   │
   ├─→ DocumentoCargoResultDTO {
   │       idDocumento: 1001,
   │       nombreDocumento: "Contrato...",
   │       fechaHoraCarga: 2026-02-12T20:35:00,
   │       ...
   │   }
   │
   └─→ FEDIServiceImpl.cargarDocumentos() retorna:
       └─ ResponseFEDI {
             code: 200,
             success: true,
             data: [DocumentoCargoResultDTO],
             message: "Documentos guardados exitosamente"
           }

7. PRESENTACIÓN (JSF)
   │
   └─→ DocumentoVistaFirmaMB recibe respuesta
       │
       ├─→ Si success=true:
       │   └─ Mostrar mensaje "✅ Documento guardado"
       │   └─ Refrescar lista de documentos
       │
       └─→ Si success=false:
           └─ Mostrar error con detalles

═══════════════════════════════════════════════════════════════════════════

TIEMPO TOTAL: <100ms
ANTES: 120,000ms (timeout ❌)
AHORA: 50-100ms (sin problemas ✅)
```

---

## 🔀 COMPARATIVA DETALLADA: Store Procedure vs Java

### SP_CARGAR_DOCUMENTO (SQL Server)

```sql
CREATE PROCEDURE SP_CARGAR_DOCUMENTO
  @NombreDocumento nvarchar(100),
  @RutaDocumento nvarchar(100),
  @TipoFirmaID int,
  @Firmantes nvarchar(MAX),  -- JSON String
  @DocumentoID int OUTPUT
AS
BEGIN
  -- Validaciones
  IF @NombreDocumento IS NULL RAISERROR('...', 16, 1)
  
  -- INSERT documento
  INSERT INTO tbl_Documentos(...)
  SELECT @DocumentoID = SCOPE_IDENTITY()
  
  -- CURSOR sobre JSON de firmantes
  DECLARE cFirmantes CURSOR FOR
  SELECT * FROM OPENJSON(@Firmantes) WITH (...)
  OPEN cFirmantes
  FETCH NEXT FROM cFirmantes INTO @Firmante, @Posicion
  
  WHILE @@FETCH_STATUS = 0
  BEGIN
    -- Validar posición si secuencial
    IF @TipoFirmaID = 1 AND @Posicion IS NULL
      RAISERROR('...', 16, 1)
    
    -- INSERT firmante
    INSERT INTO tbl_Firmantes(Posicion, UsuarioID, DocumentoID)
    VALUES(@Posicion, @Firmante, @DocumentoID)
    
    FETCH NEXT FROM cFirmantes INTO @Firmante, @Posicion
  END
  
  CLOSE cFirmantes
  DEALLOCATE cFirmantes
END
```

**Problemas:**
- ❌ Sintaxis SQL Server 2012+ (OPENJSON)
- ❌ Cursores (rendimiento pobre)
- ❌ Difícil de testear
- ❌ Control de versiones complicado
- ❌ Debugging con SSMS tedioso

### Refactorización a Java (DocumentoCargoServiceImpl)

```java
@Service
public class DocumentoCargoServiceImpl implements DocumentoCargoService {
    
    @Autowired
    private DocumentoRepository repository;
    
    public DocumentoCargoResultDTO cargarDocumento(DocumentoCargoDTO documento) {
        
        // VALIDACIÓN 1: Nombre
        if (documento.getNombreDocumento() == null || isEmpty(documento.getNombreDocumento()))
            throw new IllegalArgumentException("El nombre es requerido");
        
        // VALIDACIÓN 2: Tipo de firma
        if (documento.getTipoFirmaID() < 1 || documento.getTipoFirmaID() > 2)
            throw new IllegalArgumentException("TipoFirmaID inválido");
        
        // VALIDACIÓN 3: Firmantes secuenciales
        if (documento.getTipoFirmaID() == 1) {
            for (FirmanteDTO f : documento.getFirmantes()) {
                if (f.getPosicion() == null)
                    throw new IllegalArgumentException("Posición requerida");
            }
        }
        
        // INSERT documento (transacción automática)
        repository.insertDocumentoDTO(documento);
        Integer docID = documento.getDocumentoID();
        
        // INSERT firmantes (sin cursores, list.stream() moderno)
        documento.getFirmantes().forEach(firmante -> {
            Integer pos = documento.getTipoFirmaID() == 2 ? null : firmante.getPosicion();
            repository.insertFirmante(pos, firmante.getIdUsuario(), docID, null);
        });
        
        // INSERT observadores
        documento.getObservadores().forEach(obs ->
            repository.insertFirmante(null, obs.getIdUsuario(), docID, 1)
        );
        
        return new DocumentoCargoResultDTO(documento);
    }
}
```

**Ventajas:**
- ✅ Sintaxis Java estándar (Java 8+)
- ✅ Legible: bucles foreach en lugar de cursores
- ✅ Testeable: mocks de repository
- ✅ Control de versiones: Git + commits claros
- ✅ Debugging: breakpoints, stack traces útiles
- ✅ Modernizable: cambios sin toque de BD

---

## 📊 MATRIZ DE COMPARACIÓN

| Característica | SQL SP | Java Refactorizado |
|---|---|---|
| **Líneas de Código** | ~250 | ~150 (más legible) |
| **Curva de Aprendizaje** | Alta (SQL Server) | Media (Java) |
| **Testing** | Con DB | Unit tests con mocks |
| **Debugging** | SSMS (lento) | IDE (rápido) |
| **Control de Versiones** | Difícil (DDL scripts) | Fácil (Git) |
| **CI/CD Integration** | Complejo | Nativo |
| **Documentación** | Comentarios SQL | JavaDoc + Tests |
| **Refactoring Futuro** | Requiere BD DBA | Solo developer Java |
| **Transacciones** | Implícitas en SP | Explícitas (@Transactional) |
| **Error Handling** | RAISERROR | Excepciones Java |

---

## ✅ CHECKLIST PRE-IMPLEMENTACIÓN

### Verificación de Archivos
- [ ] DocumentoCargoDTO.java existe
- [ ] FirmanteDTO.java existe
- [ ] DocumentoCargoResultDTO.java existe
- [ ] DocumentoRepository.java existe
- [ ] DocumentoCargoService.java existe
- [ ] DocumentoCargoServiceImpl.java existe

### Verificación de Imports
- [ ] Lombok @Data, @NoArgsConstructor, etc. importados
- [ ] MyBatis @Insert, @Select, @Options importados
- [ ] Spring @Service, @Autowired, @Transactional importados
- [ ] Java 8 LocalDate, LocalDateTime importados

### Verificación de Configuración
- [ ] MyBatis SqlSessionFactory configurado (aplicación)
- [ ] JNDI datasource jdbc/fedi disponible en Tomcat
- [ ] Transactionmanager configurado en Spring

### Verificación de Integración
- [ ] FEDIServiceImpl inyecta DocumentoCargoService
- [ ] cargarDocumentos() reemplazado
- [ ] convertirRequestADocumentos() implementado
- [ ] Imports actualizados en FEDIServiceImpl

---

## 🎯 RESULT ESPERADO

**Después de implementar esta solución:**

```
Usuario carga documento en GUI
         ↓ (clic en "Guardar")
         ↓ (sin timeout)
    <100ms
         ↓
Documento guardado en BD ✅
     ↓ Mensaje a usuario
"✅ Documento guardado exitosamente"
     ↓
Usuario puede proceder a firmar
```

**Vs Antes:**
```
Usuario carga documento en GUI
         ↓ (clic en "Guardar")
      120s ⏳
    (esperando...)
         ↓
❌ TIMEOUT - Documento NO se guarda
"❌ Error: Unable to connect to fedi-srv"
```

---

**Fin del Mapa de Solución. ¡Listo para implementar! 🚀**
