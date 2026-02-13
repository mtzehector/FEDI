# 📋 Observación Crítica: SQL Server, NO Oracle

**Fecha:** 12-Feb-2026  
**Actualizado por:** Usuario  
**Impacto:** CRÍTICO - Afecta la compilación y configuración de datasources

---

## ✅ Dato Corregido

**Base de datos FEDI:** Microsoft SQL Server (NO Oracle)

### Implicaciones

| Aspecto | SQL Server | Oracle |
|---------|-----------|--------|
| **Driver JDBC** | `mssql-jdbc` o `jtds` | `ojdbc6` |
| **URL Conexión** | `jdbc:sqlserver://host:1433;databaseName=FEDI` | `jdbc:oracle:thin:@host:1521:SID` |
| **Clase Driver** | `com.microsoft.sqlserver.jdbc.SQLServerDriver` | `oracle.jdbc.OracleDriver` |
| **pom.xml** | Debe incluir `mssql-jdbc` | ~~`ojdbc6` (comentado)~~ |
| **Configuración JNDI** | DataSource SQL Server | DataSource Oracle |

---

## 🔍 Ubicación de la Base de Datos

**Información a verificar en el servidor:**

1. ¿En qué servidor está instalado SQL Server?
   ```
   IP: ?
   Puerto: 1433 (por defecto)
   Base de datos: FEDI (o similar)
   Usuario: ?
   Contraseña: ?
   ```

2. **Configuración en Tomcat `server.xml`:**
   ```xml
   <Resource name="jdbc/fedi_pool"
             auth="Container"
             type="javax.sql.DataSource"
             maxTotal="32"
             maxIdle="10"
             maxWaitMillis="30000"
             username="USUARIO_SQL"
             password="PASSWORD_SQL"
             driverClassName="com.microsoft.sqlserver.jdbc.SQLServerDriver"
             url="jdbc:sqlserver://HOST:1433;databaseName=FEDI"/>
   </Resource>
   ```

---

## 📝 Cambios a Realizar en pom.xml

**Necesario:**

```xml
<!-- SQL Server JDBC Driver -->
<dependency>
    <groupId>com.microsoft.sqlserver</groupId>
    <artifactId>mssql-jdbc</artifactId>
    <version>9.4.1.jre8</version>
</dependency>
```

**Estado actual en pom.xml:**
- ❌ ojdbc6 comentado (correcto - no es Oracle)
- ⏳ Necesita incluir SQL Server driver

---

## 🔗 Referencia

- [pom.xml](../fedi-srv/pom.xml) - Modificar si es necesario
- [applicationContext-datasource-jndi.xml](../fedi-srv/src/main/resources/spring/applicationContext-datasource-jndi.xml) - Configuración JNDI
- [Logs de despliegue](Logs_fedi_web_ambiente_dev.txt) - Verificar en el análisis siguiente

---

**Recordatorio:** No compilar hasta confirmar la dependencia correcta de SQL Server.
