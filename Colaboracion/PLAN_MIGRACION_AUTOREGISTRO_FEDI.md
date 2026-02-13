# 📋 PLAN DE MIGRACIÓN Y DOCUMENTACIÓN DE AUTOREGISTRO A FEDI NATIVO

**Ruta de documentación:** `C:\github\Colaboracion`

---

## 1. Objetivo

Migrar todas las dependencias de FEDI con el servicio Autoregistro, haciendo nativos en `fedi-srv` los métodos de registro, validación, activación y creación de usuario. Así, FEDI será autosuficiente y optimizable por el equipo.

---

## 2. Contexto

Toda la documentación técnica, solicitudes a equipos, análisis de logs y planes de acción se están guardando en:
- `C:\github\Colaboracion\`

Archivos clave:
- `SOLICITUD_EQUIPO_BD.md` (escalación a BD)
- `SOLICITUD_EQUIPO_WSO2.md` (escalación a WSO2)
- `ANALISIS_LOGS_CRT_FALLO.md`, `LOGS_AGREGADOS_DIAGNOSTICO.md`, etc.

Este plan se documenta aquí para referencia y trazabilidad.

---

## 3. Alcance del plan

- Identificar todos los métodos de FEDI que dependen de Autoregistro.
- Replicar y mejorar la lógica en `fedi-srv`.
- Crear endpoints REST nativos en `fedi-srv`:
  - `/usuarios/registro`
  - `/usuarios/validar/{user}`
  - `/usuarios/activar`
  - `/usuarios/crear`
- Actualizar FEDI-web y otros clientes para consumir solo endpoints nativos.
- Eliminar referencias a Autoregistro en código y configuración.
- Validar funcionalidad y performance.

---

## 4. Pasos concretos

1. **Identificación:**
   - Buscar referencias a `AutoregistroService` y `autoregistro.url`.
   - Listar métodos: registro, validación, activación, creación de usuario.

2. **Migración:**
   - Implementar lógica en `UsuarioService` y `UsuariosResource` en `fedi-srv`.
   - Crear DTOs (`RegistroRequest`, `ActivarUsuarioRequest`, `DatosUsuario`).
   - Replicar validaciones, reglas de negocio y seguridad.

3. **Actualización de clientes:**
   - FEDI-web y otros deben consumir los nuevos endpoints.
   - Eliminar dependencias externas.

4. **Pruebas y validación:**
   - Probar todos los flujos de usuario.
   - Medir performance y documentar resultados.

5. **Documentación:**
   - Registrar avances, decisiones y problemas en `C:\github\Colaboracion`.
   - Actualizar solicitudes a BD y WSO2 según avance.

---

## 5. Referencia de contexto

- Toda la evidencia, logs, solicitudes y análisis están centralizados en la carpeta de colaboración.
- Si es necesario retomar contexto, consultar los archivos de la ruta.
- El plan puede ser actualizado conforme avance el proyecto.

---

## 6. Checklist de migración

- [ ] Identificar métodos dependientes de Autoregistro
- [ ] Implementar endpoints nativos en `fedi-srv`
- [ ] Actualizar clientes FEDI-web
- [ ] Eliminar dependencias externas
- [ ] Validar funcionalidad y performance
- [ ] Documentar todo en `C:\github\Colaboracion`

---

**Última actualización:** 2026-02-09

