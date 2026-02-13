# CURLs para Consultar Firmantes - FEDI

## Análisis del código FEDI

- **Servicio**: `FEDIServiceImpl.java:246-265`
- **Endpoint**: `{profile.fedi.url}/fedi/consultarFirmantes`
- **Método**: POST
- **Modelo Request**: `RequestFEDI.java` con `listaFirmantes`
- **Modelo Response**: `ResponseFEDI.java` con `listaFirmantes`

## URLs según el ambiente

### Desarrollo:
```
https://apimanager-dev.ift.org.mx/FEDI/v1.0/fedi/consultarFirmantes
```

### QA (ambiente activo):
```
https://apimanager-qa.ift.org.mx/FEDI/v3.0/fedi/consultarFirmantes
```

### Producción:
```
https://apimanager.ift.org.mx/FEDI/v2.0/fedi/consultarFirmantes
```

---

## CURLs para Ambiente QA (Activo)

### 1. Obtener Token de Acceso
```bash
curl -X POST "https://apimanager-qa.ift.org.mx/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Authorization: Basic V3FsMVBMdmpvZTh6U0RfNHFTRWIyNEhTOWZBYTpFeExrVEFsOEY0eEkxZ1BjaHh5Rk5TblFYQlFh" \
  -d "grant_type=client_credentials"
```

### 2. Consultar Firmantes de un Documento
```bash
curl -X POST "https://apimanager-qa.ift.org.mx/FEDI/v3.0/fedi/consultarFirmantes" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {TOKEN_DE_ACCESO}" \
  -d '{
    "idDocumento": 123,
    "nombreDocumento": "documento.pdf"
  }'
```

---

## CURLs para Ambiente Desarrollo

### 1. Obtener Token de Acceso
```bash
curl -X POST "https://apimanager-dev.ift.org.mx/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Authorization: Basic VGZxc3BCYWVYZHhCNlF0SUJHV0EzZUxpMkw0YTpWTUdUVHhqUDVkMl91eFoxdW5uSVBSTGpmZ01h" \
  -d "grant_type=client_credentials"
```

### 2. Consultar Firmantes de un Documento
```bash
curl -X POST "https://apimanager-dev.ift.org.mx/FEDI/v1.0/fedi/consultarFirmantes" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {TOKEN_DE_ACCESO}" \
  -d '{
    "idDocumento": 123,
    "nombreDocumento": "documento.pdf"
  }'
```

---

## CURLs para Ambiente Producción

### 1. Obtener Token de Acceso
```bash
curl -X POST "https://apimanager.ift.org.mx/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Authorization: Basic TUo5ZnVHTnhDeWt2b0ROSlE4V25qTmg1a0tZYTpLWndCUXFHNHNibmRqVEI2RnpraEdnUzdNcnNh" \
  -d "grant_type=client_credentials"
```

### 2. Consultar Firmantes de un Documento
```bash
curl -X POST "https://apimanager.ift.org.mx/FEDI/v2.0/fedi/consultarFirmantes" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {TOKEN_DE_ACCESO}" \
  -d '{
    "idDocumento": 123,
    "nombreDocumento": "documento.pdf"
  }'
```

---

## Modelo de RequestFEDI

```json
{
  "idDocumento": 123,
  "nombreDocumento": "documento.pdf",
  "sistemaOrigen": "FEDI"
}
```

## Modelo de Respuesta Esperado (ResponseFEDI)

```json
{
  "codigo": "0000",
  "mensaje": "Éxito",
  "listaFirmantes": [
    {
      "idUsuario": "usuario@ejemplo.com",
      "posicion": 1,
      "nombre": "Juan",
      "apellidoPaterno": "Pérez",
      "apellidoMaterno": "García",
      "fechaFirma": "2026-02-04",
      "horaFirma": "10:30:00",
      "hash": "md5hash123...",
      "nombreDocumento": "documento.pdf",
      "unidadAdministrativa": "Unidad X"
    }
  ]
}
```

## Campos del Modelo Firmante

| Campo | Tipo | Descripción |
|-------|------|-------------|
| idUsuario | String | Identificador del usuario firmante |
| posicion | Integer | Posición en la lista de firmantes |
| nombre | String | Nombre del firmante |
| apellidoPaterno | String | Apellido paterno |
| apellidoMaterno | String | Apellido materno |
| fechaFirma | String | Fecha de la firma |
| horaFirma | String | Hora de la firma |
| hash | String | Hash MD5 de la firma |
| nombreDocumento | String | Nombre del documento firmado |
| unidadAdministrativa | String | Unidad administrativa del firmante |

---

## Ejemplo Completo con Token y Consulta (QA)

```bash
# Paso 1: Obtener token
TOKEN_RESPONSE=$(curl -X POST "https://apimanager-qa.ift.org.mx/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Authorization: Basic V3FsMVBMdmpvZTh6U0RfNHFTRWIyNEhTOWZBYTpFeExrVEFsOEY0eEkxZ1BjaHh5Rk5TblFYQlFh" \
  -d "grant_type=client_credentials")

# Paso 2: Extraer access_token (requiere jq)
ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.access_token')

# Paso 3: Consultar firmantes
curl -X POST "https://apimanager-qa.ift.org.mx/FEDI/v3.0/fedi/consultarFirmantes" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "idDocumento": 123,
    "nombreDocumento": "documento.pdf"
  }'
```

---

## Notas

- Reemplazar `{TOKEN_DE_ACCESO}` con el token obtenido del primer paso
- Reemplazar `123` con el ID del documento real
- Reemplazar `"documento.pdf"` con el nombre del documento real
- Los tokens de autorización Basic están configurados en el `pom.xml` del proyecto
- El ambiente QA es el activo por defecto según `pom.xml:769`

## Referencias del Código

- Implementación del servicio: `src/main/java/fedi/ift/org/mx/service/FEDIServiceImpl.java:246`
- Interface del servicio: `src/main/java/fedi/ift/org/mx/service/FEDIService.java:29`
- Modelo Firmante: `src/main/java/fedi/ift/org/mx/model/Firmante.java`
- Modelo Request: `src/main/java/fedi/ift/org/mx/model/RequestFEDI.java`
- Modelo Response: `src/main/java/fedi/ift/org/mx/model/ResponseFEDI.java`
