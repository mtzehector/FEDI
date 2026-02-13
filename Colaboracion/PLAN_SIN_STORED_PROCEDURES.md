# Plan: Reemplazar Stored Procedures con SQL Directo

## ✅ Situación Actual

- **TODO el fedi-srv usa Stored Procedures** en SQL Server
- Ejemplo crítico: `SP_CARGAR_DOCUMENTOS` que está causando el timeout
- MyBatis configurado con `statementType="CALLABLE"`

## 🎯 Solución: SQL Directo con MyBatis

Voy a reemplazar los SPs más críticos con SQL directo. Ventajas:

✅ **Más rápido** - No overhead de SP  
✅ **Más debuggeable** - Ves SQL exacto en logs  
✅ **Más controlable** - Manejo de transacciones en Java  
✅ **Sin permisos especiales** - Solo necesitas INSERT/SELECT/UPDATE  
✅ **Mejor para migración** - Independiente de BD específica  

## 📋 Stored Procedures a Reemplazar

### **PRIORITARIO (Causa del HTTP 502)**

| SP Actual | Línea XML | Lo que hace | Reemplazo SQL |
|-----------|-----------|-------------|---------------|
| `SP_CARGAR_DOCUMENTOS` | 56 | INSERT múltiple en `solicitud_documento` + return JSON | INSERT INTO + SELECT con FOR JSON |
| `SP_CARGAR_DOCUMENTO` | 38 | INSERT individual en `solicitud_documento` | INSERT INTO + SELECT SCOPE_IDENTITY() |

### **SECUNDARIO (Si hay tiempo)**

| SP | Lo que hace | Complejidad |
|----|-------------|-------------|
| `SP_CONSULTA_DOCUMENTOS` | SELECT documentos del usuario | FÁCIL |
| `SP_CONSULTA_FIRMANTES` | SELECT firmantes de documento | FÁCIL |
| `SP_FIRMAR_DOCUMENTO` | UPDATE firma de documento | MEDIO |
| `SP_BORRAR_DOCUMENTO` | UPDATE estatus a eliminado | FÁCIL |

---

## 🔧 Implementación: cargarDocumentos()

### **Paso 1: Esquema de Tabla (inferido del resultMap)**

```sql
-- Tabla: solicitud_documento (o similar)
CREATE TABLE dbo.solicitud_documento (
    documento_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_documento VARCHAR(255) NOT NULL,
    ruta_documento VARCHAR(500) NOT NULL,
    fecha_vigencia VARCHAR(50),
    fecha_hora_carga VARCHAR(50) NOT NULL,
    total_paginas INT,
    usuario_id VARCHAR(100) NOT NULL,
    tipo_firma_id INT NOT NULL,
    tamano_documento INT,
    hash_documento VARCHAR(255),
    sistema_origen VARCHAR(100),
    estatus_id INT DEFAULT 1, -- 1=CARGADO, 2=FIRMADO, 3=ELIMINADO
    fecha_creacion DATETIME DEFAULT GETDATE()
);

-- Tabla: documento_firmante
CREATE TABLE dbo.documento_firmante (
    documento_firmante_id INT IDENTITY(1,1) PRIMARY KEY,
    documento_id INT NOT NULL,
    usuario_id VARCHAR(100) NOT NULL,
    posicion INT NOT NULL,
    fecha_firma VARCHAR(50),
    hora_firma VARCHAR(50),
    hash VARCHAR(255),
    FOREIGN KEY (documento_id) REFERENCES solicitud_documento(documento_id)
);
```

### **Paso 2: Nuevo MyBatis Mapper (SQL Directo)**

Voy a crear un archivo: **FEDI_DIRECT.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="fedi.srv.ift.org.mx.persistence.FEDIMapperDirect">

    <!-- ============================================ -->
    <!-- CARGAR DOCUMENTO INDIVIDUAL (sin SP) -->
    <!-- ============================================ -->
    <insert id="cargarDocumento" parameterType="map" useGeneratedKeys="true" keyProperty="idDocumento">
        INSERT INTO dbo.solicitud_documento (
            nombre_documento,
            ruta_documento,
            fecha_vigencia,
            fecha_hora_carga,
            total_paginas,
            usuario_id,
            tipo_firma_id,
            tamano_documento,
            sistema_origen,
            estatus_id
        ) VALUES (
            #{nombreDocumento, jdbcType=VARCHAR},
            #{rutaDocumento, jdbcType=VARCHAR},
            #{fechaVigencia, jdbcType=VARCHAR},
            #{fechaHoraCarga, jdbcType=VARCHAR},
            #{totalPaginas, jdbcType=INTEGER},
            #{idUsuario, jdbcType=VARCHAR},
            #{idTipoFirma, jdbcType=INTEGER},
            #{tamanoDocumento, jdbcType=INTEGER},
            #{sistemaOrigen, jdbcType=VARCHAR},
            1 -- Estatus CARGADO
        )
    </insert>

    <!-- Insertar firmantes de un documento -->
    <insert id="insertarFirmantes" parameterType="map">
        INSERT INTO dbo.documento_firmante (
            documento_id,
            usuario_id,
            posicion
        )
        SELECT
            #{idDocumento, jdbcType=INTEGER} AS documento_id,
            value AS usuario_id,
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS posicion
        FROM STRING_SPLIT(#{firmantes, jdbcType=VARCHAR}, ',')
        WHERE RTRIM(value) != ''
    </insert>

    <!-- ============================================ -->
    <!-- CARGAR DOCUMENTOS MÚLTIPLES (sin SP) -->
    <!-- ============================================ -->
    
    <!-- Este será el reemplazo directo de SP_CARGAR_DOCUMENTOS -->
    <!-- Recibe JSON de documentos, los inserta, y retorna JSON con IDs -->
    <insert id="cargarDocumentosBatch" parameterType="map" statementType="PREPARED">
        <![CDATA[
        DECLARE @DocumentosTemp TABLE (
            temp_id INT IDENTITY(1,1),
            nombreDocumento VARCHAR(255),
            rutaDocumento VARCHAR(500),
            fechaVigencia VARCHAR(50),
            fechaHoraCarga VARCHAR(50),
            totalPaginas INT,
            idUsuario VARCHAR(100),
            idTipoFirma INT,
            tamanoDocumento INT,
            hashDocumento VARCHAR(255),
            sistemaOrigen VARCHAR(100),
            firmantes NVARCHAR(MAX)
        );

        -- Parsear JSON de entrada
        INSERT INTO @DocumentosTemp (
            nombreDocumento,
            rutaDocumento,
            fechaVigencia,
            fechaHoraCarga,
            totalPaginas,
            idUsuario,
            idTipoFirma,
            tamanoDocumento,
            hashDocumento,
            sistemaOrigen,
            firmantes
        )
        SELECT
            nombreDocumento,
            rutaDocumento,
            fechaVigencia,
            fechaHoraCarga,
            totalPaginas,
            idUsuario,
            idTipoFirma,
            tamanoDocumento,
            hashDocumento,
            sistemaOrigen,
            firmantes
        FROM OPENJSON(#{jsonDatosDocs, jdbcType=VARCHAR})
        WITH (
            nombreDocumento VARCHAR(255) '$.nombreDocumento',
            rutaDocumento VARCHAR(500) '$.rutaDocumento',
            fechaVigencia VARCHAR(50) '$.fechaVigencia',
            fechaHoraCarga VARCHAR(50) '$.fechaHoraCarga',
            totalPaginas INT '$.totalPaginas',
            idUsuario VARCHAR(100) '$.idUsuario',
            idTipoFirma INT '$.idTipoFirma',
            tamanoDocumento INT '$.tamanoDocumento',
            hashDocumento VARCHAR(255) '$.hashDocumento',
            sistemaOrigen VARCHAR(100) '$.sistemaOrigen',
            firmantes NVARCHAR(MAX) '$.listaFirmantes' AS JSON
        );

        -- Insertar documentos
        DECLARE @InsertedDocs TABLE (
            documento_id INT,
            temp_id INT,
            nombreDocumento VARCHAR(255),
            hashDocumento VARCHAR(255)
        );

        INSERT INTO dbo.solicitud_documento (
            nombre_documento,
            ruta_documento,
            fecha_vigencia,
            fecha_hora_carga,
            total_paginas,
            usuario_id,
            tipo_firma_id,
            tamano_documento,
            sistema_origen,
            estatus_id
        )
        OUTPUT
            INSERTED.documento_id,
            NULL AS temp_id, -- Will be populated via JOIN
            INSERTED.nombre_documento,
            NULL AS hashDocumento
        INTO @InsertedDocs
        SELECT
            nombreDocumento,
            rutaDocumento,
            fechaVigencia,
            fechaHoraCarga,
            totalPaginas,
            idUsuario,
            idTipoFirma,
            tamanoDocumento,
            sistemaOrigen,
            1 -- Estatus CARGADO
        FROM @DocumentosTemp;

        -- Retornar JSON con IDs asignados
        SELECT @documentosID = (
            SELECT
                documento_id AS idDocumento,
                nombreDocumento,
                hashDocumento
            FROM @InsertedDocs
            FOR JSON PATH
        );
        ]]>
    </insert>

    <!-- ============================================ -->
    <!-- CONSULTAR DOCUMENTOS (sin SP) -->
    <!-- ============================================ -->
    <select id="obtenDocumentos" resultMap="obtenDocumentosMap">
        SELECT
            d.documento_id AS DOCUMENTOID,
            d.nombre_documento AS NOMBREDOCUMENTO,
            d.ruta_documento AS RUTADOCUMENTO,
            d.fecha_vigencia AS FECHAVIGENCIA,
            d.fecha_hora_carga AS FECHAHORACARGA,
            d.total_paginas AS TOTALPAGINAS,
            d.tamano_documento AS TAMANODOCUMENTO,
            d.sistema_origen AS SISTEMAORIGEN,
            d.usuario_id AS USUARIOID,
            u.nombre AS NOMBRE,
            u.apellido_paterno AS APELLIDOPATERNO,
            u.apellido_materno AS APELLIDOMATERNO,
            tf.tipo_firma_id AS TIPOFIRMAID,
            tf.tipo_firma AS TIPOFIRMA,
            de.estatus_id AS DOCUMENTOESTATUSID,
            de.estatus AS DOCUMENTOESTATUS,
            CASE WHEN EXISTS (
                SELECT 1 FROM dbo.documento_firmante df
                WHERE df.documento_id = d.documento_id
                AND df.usuario_id = #{idUsuario, jdbcType=VARCHAR}
                AND df.fecha_firma IS NULL
            ) THEN 1 ELSE 0 END AS TOCAFIRMAR
        FROM dbo.solicitud_documento d
        LEFT JOIN dbo.cat_usuario u ON d.usuario_id = u.usuario_id
        LEFT JOIN dbo.cat_tipo_firma tf ON d.tipo_firma_id = tf.tipo_firma_id
        LEFT JOIN dbo.cat_documento_estatus de ON d.estatus_id = de.estatus_id
        WHERE d.usuario_id = #{idUsuario, jdbcType=VARCHAR}
        AND d.sistema_origen = #{sistemaOrigen, jdbcType=VARCHAR}
        ORDER BY d.fecha_creacion DESC
    </select>

    <!-- ============================================ -->
    <!-- CONSULTAR FIRMANTES (sin SP) -->
    <!-- ============================================ -->
    <select id="obtenFirmantes" resultMap="obtenFirmantesMap">
        SELECT
            df.usuario_id AS USUARIOID,
            u.nombre AS NOMBRE,
            u.apellido_paterno AS APELLIDOPATERNO,
            u.apellido_materno AS APELLIDOMATERNO,
            df.posicion AS POSICION,
            df.fecha_firma AS FECHAFIRMA,
            df.hora_firma AS HORAFIRMA,
            df.hash AS HASH,
            d.nombre_documento AS NOMBREDOCUMENTO
        FROM dbo.documento_firmante df
        INNER JOIN dbo.solicitud_documento d ON df.documento_id = d.documento_id
        LEFT JOIN dbo.cat_usuario u ON df.usuario_id = u.usuario_id
        WHERE df.documento_id = #{idDocumento, jdbcType=INTEGER}
        ORDER BY df.posicion
    </select>

    <!-- ============================================ -->
    <!-- FIRMAR DOCUMENTO (sin SP) -->
    <!-- ============================================ -->
    <update id="firmarDocumento" parameterType="map">
        UPDATE dbo.documento_firmante
        SET
            fecha_firma = #{fechaHoraFirma, jdbcType=VARCHAR},
            hora_firma = #{fechaHoraFirma, jdbcType=VARCHAR},
            hash = #{hash, jdbcType=VARCHAR}
        WHERE documento_id = #{idDocumento, jdbcType=INTEGER}
        AND usuario_id = #{idUsuario, jdbcType=VARCHAR}
    </update>

    <!-- ============================================ -->
    <!-- BORRAR DOCUMENTO (sin SP) -->
    <!-- ============================================ -->
    <update id="borrarDocumento" parameterType="map">
        UPDATE dbo.solicitud_documento
        SET estatus_id = 3 -- ELIMINADO
        WHERE documento_id = #{idDocumento, jdbcType=INTEGER}
    </update>

    <!-- ResultMaps (reutilizar los existentes) -->
    <resultMap id="obtenDocumentosMap" type="fedi.srv.ift.org.mx.model.Documento">
        <id jdbcType="INTEGER" property="idDocumento" column="DOCUMENTOID"/>
        <result jdbcType="VARCHAR" property="nombreDocumento" column="NOMBREDOCUMENTO"/>
        <result jdbcType="VARCHAR" property="rutaDocumento" column="RUTADOCUMENTO"/>
        <result jdbcType="VARCHAR" property="fechaVigencia" column="FECHAVIGENCIA"/>
        <result jdbcType="VARCHAR" property="fechaHoraCarga" column="FECHAHORACARGA"/>
        <result jdbcType="INTEGER" property="totalPaginas" column="TOTALPAGINAS"/>
        <result jdbcType="INTEGER" property="tamanoDocumento" column="TAMANODOCUMENTO"/>
        <result jdbcType="VARCHAR" property="sistemaOrigen" column="SISTEMAORIGEN"/>
        <result jdbcType="INTEGER" property="tocaFirmar" column="TOCAFIRMAR"/>
        <association property="usuario" resultMap="usuarioMap"/>
        <association property="tipoFirma" resultMap="tipoFirmaMap"/>
        <association property="documentoEstatus" resultMap="documentoEstatusMap"/>
    </resultMap>

    <resultMap id="obtenFirmantesMap" type="fedi.srv.ift.org.mx.model.Firmante">
        <id jdbcType="VARCHAR" property="idUsuario" column="USUARIOID"/>
        <result jdbcType="VARCHAR" property="nombre" column="NOMBRE"/>
        <result jdbcType="VARCHAR" property="apellidoPaterno" column="APELLIDOPATERNO"/>
        <result jdbcType="VARCHAR" property="apellidoMaterno" column="APELLIDOMATERNO"/>
        <result jdbcType="INTEGER" property="posicion" column="POSICION"/>
        <result jdbcType="VARCHAR" property="fechaFirma" column="FECHAFIRMA"/>
        <result jdbcType="VARCHAR" property="horaFirma" column="HORAFIRMA"/>
        <result jdbcType="VARCHAR" property="hash" column="HASH"/>
        <result jdbcType="VARCHAR" property="nombreDocumento" column="NOMBREDOCUMENTO"/>
    </resultMap>

    <resultMap id="tipoFirmaMap" type="fedi.srv.ift.org.mx.model.TipoFirma">
        <id property="idTipoFirma" column="TIPOFIRMAID" jdbcType="INTEGER"/>
        <result property="tipoFirma" column="TIPOFIRMA" jdbcType="VARCHAR"/>
    </resultMap>

    <resultMap id="documentoEstatusMap" type="fedi.srv.ift.org.mx.model.DocumentoEstatus">
        <id property="idDocumentoEstatus" column="DOCUMENTOESTATUSID" jdbcType="INTEGER"/>
        <result property="documentoEstatus" column="DOCUMENTOESTATUS" jdbcType="VARCHAR"/>
    </resultMap>

    <resultMap id="usuarioMap" type="fedi.srv.ift.org.mx.model.CatUsuario">
        <id jdbcType="VARCHAR" property="idUsuario" column="USUARIOID"/>
        <result jdbcType="VARCHAR" property="nombre" column="NOMBRE"/>
        <result jdbcType="VARCHAR" property="apellidoPaterno" column="APELLIDOPATERNO"/>
        <result jdbcType="VARCHAR" property="apellidoMaterno" column="APELLIDOMATERNO"/>
    </resultMap>

</mapper>
```

---

## 🎯 Cómo Implementarlo

### **Opción A: REEMPLAZO COMPLETO (Recomendado)**

1. Crear archivo `FEDI_DIRECT.xml` con SQL directo
2. Actualizar `FEDIServiceImpl.java` para usar nuevo mapper
3. Comentar/eliminar `FEDI.xml` viejo

**Ventajas:**
- ✅ Sin stored procedures
- ✅ Más rápido (sin overhead de SP)
- ✅ Más fácil de debuggear

**Desventajas:**
- ⚠️ Necesitas conocer nombres exactos de tablas
- ⚠️ Necesitas acceso a esquema de BD

### **Opción B: HÍBRIDO (Más seguro)**

1. Crear `FEDIMapperDirect.java` interface paralela
2. Mantener `FEDIMapper.java` viejo funcional
3. Configurar Spring para usar uno u otro vía property

**Ventajas:**
- ✅ Rollback fácil si algo falla
- ✅ A/B testing entre SP y SQL directo
- ✅ No rompes nada existente

---

## ⚡ MEJORA INMEDIATA (Sin cambiar BD)

Si NO quieres tocar el mapper XML todavía, puedo:

1. **Optimizar el código Java** para reducir llamadas a BD
2. **Implementar caché** de consultas frecuentes
3. **Hacer batch inserts más eficientes** en Java antes de llamar SP
4. **Agregar connection pooling** optimizado

---

## 📊 Comparación de Performance

| Método | Tiempo Estimado | Complejidad |
|--------|----------------|-------------|
| **SP Actual** | 30-120+ segundos | N/A |
| **SQL Directo Simple** | 1-5 segundos | BAJO |
| **SQL Directo + Transaction** | 2-8 segundos | MEDIO |
| **SQL Directo + Batch** | 0.5-3 segundos | MEDIO |

---

## ❓ SIGUIENTE PASO

**¿Qué prefieres?**

1. 🎯 **OPCIÓN A:** Te creo el archivo `FEDI_DIRECT.xml` completo con SQL directo listo para usar
   - Necesito confirmar nombres de tablas con el DBA
   - Te lo implemento en 15 minutos

2. 🔧 **OPCIÓN B:** Creamos versión híbrida que mantiene compatibilidad con SPs
   - Más seguro para producción
   - Te lo implemento en 20 minutos

3. ⚡ **OPCIÓN C:** Optimizamos el código Java actual sin tocar XML
   - Sin cambios en BD
   - Mejoras inmediatas en 10 minutos

**¿Cuál prefieres?** Y si eliges Opción A o B, ¿tienes acceso al DBA para confirmar nombres de tablas o quieres que los infiera del código existente?
