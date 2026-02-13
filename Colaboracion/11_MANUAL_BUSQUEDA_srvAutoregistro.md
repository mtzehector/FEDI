# MANUAL DE BÚSQUEDA: Cómo Localizar srvAutoregistro

**Documento de Referencia Técnica**

---

## 1. Búsqueda en Repositorio Local

### 1.1 Comando Básico

```bash
cd c:\github
find . -iname "*autoregistro*" -o -iname "*srvAuto*"
```

**Si está en el directorio:** Encontrará todos los archivos con esos nombres.

---

### 1.2 Búsqueda en Archivos Java

```bash
# Buscar mentions de srvAutoregistro en código
grep -r "srvAutoregistro" . --include="*.java" | head -20

# Resultado esperado:
# ./fedi-web/.../AdminUsuariosServiceImpl.java (consumidor) ✅
# ./msperitos-admin/.../AdminUsuariosServiceImpl.java (consumidor) ✅
# Nada más = servicio NO ESTÁ EN REPOS ❌
```

---

### 1.3 Búsqueda en Archivos WARs

```bash
# Buscar en WAR files
cd c:\github\PREANALISIS_CPCREL

# Listar contenido de todos los WARs
for file in WAR*/*.war WAR*/*.jar; do
    echo "=== $file ==="
    unzip -l "$file" | grep -i "autoregistro\|registro"
done

# O más específico:
unzip -l "WAR2026/*.war" | grep -i "AutoregistroWS\|RegistroWS"
```

---

### 1.4 Búsqueda en Properties/XML

```bash
# Buscar en pom.xml
grep -r "srvAutoregistro\|autoregistro" . --include="pom.xml"

# Buscar en application.properties
grep -r "autoregistro" . --include="*.properties"

# Resultado esperado:
# profile.autoregistro.url=... ✅
# Indica que el servicio DEBERÍA EXISTIR
```

---

## 2. Búsqueda en Git

### 2.1 Ver Historial de Commits

```bash
# ¿Se mencionó srvAutoregistro en commits?
cd c:\github\fedi-web
git log --all --grep="autoregistro" --oneline

# ¿Se mencionó en cambios de archivos?
git log -S "srvAutoregistro" --oneline

# Resultado esperado:
# Commit: "Add srvAutoregistro integration" (por ejemplo)
# Si no hay: Nunca estuvo en Git
```

---

### 2.2 Ver Todos los Repositorios

```bash
# Listar todos los repos clonados
for dir in c:\github\*; do
    if [ -d "$dir/.git" ]; then
        echo "=== $(basename $dir) ==="
        cd "$dir"
        git remote -v
    fi
done

# Resultado esperado:
# origin: https://github.com/IFT/fedi-web.git
# origin: https://github.com/IFT/msperitos-admin.git
# etc.
# Buscar si hay repo: https://github.com/IFT/srvAutoregistro.git
```

---

### 2.3 Buscar en GitHub Online

```bash
# Desde navegador:
# https://github.com/search?q=srvAutoregistro+org:IFT
# https://github.com/search?q=autoregistro+org:IFT
# https://github.com/search?q=RegistroWS+org:IFT
```

---

## 3. Búsqueda en API Manager IFT

### 3.1 Acceder al Portal

```
URL: https://apimanager-dev.ift.org.mx
Usuario: (credenciales del equipo)
Contraseña: (credenciales del equipo)
```

### 3.2 Buscar API Publicada

```
Menú: APIs → APIs de Aplicación
Buscar: "srvAutoregistro" o "autoregistro"

Si encuentra:
└─ Hacer clic para ver detalles
   ├─ Versión
   ├─ Endpoint backend
   ├─ Status
   └─ Última actualización
```

### 3.3 Información a Obtener

```
Nombre de API: srvAutoregistroQA
Versión: 3.0 (?)
Basepath: /srvAutoregistroQA/v3.0/

Backend Endpoint: http://[HOST]:[PORT]/srvAutoregistro/
├─ HOST: ¿Dónde está deployado?
└─ PORT: ¿Qué puerto usa?

Oauth2 Scopes: (cuáles usa)
Policies: (qué políticas están activas)
```

---

## 4. Búsqueda en Infraestructura

### 4.1 Contactos

```
Equipo de Infraestructura IFT
├─ Correo: infra@ift.org.mx (?)
├─ Slack: #infraestructura
└─ Teléfono: Extensión XXXX

Equipo de DevOps
├─ Responsable: [NOMBRE]
└─ Correo: [EMAIL]
```

### 4.2 Preguntas a Hacer

```
1. ¿Dónde está deployado srvAutoregistro?
   └─ Servidor: ?
   └─ Puerto: ?
   └─ Ambiente: DEV/QA/PROD?

2. ¿Está el código en Git?
   └─ Repositorio: ?
   └─ URL: ?
   └─ Rama: ?

3. ¿Cómo se hizo el deployment actual?
   └─ Manual o automatizado?
   └─ Hay documentación?
   └─ Quién lo maintiene?

4. ¿Existe backup de código?
   └─ WAR/JAR file?
   └─ Ubicación?
   └─ Cuándo se actualizó por última vez?

5. ¿Qué tecnología usa?
   └─ Spring Boot? Spring MVC? Otra?
   └─ JDK version?
   └─ Tomcat/JBoss/WebLogic?
```

---

## 5. Extracción desde WAR/JAR

### 5.1 Si Encuentras un WAR

```bash
# Extraer contenido
mkdir extracted_war
cd extracted_war
unzip ../srvAutoregistro.war

# Ver estructura
tree .
# o
find . -type f -name "*.class" | grep -i "RegistroWS\|RolesController"

# Extraer source (si tiene)
unzip -l srvAutoregistro.war | grep ".java"
# Si no tiene, el código está compilado
```

### 5.2 Si el Código Está Compilado

```bash
# Descompilar JAR/WAR
# Opción 1: Usar CFR (modern Java decompiler)
java -jar cfr.jar srvAutoregistro.jar --outputdir src

# Opción 2: Usar Procyon
procyon -o src srvAutoregistro.jar

# Opción 3: Usar JD-GUI (UI)
jd-gui srvAutoregistro.jar
```

---

## 6. Validación de URLs

### 6.1 Test de Conectividad

```bash
# ¿Responde API Manager IFT en dev?
curl -I http://apimanager-dev.ift.org.mx:8280/

# ¿Responde en QA?
curl -I http://apimanager-qa.ift.org.mx/

# ¿Responde API Manager CRT?
curl -I http://apimanager-qa.crt.gob.mx/

# ¿Está publicado srvAutoregistro?
curl -I https://apimanager-dev.ift.org.mx/srvAutoregistroQA/v3.0/

# ¿Funciona el endpoint de roles?
curl -I "https://apimanager-dev.ift.org.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT"
```

### 6.2 Test de Autenticación

```bash
# Obtener token
curl -X POST http://apimanager-dev.ift.org.mx:8280/token \
  -H "Authorization: Basic VGZxc3BCYWVYZHhCNlF0SUJHV0EzZUxpMkw0YTpWTUdUVHhqUDVkMl91eFoxdW5uSVBSTGpmZ01h" \
  -d "grant_type=client_credentials" \
  -v

# Resultado esperado: access_token en respuesta

# Usar token para llamar endpoint
TOKEN="[access_token_aqui]"
curl -X GET "https://apimanager-dev.ift.org.mx/srvAutoregistroQA/v3.0/registro/consultas/roles/2/1/0015MSPERITOSDES-INT" \
  -H "Authorization: Bearer $TOKEN" \
  -v
```

---

## 7. Búsqueda Paso a Paso

### Paso 1: Verificar lo Obvio

```bash
# ¿Existe C:\github\srvAutoregistro?
ls -la c:\github\srvAutoregistro\

# ¿Existe en PREANALISIS_CPCREL?
find c:\github\PREANALISIS_CPCREL -iname "*autoregistro*" -o -iname "*srvAuto*"

# ¿Hay otros directorios?
ls c:\github\
```

### Paso 2: Buscar en Git

```bash
# Todos los repos clonados
cd c:\github
for dir in */; do
    if [ -d "$dir/.git" ]; then
        echo "=== $dir ==="
        cd "$dir"
        git remote -v | grep -i autoregistro || echo "No encontrado"
        cd ..
    fi
done
```

### Paso 3: Búsqueda Online

```bash
# GitHub
https://github.com/search?q=srvAutoregistro+org:IFT+language:java

# GitLab (si usan)
https://gitlab.ift.org.mx/search?search=srvAutoregistro

# Bitbucket (si usan)
https://bitbucket.ift.org.mx/search?name=srvAutoregistro
```

### Paso 4: Contactar Infraestructura

```
Correo: "¿Dónde está el código de srvAutoregistro?"
Adjuntar: Este documento
Solicitar: Ubicación exacta del código fuente
```

### Paso 5: Plan B - Si No Se Encuentra

```bash
# Opción A: Obtener del WAR deployado
# ¿Dónde está deployado srvAutoregistro en producción?
# → Contactar infraestructura
# → Obtener el WAR/JAR
# → Extraer el código compilado
# → Descompilar

# Opción B: Reconstruir desde cero
# Usar información de:
# - FEDI/AdminUsuariosServiceImpl.java (cómo se consume)
# - Modelos de datos (ResponseRoles.java, Role.java)
# - Endpoints esperados (documentados en este análisis)
# → Crear nuevo srvAutoregistro basado en especificación
# → Implementar endpoints 1-4 listados arriba
```

---

## 8. Checklist de Búsqueda

```
FASE 1: Búsqueda Local
├─ [ ] Ejecutar: find . -iname "*autoregistro*"
├─ [ ] Ejecutar: grep -r "srvAutoregistro" . --include="*.java"
├─ [ ] Revisar: C:\github\PREANALISIS_CPCREL\WAR*\
├─ [ ] Revisar: C:\github\ (listar directorios)
└─ Resultado: [ ] Encontrado [ ] No encontrado

FASE 2: Búsqueda en Git
├─ [ ] git log --grep="autoregistro"
├─ [ ] git log -S "srvAutoregistro"
├─ [ ] Revisar remotes: git remote -v
└─ Resultado: [ ] Encontrado [ ] No encontrado

FASE 3: Búsqueda en GitHub
├─ [ ] Ir a: https://github.com/search
├─ [ ] Buscar: "srvAutoregistro" + "org:IFT"
├─ [ ] Buscar: "autoregistro" + "org:IFT"
└─ Resultado: [ ] Encontrado [ ] No encontrado

FASE 4: Búsqueda en API Manager
├─ [ ] Acceder: https://apimanager-dev.ift.org.mx
├─ [ ] Buscar API: "srvAutoregistro"
├─ [ ] Anotar: Backend endpoint
└─ Resultado: [ ] Encontrado [ ] No encontrado

FASE 5: Contactar Infraestructura
├─ [ ] Enviar correo con preguntas del manual
├─ [ ] Preguntar ubicación exacta
├─ [ ] Solicitar acceso al repositorio
└─ Resultado: [ ] Información obtenida [ ] En espera

FASE 6: Plan B (Si no se encuentra)
├─ [ ] Obtener WAR deployado
├─ [ ] Descompilar código
├─ [ ] O: Reconstruir desde especificación
└─ Resultado: [ ] Código disponible [ ] Requiere desarrollo
```

---

## 9. Documentación de Resultados

### Template de Reporte

```markdown
# Búsqueda de srvAutoregistro - Reporte Final

**Fecha:** [FECHA]
**Responsable:** [NOMBRE]

## Resultados de Búsqueda

### Fase 1: Local
- [ ] Encontrado en: [RUTA] o [ ] No encontrado
- Evidencia: [DETALLES]

### Fase 2: Git
- [ ] Encontrado en repo: [URL] o [ ] No encontrado
- Branch: [NOMBRE]
- Commits: [CANTIDAD]

### Fase 3: GitHub
- [ ] Encontrado en: [URL] o [ ] No encontrado
- Versión actual: [VERSION]
- Última actualización: [FECHA]

### Fase 4: API Manager IFT
- [ ] API publicada: Sí/No
- Backend endpoint: [URL]
- Status: [ACTIVA/INACTIVA]

### Fase 5: Infraestructura
- Contacto: [NOMBRE]
- Respuesta recibida: [FECHA]
- Información: [DETALLES]

## Conclusión

✅ srvAutoregistro ENCONTRADO
└─ Ubicación: [RUTA O URL]
└─ Siguiente paso: Obtener código y comenzar migración

O

❌ srvAutoregistro NO ENCONTRADO
└─ Razón: [DESCRIPCIÓN]
└─ Siguiente paso: Ejecutar Plan B (Reconstruir o descompilar)

## Archivos Obtenidos

- [ ] Código fuente (pom.xml, *.java)
- [ ] WAR/JAR compilado
- [ ] Documentación API
- [ ] Base de datos schema
- [ ] Tests unitarios
```

---

**Fin del Manual de Búsqueda**

Use estos comandos sistemáticamente para localizar srvAutoregistro. Cada fase debería tomar 15-30 minutos.

**Tiempo total estimado:** 3-4 horas para completar todas las fases.

Si después de todas estas búsquedas no lo encuentra, ejecute **Plan B: Reconstrucción desde especificación**.
