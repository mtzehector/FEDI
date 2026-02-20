import re

file_path = r'fedi-web\fedi-web\src\main\java\fedi\ift\org\mx\exposition\ValidarDocumentoMB.java'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find key lines and insert logs
for i, line in enumerate(lines):
    # PASO 1: After line with "if (responseDatosDocumento != null && responseDatosDocumento.getError().equals("false") && responseDatosDocumento.getCode() == 102)"
    if 'responseDatosDocumento.getCode() == 102)' in line and 'PASO 1' not in ''.join(lines[max(0,i-2):i+3]):
        lines[i] = line.rstrip() + '\n\t\t\t\tLOGGER.info(">>> Validacion PASO 1: Respuesta valida (code=102, error=false)");\n'

    # PASO 2: After "if (!responseDatosDocumento.getListaDocumentos().isEmpty())"
    elif '.getListaDocumentos().isEmpty())' in line and 'PASO 2' not in ''.join(lines[max(0,i-2):i+3]):
        lines[i] = line.rstrip() + '\n\t\t\t\t\tLOGGER.info(">>> Validacion PASO 2: Lista contiene {} documento(s)", responseDatosDocumento.getListaDocumentos().size());\n'

    # PASO 3: After "for (Documento doc : responseDatosDocumento.getListaDocumentos())"
    elif 'for (Documento doc : responseDatosDocumento.getListaDocumentos())' in line and 'PASO 3' not in ''.join(lines[max(0,i-2):i+3]):
        lines[i] = line.rstrip() + '\n\t\t\t\t\t\tLOGGER.info(">>> Validacion PASO 3: Iterando documento - Nombre: {}, Status: {}", doc.getNombreDocumento(), doc.getDocumentoEstatus() != null ? doc.getDocumentoEstatus().getIdDocumentoEstatus() : "NULL");\n'

    # PASO 4: After "if (nombreDocumento.equals(nombreDocumentoSeleccionado))" - first occurrence in validarDocumento()
    elif 'if (nombreDocumento.equals(nombreDocumentoSeleccionado))' in line and i > 500 and i < 600 and 'PASO 4' not in ''.join(lines[max(0,i-2):i+3]):
        lines[i] = line.rstrip() + '\n\t\t\t\t\t\t\tLOGGER.info(">>> Validacion PASO 4: Nombres coinciden - DB: \\"{}\\", Cargado: \\"{}\\", nombreDocumento, nombreDocumentoSeleccionado);\n'

    # PASO 5: After "if (doc.getDocumentoEstatus().getIdDocumentoEstatus() == 1 || doc.getDocumentoEstatus().getIdDocumentoEstatus() == 2)"
    elif 'getDocumentoEstatus().getIdDocumentoEstatus() == 1 ||' in line and 'PASO 5' not in ''.join(lines[max(0,i-2):i+3]):
        lines[i] = line.rstrip() + '\n\t\t\t\t\t\t\t\tLOGGER.info(">>> Validacion PASO 5: Documento aun en proceso (status: {})", doc.getDocumentoEstatus().getIdDocumentoEstatus());\n'

    # PASO 6: After "hash = Utils.crearCadenaMD5(...)"
    elif 'hash = Utils.crearCadenaMD5(doc.getNombreDocumento()' in line and 'PASO 6' not in ''.join(lines[max(0,i-2):i+3]):
        lines[i] = line.rstrip() + '\n\t\t\t\t\t\t\tLOGGER.info(">>> Validacion PASO 6: Hash generado MD5: {}", hash);\n'

    # PASO 7: After "String name = info.get("Keywords");"
    elif 'String name = info.get("Keywords");' in line and i > 500 and i < 600 and 'PASO 7' not in ''.join(lines[max(0,i-2):i+3]):
        lines[i] = line.rstrip() + '\n\t\t\t\t\t\t\tLOGGER.info(">>> Validacion PASO 7: Keywords del PDF: {}", name);\n'

    # PASO 8: After "if (name.equals(hash))"
    elif 'if (name.equals(hash))' in line and i > 500 and i < 600 and 'PASO 8' not in ''.join(lines[max(0,i-2):i+3]):
        lines[i] = line.rstrip() + '\n\t\t\t\t\t\t\t\tLOGGER.info(">>> Validacion PASO 8: Hash COINCIDE - PDF valido");\n'

    # PASO 9: After "cargarFirmantes(doc.getIdDocumento())"
    elif 'this.firmantesDocumentoSeleccionado = cargarFirmantes(doc.getIdDocumento());' in line and 'PASO 9' not in ''.join(lines[max(0,i-2):i+3]):
        lines[i] = line.rstrip() + '\n\t\t\t\t\t\t\t\t\tLOGGER.info(">>> Validacion PASO 9: Cargados {} firmantes para validar", this.firmantesDocumentoSeleccionado.size());\n'

    # PASO 10: After "for (Firmante firmante : this.firmantesDocumentoSeleccionado)"
    elif 'for (Firmante firmante : this.firmantesDocumentoSeleccionado)' in line and i > 500 and i < 600 and 'PASO 10' not in ''.join(lines[max(0,i-2):i+3]):
        lines[i] = line.rstrip() + '\n\t\t\t\t\t\t\t\t\t\tLOGGER.info(">>> Validacion PASO 10: Validando firmante: {} {} {}", firmante.getNombre(), firmante.getApellidoPaterno(), firmante.getApellidoMaterno());\n'

    # PASO 11: After "if (valorPdfFirmante == false)"
    elif 'if (valorPdfFirmante == false)' in line and i > 500 and i < 600 and 'PASO 11' not in ''.join(lines[max(0,i-2):i+3]):
        lines[i] = line.rstrip() + '\n\t\t\t\t\t\t\t\t\t\t\tLOGGER.warn(">>> Validacion PASO 11: Firmante NO encontrado en PDF: {}", nombre.toUpperCase());\n'

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('OK - Logs detallados agregados')
