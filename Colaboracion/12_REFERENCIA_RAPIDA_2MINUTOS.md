# ⚡ REFERENCIA RÁPIDA: FEDI-PERITOS-CRT

**Para leer en 2 minutos**

---

## 🎯 El Problema

| Aspecto | IFT | CRT |
|---------|-----|-----|
| **Login** | ✅ Funciona | ✅ Funciona |
| **Autenticación** | ✅ OAuth2 OK | ✅ OAuth2 OK |
| **Obtener usuarios PERITOS** | ✅ Funciona | ❌ FALLA (HTTP 404) |
| **Asignar firmantes** | ✅ Posible | ❌ IMPOSIBLE |
| **Firmar documento** | ✅ Funciona | ❌ Bloqueado |

**Razón:** Falta servicio `srvAutoregistro` en CRT

---

## 📍 Los 4 Endpoints Faltantes

```
1. GET /srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/{sistema}
   └─ Retorna: Todos los roles

2. GET /srvAutoregistroQA/v3.0/registro/consultas/roles/4/{sistema}--{rol}/{sistemaFEDI}
   └─ Retorna: Usuarios de un rol

3. GET /srvAutoregistroQA/v3.0/registro/consultas/roles/1/{usuario}/{sistema}
   └─ Retorna: Valida si usuario existe

4. POST /srvAutoregistroQA/v3.0/registro/actualizar
   └─ Acción: Actualiza permisos de usuario
```

**Todos publicados por:** API Manager CRT (NO EXISTEN)

---

## 🔧 El Responsable (Desaparecido)

```
Servicio: srvAutoregistro
Ubicación: ❌ NO ENCONTRADO EN REPOS
Función: Expone endpoints REST para:
         - Obtener roles y usuarios de PERITOS
         - Validar existencia de usuarios
         - Actualizar permisos

Última localización conocida: API Manager IFT (DEV)
Estado en CRT: NO PUBLICADO (404)
```

---

## 💡 Dónde Buscar

### Rápido (30 min)

```bash
# Línea de comandos
grep -r "srvAutoregistro" c:\github --include="*.java"
find c:\github -iname "*autoregistro*"
ls c:\github\PREANALISIS_CPCREL\WAR*\
```

### Medio (1-2 horas)

```
- Revisar GitHub: https://github.com/search?q=srvAutoregistro
- Acceder a API Manager IFT
- Contactar infraestructura
```

### Completo (4+ horas)

Ver: 11_MANUAL_BUSQUEDA_srvAutoregistro.md

---

## ✅ Soluciones

### Opción A: Encontrar srvAutoregistro (Recomendado)
```
1. Ubicar código (documento 11)
2. Compilar para CRT
3. Publicar en API Manager CRT
4. Desplegar FEDI con nuevas URLs
5. Probar y validar
Tiempo: 1-2 semanas
```

### Opción B: Reconstruir desde Cero
```
1. Usar especificación de 4 endpoints
2. Implementar servicio REST
3. Conectar a BD PERITOS
4. Publicar en API Manager CRT
5. Probar y validar
Tiempo: 2-3 semanas
```

---

## 📊 Impacto

| Funcionalidad | Estado | % Bloqueado |
|---|---|---|
| Login | ✅ Funciona | 0% |
| Crear documentos | ✅ Funciona | 0% |
| Ver documentos | ✅ Funciona | 0% |
| **Asignar firmantes** | ❌ BLOQUEADO | **30%** |
| Firmar documentos | ⚠️ Sin firmantes | **30%** |
| Exportar/Descargar | ✅ Funciona | 0% |

**Línea de fondo:** ~30% de funcionalidad bloqueada sin srvAutoregistro

---

## 🚨 Acción Inmediata

```
[ ] Leer: 10_RESUMEN_EJECUTIVO_FEDI_PERITOS_CRT.md (5 min)
[ ] Ejecutar: 11_MANUAL_BUSQUEDA_srvAutoregistro.md (30 min)
[ ] Reportar: Ubicación de srvAutoregistro
[ ] Resolver: Publicar en API Manager CRT (1-2 semanas)
```

---

## 📞 Contactar

**Si eres:**
- **Directivo:** Leer documento 10 (5 min)
- **Infraestructura:** Ejecutar documento 11 (30 min)
- **Desarrollo:** Leer documentos 07+08 (45 min)
- **Ejecutivo:** Este documento (2 min) ✅

---

## 📄 Documentación Completa

- 00_INDICE_COMPLETO_ANALISIS_FEDI_PERITOS.md ← **Empieza aquí**
- 10_RESUMEN_EJECUTIVO_FEDI_PERITOS_CRT.md ← Ejecutivos
- 11_MANUAL_BUSQUEDA_srvAutoregistro.md ← Búsqueda
- 07_MAPEO_METODOS_CONSUMO_PERITOS.md ← Desarrolladores
- 08_DIAGRAMA_ARQUITECTURA_FEDI_PERITOS.md ← Técnicos

---

**Estado:** 🔴 BLOQUEADOR CRÍTICO IDENTIFICADO  
**Próximo:** Buscar srvAutoregistro  
**Timeline:** +1-2 semanas para resolver  
**Riesgo:** Funcionalidad ~30% bloqueada sin esto
