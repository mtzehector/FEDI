# Solicitud de Acceso a Base de Datos - Sistema FEDI

**Para:** Equipo de Base de Datos  
**De:** [Tu Nombre]  
**Fecha:** 11 de febrero de 2026  
**Asunto:** Acceso READ-ONLY para mantenimiento de FEDI  

---

## Contexto

Estoy trabajando en la resolución del error **HTTP 502** que impide guardar documentos en FEDI. El problema está en el SP `SP_CARGAR_DOCUMENTOS` que excede los 120 segundos de timeout.

Para optimizar el sistema, necesito reemplazar los Stored Procedures con SQL directo en MyBatis (como hemos hecho en otros proyectos). Esto debería reducir el tiempo de 30-120s a 1-5s.

---

## Acceso Solicitado

### **Usuario READ-ONLY para DEV/QA**

**Permisos necesarios:**
- `SELECT` en tablas del esquema FEDI
- `VIEW DEFINITION` en tablas y stored procedures
- Acceso a `INFORMATION_SCHEMA`

**Usuario sugerido:** `fedi_dev_readonly`  
**Duración:** Permanente (para mantenimiento continuo)

### **Información que necesito:**

**Tablas (DDL + estructura):**
- `solicitud_documento` (o equivalente)
- `documento_firmante`
- `cat_usuario`
- `cat_tipo_firma`
- `cat_documento_estatus`

**Stored Procedures (código fuente):**
- `SP_CARGAR_DOCUMENTOS` ← **PRIORITARIO**
- `SP_CARGAR_DOCUMENTO`
- `SP_CONSULTA_DOCUMENTOS`
- `SP_CONSULTA_FIRMANTES`
- `SP_FIRMAR_DOCUMENTO`
- `SP_BORRAR_DOCUMENTO`

**Adicional:**
- Índices en tablas principales
- Foreign keys y constraints
- Connection string para DEV/QA

---

## Plan de Trabajo

1. **Análisis** (1-2 días): Revisar esquema y lógica de SPs
2. **Desarrollo** (2-3 días): Implementar SQL directo en MyBatis
3. **Testing** (2-3 días): Validar en QA
4. **Producción** (1 día): Deploy con rollback disponible

**Total:** ~1 semana

---

## Impacto

✅ **SIN cambios en BD:** Los SPs se mantienen, esquema intacto  
✅ **Performance:** Mejora estimada del 95% (30-120s → 1-5s)  
✅ **Rollback:** SPs disponibles como fallback  
✅ **Mantenimiento:** Más fácil debuggear y modificar en el futuro  

---

## Entregables

Al finalizar:
- Código en Git con revisión completa
- Documentación de queries SQL
- Reporte de performance (antes/después)
- Diagrama ER actualizado

---

## Información de Contacto

**Desarrollador:**  
- Nombre: [Tu Nombre]  
- Email: [tu.email@ift.org.mx]  
- Extensión: [Tu Ext]

**Disponibilidad:** Horario normal de oficina. Podemos coordinar una sesión de 30 min para revisar el esquema si es necesario.

---

**Urgencia:** Alta - Funcionalidad crítica bloqueada  
**Fecha objetivo:** 20 de febrero de 2026

Gracias,  
[Tu Nombre]
