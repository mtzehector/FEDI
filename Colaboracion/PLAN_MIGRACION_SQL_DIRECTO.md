# Plan Migración SQL Directo - SP_CARGAR_DOCUMENTOS

## 1. Problema Identificado

### Cuello de Botella: SP_CARGAR_DOCUMENTOS
- **Línea 280:** CURSOR `cDocumentos` itera cada documento
- **Línea 300:** CURSOR `cFirmantes` itera cada firmante POR documento
- **Línea 320:** CURSOR `cObservadores` itera cada observador POR documento
- **Impacto:** O(N * M * O) operaciones = **TIMEOUT**

### Evidencia
```
BD cargarDocumentos() tardó: 125000ms  ← EXCEEDS 120s timeout
```

---

## 2. Arquitectura de la Solución

### Opción A: INSERT...SELECT (Recomendado - Rápido)
```sql
-- Paso 1: Insertar documentos en batch (una sola operación)
INSERT INTO tbl_Documentos (...)
SELECT ... FROM OPENJSON(@Documentos) ...

-- Paso 2: Insertar firmantes con IDs generados (una sola operación)
INSERT INTO tbl_Firmantes (...)
SELECT ... FROM tbl_Documentos doc
INNER JOIN OPENJSON ... firmantes ...

-- Paso 3: Insertar observadores (una sola operación)
INSERT INTO tbl_Firmantes (...)
SELECT ... FROM tbl_Documentos doc
INNER JOIN OPENJSON ... observadores ...

-- Paso 4: Retornar resultado JSON
SELECT ... FOR JSON AUTO
```

**Ventajas:**
- ✅ Una operación = Muy rápido (5-10s vs 30-120s)
- ✅ Menos overhead de red (una sola llamada SP)
- ✅ Transacciones limpias y atómicas
- ✅ SQL Server optimiza automáticamente

**Desventajas:**
- Requiere SQL Server 2016+ (OPENJSON)
- Curva de aprendizaje en CROSS APPLY

---

## 3. Implementación SQL Directo en MyBatis

### Archivo: FEDI_DIRECT.xml (Nuevo)

#### Mapping 1: cargarDocumentos (SQL Directo)
```xml
<insert id="cargarDocumentos" parameterType="NuevoFEDI">
    -- Insertar documentos e inmediatamente insertar firmantes/observadores
    -- Una sola sentencia INSERT...SELECT con CROSS APPLY
    BEGIN TRANSACTION
    
    INSERT INTO tbl_Documentos(...)
    SELECT ... FROM OPENJSON(#{documentos})
    
    INSERT INTO tbl_Firmantes(...)
    SELECT ... FROM tbl_Documentos
    WHERE DocumentoID IN (SELECT SCOPE_IDENTITY()...)
    
    COMMIT TRANSACTION
</insert>
```

#### Mapping 2: cargarDocumento (SQL Directo)
Sentencia INSERT simple + INSERT de firmantes

#### Mapping 3: consultarDocumentos (SQL Directo)
SELECT directo sin iteración

#### Mapping 4: firmarDocumento (SQL Directo)
UPDATE + SELECT status

---

## 4. Cambios en Código Java

### FEDIServiceImpl.java
```java
// Línea ~256
public void cargarDocumentos(RequestFEDIMain request) {
    *** INICIO cargarDocumentos - Docs: request.getDocumentos().size()
    
    try {
        long start = System.currentTimeMillis();
        
        // SQL Directo en lugar de SP
        FEDIMapper.cargarDocumentosBatch(request);
        
        long elapsed = System.currentTimeMillis() - start;
        *** SQL DIRECTO cargarDocumentos() tardó: ${elapsed}ms
        
        response.setCode(102);  // Success
    } catch (Exception e) {
        *** ERROR: ${e.getMessage()}
        response.setCode(500);  // Error
    }
}
```

---

## 5. Estimado de Mejora

| Operación | Antes (SP) | Después (SQL) | Mejora |
|-----------|-----------|---------------|--------|
| 10 docs × 5 firmas | 35-45s | 3-5s | **8-9x más rápido** |
| 50 docs × 5 firmas | 120s+ (TIMEOUT) | 15-20s | **6-8x más rápido** |
| API timeout | 120s | ✅ Bajo 60s | ✅ Resuelto |

---

## 6. Pasos de Implementación

### Fase 1: Crear SQL Directo
1. ✅ Analizar DDL (COMPLETADO)
2. ⏳ Crear FEDI_DIRECT.xml con INSERT...SELECT

### Fase 2: Integrar en MyBatis
3. ⏳ Crear FEDIMapperDirect.java interface
4. ⏳ Implementar métodos en FEDIServiceImpl

### Fase 3: Compilar y Testear
5. ⏳ mvn clean install en fedi-srv
6. ⏳ Validar WARs generadas
7. ⏳ Testear en QA antes de prod

### Fase 4: Optimizaciones Posteriores
8. ⏳ Índices en tbl_Documentos (DocumentoID, UsuarioID)
9. ⏳ Estadísticas de query execution time

---

## 7. Validación de Éxito

✅ **Objetivo:** Reducir tiempo de cargarDocumentos() de 120s a <20s

**Métricas:**
- Tiempo promedio: 5-20s (vs 30-120s)
- API responde en <60s
- Documentos persisten en FS y BD
- No hay HTTP 502

---

## 8. Rollback Plan

Si SQL directo falla:
1. Mantener SPs intactos en BD
2. FEDIMapperDirect solo en fedi-srv
3. Si error → log y usar SP fallback
4. Redeployed WAR anterior

---

**Siguiente paso:** Crear FEDI_DIRECT.xml con las sentencias INSERT...SELECT optimizadas
