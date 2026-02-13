@echo off
REM ========================================================================
REM Script de Despliegue Automatizado - FEDI REST Timeout Fix
REM Autor: GitHub Copilot
REM Fecha: 2026-02-08
REM ========================================================================

setlocal enabledelayedexpansion
cls

echo.
echo ========================================================================
echo   DESPLIEGUE AUTOMATIZADO - FEDI REST Timeout Fix
echo ========================================================================
echo.

REM Variables
set TOMCAT_HOME=C:\Tomcat
set WEBAPPS_PATH=%TOMCAT_HOME%\webapps
set WAR_SOURCE=C:\github\fedi-web\target\FEDIPortalWeb-1.0.war
set WAR_DEST=%WEBAPPS_PATH%\FEDIPortalWeb.war
set LOGS_PATH=%TOMCAT_HOME%\logs
set TIMESTAMP=%date:~-4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%

echo [1/6] Validando archivos necesarios...
if not exist "%WAR_SOURCE%" (
    echo.
    echo [ERROR] WAR no encontrado en: %WAR_SOURCE%
    echo Asegúrate de haber ejecutado: mvn clean install -P development-oracle1 -DskipTests
    echo.
    pause
    exit /b 1
)
echo [✓] WAR encontrado: %WAR_SOURCE%

echo.
echo [2/6] Deteniendo servicio Tomcat...
net stop Tomcat >nul 2>&1
if %errorlevel% equ 0 (
    echo [✓] Tomcat detenido correctamente
) else (
    echo [!] Tomcat ya estaba detenido o no se pudo detener
)
timeout /t 3 /nobreak

echo.
echo [3/6] Limpiando cache de Tomcat...
if exist "%TOMCAT_HOME%\work\Catalina\localhost\FEDIPortalWeb" (
    rmdir /s /q "%TOMCAT_HOME%\work\Catalina\localhost\FEDIPortalWeb"
    echo [✓] Directorio work eliminado
)
if exist "%WEBAPPS_PATH%\FEDIPortalWeb" (
    rmdir /s /q "%WEBAPPS_PATH%\FEDIPortalWeb"
    echo [✓] Directorio webapps/FEDIPortalWeb eliminado
)

echo.
echo [4/6] Realizando backup del WAR anterior...
if exist "%WAR_DEST%" (
    set BACKUP_PATH=%WEBAPPS_PATH%\FEDIPortalWeb-backup-%TIMESTAMP%.war
    copy "%WAR_DEST%" "!BACKUP_PATH!" >nul
    echo [✓] Backup creado: !BACKUP_PATH!
)

echo.
echo [5/6] Copiando nuevo WAR...
copy "%WAR_SOURCE%" "%WAR_DEST%" >nul
if %errorlevel% equ 0 (
    echo [✓] WAR copiado exitosamente: %WAR_DEST%
) else (
    echo [ERROR] Fallo al copiar WAR
    pause
    exit /b 1
)

echo.
echo [6/6] Iniciando servicio Tomcat...
net start Tomcat >nul 2>&1
if %errorlevel% equ 0 (
    echo [✓] Tomcat iniciado correctamente
) else (
    echo [ERROR] Fallo al iniciar Tomcat
    pause
    exit /b 1
)

echo.
echo ========================================================================
echo   DESPLIEGUE COMPLETADO ✓
echo ========================================================================
echo.
echo Esperando despliegue de aplicación (30 segundos)...
echo.
timeout /t 30 /nobreak

echo.
echo ========================================================================
echo   VALIDACIÓN
echo ========================================================================
echo.

REM Verificar estado de Tomcat
for /f %%A in ('net start ^| find /c "Tomcat"') do set TOMCAT_RUNNING=%%A
if "%TOMCAT_RUNNING%"=="1" (
    echo [✓] Tomcat está ejecutándose
) else (
    echo [!] No se pudo confirmar que Tomcat está ejecutándose
    echo    Revisar manualmente con: net start
)

REM Verificar que la aplicación está desplegada
if exist "%WEBAPPS_PATH%\FEDIPortalWeb" (
    echo [✓] Aplicación desplegada en: %WEBAPPS_PATH%\FEDIPortalWeb
) else (
    echo [!] La aplicación aún no está desplegada, esperar un momento más...
    timeout /t 10 /nobreak
    if exist "%WEBAPPS_PATH%\FEDIPortalWeb" (
        echo [✓] Aplicación desplegada exitosamente
    ) else (
        echo [!] La aplicación aún no está disponible
    )
)

echo.
echo ========================================================================
echo   PRÓXIMOS PASOS
echo ========================================================================
echo.
echo 1. Abre tu navegador en: https://fedi-dev.ift.org.mx/FEDIPortalWeb
echo.
echo 2. Inicia sesión con tus credenciales
echo.
echo 3. Espera a que cargue el caché inicial
echo    (Ahora puede tomar 15-20 segundos en lugar de fallar)
echo.
echo 4. Intenta guardar un documento
echo    Debe funcionar sin error de timeout ✓
echo.
echo 5. Monitorea los logs para validar tiempos de respuesta:
echo    Archivo: %LOGS_PATH%\catalina.out
echo    Busca: "[MDSeguridadService.EjecutaMetodoGET] exitoso"
echo.
echo ========================================================================
echo.
echo Para más detalles, revisa:
echo - RESUMEN_SOLUCION_TIMEOUT.md
echo - PLAN_DESPLIEGUE_REST_TIMEOUT.md
echo - ANALISIS_DIAGNOSTICO_REST_TIMEOUT.md
echo.

pause
