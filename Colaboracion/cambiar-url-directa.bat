@echo off
REM Script para cambiar URL de acceso directo a fedi-srv en pom.xml de fedi-web
REM Uso: cambiar-url-directa.bat [DEV|QA|PROD] [IP-O-HOSTNAME]
REM Ejemplo: cambiar-url-directa.bat DEV localhost
REM Ejemplo: cambiar-url-directa.bat QA 192.168.1.100
REM Ejemplo: cambiar-url-directa.bat PROD srv-fedi.dominio.mx

setlocal enabledelayedexpansion

if "%1"=="" (
    echo.
    echo ERROR: Falta especificar ambiente [DEV^|QA^|PROD]
    echo.
    echo Uso: cambiar-url-directa.bat [AMBIENTE] [IP-O-HOSTNAME] [PUERTO]
    echo.
    echo Ejemplos:
    echo   cambiar-url-directa.bat DEV localhost
    echo   cambiar-url-directa.bat DEV localhost 8080
    echo   cambiar-url-directa.bat QA 192.168.1.100
    echo   cambiar-url-directa.bat QA 192.168.1.100 8080
    echo   cambiar-url-directa.bat PROD srv-fedi.dominio.mx
    echo.
    exit /b 1
)

if "%2"=="" (
    echo.
    echo ERROR: Falta especificar IP o HOSTNAME de fedi-srv
    echo.
    exit /b 1
)

set AMBIENTE=%1
set HOST=%2
set PUERTO=%3

if "%PUERTO%"=="" set PUERTO=8080

REM Validar ambiente
if /i not "%AMBIENTE%"=="DEV" if /i not "%AMBIENTE%"=="QA" if /i not "%AMBIENTE%"=="PROD" (
    echo ERROR: Ambiente inválido. Usa DEV, QA o PROD
    exit /b 1
)

set "POM_FILE=C:\github\fedi-web\pom.xml"

if not exist "%POM_FILE%" (
    echo ERROR: No encontrado %POM_FILE%
    exit /b 1
)

REM Convertir ambiente a uppercase
for /f %%i in ('powershell -Command "[string]'%AMBIENTE%'.ToUpper()"') do set AMBIENTE=%%i

set "NEW_URL=http://%HOST%:%PUERTO%/srvFEDIApi/"

echo.
echo ====== CAMBIAR URL DIRECTA A FEDI-SRV ======
echo.
echo Archivo:    %POM_FILE%
echo Ambiente:   %AMBIENTE%
echo Nueva URL:  %NEW_URL%
echo.

REM Hacer backup
set "BACKUP_FILE=%POM_FILE%.backup-%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
copy "%POM_FILE%" "%BACKUP_FILE%" >nul
echo Backup creado: %BACKUP_FILE%
echo.

REM Determinar número de línea según ambiente
if /i "%AMBIENTE%"=="DEV" (
    set "LINE_NUMBER=810"
    set "PROFILE=DEV"
) else if /i "%AMBIENTE%"=="QA" (
    set "LINE_NUMBER=869"
    set "PROFILE=QA"
) else if /i "%AMBIENTE%"=="PROD" (
    set "LINE_NUMBER=918"
    set "PROFILE=PRODUCTION"
)

echo Actualizando profile %PROFILE% (línea ~%LINE_NUMBER%)...

REM Usar PowerShell para actualizar el archivo (más fácil que batch)
powershell -Command ^
  "$content = Get-Content '%POM_FILE%' -Encoding UTF8; " ^
  "$content = $content -replace '(?<=<!-- %PROFILE% -->.*?)<profile\.fedi\.direct\.url>http://[^<]+</profile\.fedi\.direct\.url>', '<profile.fedi.direct.url>%NEW_URL%</profile.fedi.direct.url>'; " ^
  "Set-Content '%POM_FILE%' -Value $content -Encoding UTF8"

if errorlevel 1 (
    echo.
    echo ERROR: Falló la actualización del archivo
    echo Restaurando desde backup...
    copy "%BACKUP_FILE%" "%POM_FILE%" /Y >nul
    exit /b 1
)

echo.
echo ✓ Actualización exitosa
echo.
echo Próximos pasos:
echo.
echo 1. Compilar:
echo    cd C:\github\fedi-web
echo    mvn clean install -P %AMBIENTE% -DskipTests
echo.
echo 2. Desplegar:
echo    Stop-Service Tomcat9 -Force
echo    Remove-Item "C:\tomcat\webapps\FEDIPortalWeb-1.0" -Recurse -Force
echo    Remove-Item "C:\tomcat\work\Catalina\localhost\*" -Recurse -Force
echo    Copy-Item "C:\github\fedi-web\target\FEDIPortalWeb-1.0.war" "C:\tomcat\webapps\"
echo    Start-Service Tomcat9
echo.
echo 3. Esperar a que Tomcat levante (30-45 segundos)
echo.
echo 4. Probar en navegador: http://[fedi-web-url]/FEDIPortalWeb/
echo.

endlocal
