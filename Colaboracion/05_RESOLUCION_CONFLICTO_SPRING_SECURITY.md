# Resolución de Conflicto de Versiones Spring Security 4.0.0

**Fecha:** 9 de Febrero de 2026  
**Problema:** Error 404 al desplegar con Spring Security 4.0.0.RELEASE  
**Causa Raíz:** Schema XML incompatible en `applicationContext-security.xml`

## Problema Identificado

El archivo `applicationContext-security.xml` en `fedi-web` utilizaba:
```xml
http://www.springframework.org/schema/beans/spring-beans-3.1.xsd
http://www.springframework.org/schema/security/spring-security-3.1.xsd
```

Mientras que el proyecto estaba configurado con:
```xml
<org.springframework.version>4.0.0.RELEASE</org.springframework.version>
<org.springframework.security.version>4.0.0.RELEASE</org.springframework.security.version>
```

### Error en los Logs:

**Error 1 - Schema Incompatible:**
```
BeanDefinitionParsingException: Configuration problem: You cannot use a spring-security-2.0.xsd 
or spring-security-3.0.xsd or spring-security-3.1.xsd schema with Spring Security 3.2. 
Please update your schema declarations to the 3.2 schema.
```

**Error 2 - Atributo Deprecado:**
```
XmlBeanDefinitionStoreException: Line 15 in XML document from ServletContext resource 
[/WEB-INF/classes/spring/applicationContext-security.xml] is invalid; 
nested exception is org.xml.sax.SAXParseException; lineNumber: 15; columnNumber: 56; 
cvc-complex-type.3.2.2: Attribute 'access-denied-page' is not allowed to appear in element 'http'.
```

**Error 3 - Constructor TokenBasedRememberMeServices:**
```
BeanInstantiationException: Could not instantiate bean class 
[org.springframework.security.web.authentication.rememberme.TokenBasedRememberMeServices]: 
No default constructor found; nested exception is java.lang.NoSuchMethodException: 
org.springframework.security.web.authentication.rememberme.TokenBasedRememberMeServices.<init>()
```

## Solución Implementada

### 1. Actualización de Schema en `fedi-web`

**Archivo:** `c:\github\fedi-web\src\main\resources\spring\applicationContext-security.xml`

**Cambio 1 - Schema Version:**
```xml
<!-- ANTES -->
xsi:schemaLocation="http://www.springframework.org/schema/beans 
       http://www.springframework.org/schema/beans/spring-beans-3.1.xsd
       http://www.springframework.org/schema/security 
       http://www.springframework.org/schema/security/spring-security-3.1.xsd"

<!-- DESPUÉS -->
xsi:schemaLocation="http://www.springframework.org/schema/beans 
       http://www.springframework.org/schema/beans/spring-beans-4.0.xsd
       http://www.springframework.org/schema/security 
       http://www.springframework.org/schema/security/spring-security-4.0.xsd"
```

**Cambio 2 - Atributo access-denied-page (Spring Security 4.0):**
```xml
<!-- ANTES -->
<http 
    auto-config="true" 
    access-decision-manager-ref="accessDecisionManager"
    access-denied-page="/content/error/access.jsf">

<!-- DESPUÉS -->
<http 
    auto-config="true" 
    access-decision-manager-ref="accessDecisionManager">
    
    <access-denied-handler error-page="/content/error/access.jsf"/>
```

**Cambio 3 - TokenBasedRememberMeServices Constructor (Spring Security 4.0):**
```xml
<!-- ANTES - Usa beans:property -->
<beans:bean id="rememberMeServices"
            class="org.springframework.security.web.authentication.rememberme.TokenBasedRememberMeServices">
    <beans:property name="key" value="jsfspring-sec" />
    <beans:property name="userDetailsService" ref="usuarioService" />
    <beans:property name="alwaysRemember" value="true" />
    <beans:property name="tokenValiditySeconds" value="60" />
</beans:bean>

<!-- DESPUÉS - Usa beans:constructor-arg -->
<beans:bean id="rememberMeServices"
            class="org.springframework.security.web.authentication.rememberme.TokenBasedRememberMeServices">
    <beans:constructor-arg value="jsfspring-sec" />
    <beans:constructor-arg ref="usuarioService" />
    <beans:property name="alwaysRemember" value="true" />
    <beans:property name="tokenValiditySeconds" value="60" />
</beans:bean>
```

**Cambio 4 - AffirmativeBased AccessDecisionManager Constructor (Spring Security 4.0):**
```xml
<!-- ANTES - Usa beans:property -->
<beans:bean id="accessDecisionManager"
            class="org.springframework.security.access.vote.AffirmativeBased">
    <beans:property name="decisionVoters">
        <beans:list>
            <beans:ref bean="decisorDeRoles" />
            <beans:ref bean="decisorDeAutenticacion" />
        </beans:list>
    </beans:property>
</beans:bean>

<!-- DESPUÉS - Usa beans:constructor-arg -->
<beans:bean id="accessDecisionManager"
            class="org.springframework.security.access.vote.AffirmativeBased">
    <beans:constructor-arg>
        <beans:list>
            <beans:ref bean="decisorDeRoles" />
            <beans:ref bean="decisorDeAutenticacion" />
        </beans:list>
    </beans:constructor-arg>
</beans:bean>
```

**Motivo:** En Spring Security 4.0, el atributo `access-denied-page` fue deprecado y debe reemplazarse por el elemento `<access-denied-handler>` con el atributo `error-page`.

### 2. Recompilación

Se ejecutaron los siguientes comandos:

```bash
# Para fedi-web
mvn clean install -P development-oracle1 -DskipTests
# Resultado: BUILD SUCCESS

# Para fedi-srv
mvn clean install -P development-oracle1 -DskipTests
# Resultado: BUILD SUCCESS
```

## Archivos Compilados

Los WARs generados están disponibles en:
- `C:\github\fedi-web\target\FEDIPortalWeb-1.0.war`
- `C:\github\fedi-srv\target\srvFEDIApi-1.0.war`

## Próximos Pasos

1. **Desplegar los WARs** en el servidor de aplicaciones (Tomcat, WebLogic, etc.)
2. **Monitorear los logs** para confirmar que la aplicación se inicia correctamente
3. **Verificar acceso** a la aplicación sin errores 404

## Versiones Finales

| Componente | Versión |
|-----------|---------|
| Spring Framework | 4.0.0.RELEASE |
| Spring Security | 4.0.0.RELEASE |
| Java | 1.6 (compilación) / 1.8 (runtime) |
| Maven | 3.x |

## Estado

✅ **Problema 1 resuelto** - Schema XSD actualizado a 4.0  
✅ **Problema 2 resuelto** - Atributo `access-denied-page` reemplazado con `<access-denied-handler>`  
✅ **Problema 3 resuelto** - Constructor de `TokenBasedRememberMeServices` actualizado  
✅ **Problema 4 resuelto** - Constructor de `AffirmativeBased` actualizado  
✅ **Problema 5 resuelto** - Constructor de `RememberMeAuthenticationProvider` actualizado  
✅ **Problema 6 resuelto** - Constructor de `RememberMeAuthenticationFilter` actualizado  
✅ **Compilación exitosa** - Sexta compilación exitosa (BUILD SUCCESS)  
⏳ **Pendiente** - Despliegue y validación en ambiente DEV

**Cambio 5 - RememberMeAuthenticationProvider Constructor (Spring Security 4.0):**
```xml
<!-- ANTES - Usa beans:property -->
<beans:bean id="rememberMeAuthenticationProvider"
            class="org.springframework.security.authentication.RememberMeAuthenticationProvider">
    <beans:property name="key" value="jsfspring-sec"/>
</beans:bean>

<!-- DESPUÉS - Usa beans:constructor-arg -->
<beans:bean id="rememberMeAuthenticationProvider"
            class="org.springframework.security.authentication.RememberMeAuthenticationProvider">
    <beans:constructor-arg value="jsfspring-sec" />
</beans:bean>
```

**Cambio 6 - RememberMeAuthenticationFilter Constructor (Spring Security 4.0):**
```xml
<!-- ANTES - Usa beans:property -->
<beans:bean id="rememberMeFilter"
            class="org.springframework.security.web.authentication.rememberme.RememberMeAuthenticationFilter">
    <beans:property name="rememberMeServices" ref="rememberMeServices"/>
    <beans:property name="authenticationManager" ref="authenticationManager" />
</beans:bean>

<!-- DESPUÉS - Usa beans:constructor-arg -->
<beans:bean id="rememberMeFilter"
            class="org.springframework.security.web.authentication.rememberme.RememberMeAuthenticationFilter">
    <beans:constructor-arg ref="rememberMeServices" />
    <beans:constructor-arg ref="authenticationManager" />
</beans:bean>
```

### 2. Recompilación
