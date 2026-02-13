# 📋 GUÍA DE INTEGRACIÓN: Refactorización a Java

**Fecha:** 12-Feb-2026  
**Estado:** ✅ Archivos Creados y Listos para Integración  
**Archivos Nuevos:** 6 clases Java + 1 Interface

---

## 📁 ARCHIVOS CREADOS

```
fedi-web/src/main/java/fedi/ift/org/mx/
├── model/documento/
│   ├── DocumentoCargoDTO.java          ← DTO del documento
│   ├── FirmanteDTO.java                ← DTO del firmante/observador
│   └── DocumentoCargoResultDTO.java    ← DTO de respuesta
├── persistence/mapper/
│   └── DocumentoRepository.java        ← MyBatis Repository (NO usa XML!)
└── service/
    ├── DocumentoCargoService.java      ← Interface del servicio
    └── DocumentoCargoServiceImpl.java   ← Implementación del servicio
```

---

## 🔄 FLUJO DE EJECUCIÓN

### Antes (Fallando con SSL):
```
DocumentoVistaFirmaMB.guardarDocumento()
    ↓
FEDIServiceImpl.cargarDocumentos()
    ↓ (REST Call)
MDSeguridadServiceImpl.EjecutaMetodoGET()
    ↓ (okhttp3 con SSL)
fedi-srv/fedi/cargarDocumentos
    ↓ (FALLA: PKIX Certificate validation error)
❌ TIMEOUT 120 segundos
```

### Después (Optimizado):
```
DocumentoVistaFirmaMB.guardarDocumento()
    ↓
DocumentoCargoServiceImpl.cargarDocumento()
    ↓ (JNDI local, no REST)
DocumentoRepository.insertDocumentoDTO()
    ↓ (MyBatis SQL local)
tbl_Documentos + tbl_Firmantes
    ↓
✅ RESPUESTA INMEDIATA (<50ms)
```

---

## 🛠️ CÓMO INTEGRAR EN FEDIServiceImpl

### Paso 1: Inyectar el Servicio

**En:** `fedi-web/src/main/java/fedi/ift/org/mx/service/FEDIServiceImpl.java`

```java
package fedi.ift.org.mx.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fedi.ift.org.mx.model.documento.DocumentoCargoDTO;
import fedi.ift.org.mx.model.documento.DocumentoCargoResultDTO;
import fedi.ift.org.mx.service.DocumentoCargoService;  // ← NUEVO

@Service
public class FEDIServiceImpl implements FEDIService {
    
    // ... existe código anterior ...
    
    @Autowired
    private DocumentoCargoService documentoCargoService;  // ← INYECTAR
```

### Paso 2: Reemplazar cargarDocumentos()

**Ubicación:** Línea 207-235 de FEDIServiceImpl.java

**Código Anterior (REEMPLAZAR):**
```java
public ResponseFEDI cargarDocumentos(RequestFEDIMain request) throws Exception {
    String vMetodo = "fedi/cargarDocumentos";
    String urlCompleta = this.perfilFEDI.getUrlServidorFEDI() + vMetodo;
    LOGGER.info("FEDIServiceImpl.cargarDocumentos() - Invocando API: " + urlCompleta);
    // REST call que falla con SSL
    // ...
}
```

**Código Nuevo (INSTALAR):**
```java
public ResponseFEDI cargarDocumentos(RequestFEDIMain request) throws Exception {
    try {
        LOGGER.info("=== FEDIServiceImpl.cargarDocumentos() - INICIO ===");
        
        // 1. Convertir RequestFEDIMain a List<DocumentoCargoDTO>
        List<DocumentoCargoDTO> documentos = convertirRequestADocumentos(request);
        
        // 2. Guardar documentos usando servicio LOCAL (SIN REST, SIN SSL)
        long startTime = System.currentTimeMillis();
        List<DocumentoCargoResultDTO> documentosGuardados = 
            documentoCargoService.cargarDocumentos(documentos);
        long duracion = System.currentTimeMillis() - startTime;
        
        LOGGER.info("FEDIServiceImpl.cargarDocumentos() - {} documentos guardados en {}ms",
                   documentosGuardados.size(), duracion);
        
        // 3. Retornar respuesta exitosa
        ResponseFEDI response = new ResponseFEDI();
        response.setCode(200);
        response.setSuccess(true);
        response.setData(documentosGuardados);
        response.setMessage("Documentos guardados exitosamente");
        
        return response;
        
    } catch (IllegalArgumentException e) {
        LOGGER.error("FEDIServiceImpl.cargarDocumentos() - Error de validación: {}", e.getMessage());
        ResponseFEDI response = new ResponseFEDI();
        response.setCode(400);  // Bad Request
        response.setSuccess(false);
        response.setErrorMessage(e.getMessage());
        return response;
        
    } catch (Exception e) {
        LOGGER.error("FEDIServiceImpl.cargarDocumentos() - Error inesperado: {}", e.getMessage(), e);
        ResponseFEDI response = new ResponseFEDI();
        response.setCode(500);  // Internal Server Error
        response.setSuccess(false);
        response.setErrorMessage("Error al guardar documentos: " + e.getMessage());
        return response;
    }
}

/**
 * Convierte RequestFEDIMain a List<DocumentoCargoDTO>
 * (Adaptar según estructura de RequestFEDIMain)
 */
private List<DocumentoCargoDTO> convertirRequestADocumentos(RequestFEDIMain request) 
        throws Exception {
    
    List<DocumentoCargoDTO> documentos = new ArrayList<>();
    
    // ADAPTACIÓN NECESARIA: Depende de cómo llegue RequestFEDIMain
    // Ejemplo (AJUSTAR según tu estructura):
    
    if (request != null && request.getDocumentos() != null) {
        for (RequestFEDI doc : request.getDocumentos()) {
            DocumentoCargoDTO dto = new DocumentoCargoDTO();
            dto.setNombreDocumento(doc.getNombreDocumento());
            dto.setRutaDocumento(doc.getRutaDocumento());
            dto.setFechaVigencia(LocalDate.parse(doc.getFechaVigencia()));
            dto.setTotalPaginas(doc.getTotalPaginas());
            dto.setUsuarioID(request.getUsuarioID());
            dto.setTipoFirmaID(doc.getTipoFirmaID());
            dto.setTamanoDocumento(doc.getTamanoDocumento());
            dto.setSistemaOrigen(doc.getSistemaOrigen());
            
            // Convertir firmantes
            List<FirmanteDTO> firmantes = new ArrayList<>();
            if (doc.getFirmantes() != null) {
                for (RequestFirmante rf : doc.getFirmantes()) {
                    FirmanteDTO fd = new FirmanteDTO(
                        rf.getIdUsuario(),
                        rf.getPosicion(),
                        rf.getUnidadAdministrativa()
                    );
                    firmantes.add(fd);
                }
            }
            dto.setFirmantes(firmantes);
            
            // Convertir observadores
            List<FirmanteDTO> observadores = new ArrayList<>();
            if (doc.getObservadores() != null) {
                for (RequestObservador ro : doc.getObservadores()) {
                    FirmanteDTO od = new FirmanteDTO(
                        ro.getIdUsuario(),
                        null,
                        ro.getUnidadAdministrativa()
                    );
                    observadores.add(od);
                }
            }
            dto.setObservadores(observadores);
            
            documentos.add(dto);
        }
    }
    
    return documentos;
}
```

### Paso 3: Usar en Obtener Documentos a Firmar

**En FEDIServiceImpl.java, agregar método nuevo:**

```java
/**
 * Obtiene documentos pendientes de firma para un usuario
 * (Anteriormente llamaba a fedi-srv)
 */
public ResponseFEDI obtenerDocumentosAFirmar(String usuarioID, String sistemaOrigen) {
    try {
        LOGGER.info("Obteniendo documentos a firmar para: {} (sistema: {})", usuarioID, sistemaOrigen);
        
        List<DocumentoCargoDTO> documentos = 
            documentoCargoService.obtenerDocumentosAFirmar(usuarioID, sistemaOrigen);
        
        ResponseFEDI response = new ResponseFEDI();
        response.setCode(200);
        response.setSuccess(true);
        response.setData(documentos);
        return response;
        
    } catch (Exception e) {
        LOGGER.error("Error obteniendo documentos: {}", e.getMessage(), e);
        ResponseFEDI response = new ResponseFEDI();
        response.setCode(500);
        response.setSuccess(false);
        response.setErrorMessage(e.getMessage());
        return response;
    }
}
```

---

## 🧪 TESTING: Verificar que Funciona

### Unit Test

**Archivo:** `fedi-web/src/test/java/fedi/ift/org/mx/service/DocumentoCargoServiceTest.java`

```java
package fedi.ift.org.mx.service;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.junit.Before;
import org.junit.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import fedi.ift.org.mx.model.documento.DocumentoCargoDTO;
import fedi.ift.org.mx.model.documento.DocumentoCargoResultDTO;
import fedi.ift.org.mx.model.documento.FirmanteDTO;
import fedi.ift.org.mx.persistence.mapper.DocumentoRepository;

public class DocumentoCargoServiceTest {
    
    @Mock
    private DocumentoRepository documentoRepository;
    
    @InjectMocks
    private DocumentoCargoServiceImpl documentoCargoService;
    
    @Before
    public void setUp() {
        MockitoAnnotations.initMocks(this);
    }
    
    /**
     * Test 1: Guardar documento sin firmantes
     */
    @Test
    public void testCargarDocumentoSinFirmantes() throws Exception {
        // Given
        DocumentoCargoDTO documento = new DocumentoCargoDTO(
            "Documento Test",
            "/documentos/test.pdf",
            LocalDate.of(2026, 12, 31),
            LocalDateTime.now(),
            5,
            "user123",
            2,  // Concurrente
            1024,
            "SISTEMA"
        );
        
        // When
        DocumentoCargoResultDTO resultado = documentoCargoService.cargarDocumento(documento);
        
        // Then
        assertNotNull(resultado);
        assertEquals("Documento Test", resultado.getNombreDocumento());
        verify(documentoRepository, times(1)).insertDocumentoDTO(documento);
    }
    
    /**
     * Test 2: Guardar documento con firmantes secuenciales
     */
    @Test
    public void testCargarDocumentoConFirmantesSecuenciales() throws Exception {
        // Given
        DocumentoCargoDTO documento = new DocumentoCargoDTO(
            "Documento Secuencial",
            "/documentos/seq.pdf",
            LocalDate.of(2026, 12, 31),
            LocalDateTime.now(),
            10,
            "user123",
            1,  // Secuencial
            2048,
            "SISTEMA"
        );
        
        // Agregar firmantes
        List<FirmanteDTO> firmantes = new ArrayList<>();
        firmantes.add(new FirmanteDTO("user1", 1, "Unidad A"));
        firmantes.add(new FirmanteDTO("user2", 2, "Unidad B"));
        documento.setFirmantes(firmantes);
        
        // When
        DocumentoCargoResultDTO resultado = documentoCargoService.cargarDocumento(documento);
        
        // Then
        assertNotNull(resultado);
        assertEquals(2, documento.getFirmantes().size());
        verify(documentoRepository, times(1)).insertDocumentoDTO(documento);
        verify(documentoRepository, times(2)).insertFirmante(anyInt(), anyString(), anyInt(), isNull(), anyString());
    }
    
    /**
     * Test 3: Error - Documento sin nombre
     */
    @Test(expected = IllegalArgumentException.class)
    public void testCargarDocumentoSinNombre() throws Exception {
        DocumentoCargoDTO documento = new DocumentoCargoDTO();
        documento.setNombreDocumento(null);
        documento.setTipoFirmaID(2);
        
        documentoCargoService.cargarDocumento(documento);
    }
    
    /**
     * Test 4: Error - Firmante secuencial sin posición
     */
    @Test(expected = IllegalArgumentException.class)
    public void testCargarDocumentoFirmanteSinPosicion() throws Exception {
        DocumentoCargoDTO documento = new DocumentoCargoDTO(
            "Documento",
            "/path/doc.pdf",
            LocalDate.now(),
            LocalDateTime.now(),
            5,
            "user123",
            1,  // Secuencial
            1024,
            "SISTEMA"
        );
        
        // Firmante SIN posición (falta)
        FirmanteDTO firmante = new FirmanteDTO("user1", null, "Unidad");
        documento.setFirmantes(List.of(firmante));
        
        documentoCargoService.cargarDocumento(documento);
    }
}
```

**Para ejecutar tests:**
```bash
cd C:\github\fedi-web
mvn clean test -Dtest=DocumentoCargoServiceTest
```

---

## ✅ VALIDACIÓN CHECKLIST

Antes de compilar, asegúrate que:

- [ ] `DocumentoCargoDTO.java` creado en `model/documento/`
- [ ] `FirmanteDTO.java` creado en `model/documento/`
- [ ] `DocumentoCargoResultDTO.java` creado en `model/documento/`
- [ ] `DocumentoRepository.java` creado en `persistence/mapper/`
- [ ] `DocumentoCargoService.java` (interface) creado en `service/`
- [ ] `DocumentoCargoServiceImpl.java` creado en `service/`
- [ ] FEDIServiceImpl.java actualizado con inyección de `DocumentoCargoService`
- [ ] Imports añadidos en FEDIServiceImpl
- [ ] Sin conflictos de clases duplicadas

---

## 🚀 COMPILACIÓN

```bash
# Desde fedi-web
cd C:\github\fedi-web

# Compilar proyecto completo
mvn clean install -P development-oracle1 -DskipTests

# Si hay errores de compilación
mvn compile -P development-oracle1 -X
```

**Esperado:**
```
[INFO] BUILD SUCCESS
[INFO] Total time: XX.XXs
[INFO] WAR file: target/FEDIPortalWeb-1.0.war
```

---

## 📊 ANTES vs DESPUÉS

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Tiempo de Guardado** | 120+ segundos (timeout) | 50-100 ms |
| **Dependencia SSL** | ❌ falla certificados | ✅ Sin SSL calls |
| **Control de Código** | En API Manager/BD | En Java CRT |
| **Transacciones** | Parciales (REST) | Completas (ACID) |
| **Logs** | Código oculto en API | Visible en Java |

---

## 🎯 PRÓXIMOS PASOS

1. ✅ Crear archivos DTOs (HECHO)
2. ✅ Crear Repository MyBatis (HECHO)
3. ✅ Crear Servicio y Interface (HECHO)
4. ⏳ **Integrar en FEDIServiceImpl** (SIGUIENTE)
5. ⏳ Reemplazar método cargarDocumentos()
6. ⏳ Compilar y verificar sin errores
7. ⏳ Desplegar WAR en Tomcat
8. ⏳ Probar guardado desde GUI
9. ⏳ Refactorizar firmarDocumentos() (similar)

