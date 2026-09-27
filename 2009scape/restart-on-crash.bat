```bat
@echo off
setlocal EnableExtensions

cd /d "%~dp0Server"

rem ================================================================
rem  2009Scape Server Launcher
rem
rem  - Performs the normal first-run Maven clean
rem  - Builds the server
rem  - Copies the latest server JAR to server.jar
rem  - Starts the server
rem  - Automatically restarts the server if Java exits
rem  - Does NOT rebuild the server after a crash
rem ================================================================

rem ---- Configuration ----------------------------------------------

rem Seconds to wait before restarting after the server stops.
set "DELAY=5"

rem 0 = restart forever
rem Any number greater than 0 = maximum number of restart attempts.
set "MAX_RETRIES=0"

rem ---- First-run initialization -----------------------------------

if not exist "hasRan.txt" (
    echo.
    echo ================================================================
    echo First run detected.
    echo Performing Maven clean...
    echo ================================================================
    echo.

    call ".\mvnw.cmd" clean

    if errorlevel 1 (
        echo.
        echo ERROR: Maven clean failed.
        echo.
        pause
        exit /b 1
    )

    copy /Y NUL "hasRan.txt" >nul
)

rem ---- Build server ------------------------------------------------

echo.
echo ================================================================
echo Building 2009Scape server...
echo ================================================================
echo.

call ".\mvnw.cmd" package -DskipTests

if errorlevel 1 (
    echo.
    echo ================================================================
    echo ERROR: Maven build failed.
    echo ================================================================
    echo.
    pause
    exit /b 1
)

rem ---- Copy server JAR ---------------------------------------------

echo.
echo Copying server JAR...

for %%F in ("target\*-with-dependencies.jar") do (
    copy /Y "%%~F" "server.jar" >nul

    if errorlevel 1 (
        echo.
        echo ERROR: Failed to copy server JAR.
        echo.
        pause
        exit /b 1
    )

    goto :jar_copied
)

echo.
echo ERROR: Could not find target\*-with-dependencies.jar
echo.
pause
exit /b 1

:jar_copied

echo Server JAR copied successfully.
echo.

rem ================================================================
rem  Server restart loop
rem ================================================================

set "RETRY_COUNT=0"

:restart

set /a RETRY_COUNT+=1

rem ---- Check maximum restart count -------------------------------

if %MAX_RETRIES% GTR 0 (
    if %RETRY_COUNT% GTR %MAX_RETRIES% (
        echo.
        echo ================================================================
        echo Maximum restart attempts reached.
        echo Server launcher exiting.
        echo ================================================================
        echo.
        exit /b 0
    )
)

echo.
echo ================================================================
echo Starting 2009Scape server
echo Restart attempt: %RETRY_COUNT%
echo Time: %TIME%
echo ================================================================
echo.

java -jar "server.jar"

rem ---- Java has exited --------------------------------------------

set "EXIT_CODE=%ERRORLEVEL%"

echo.
echo ================================================================
echo Server process stopped.
echo Exit code: %EXIT_CODE%
echo ================================================================
echo.

if "%EXIT_CODE%"=="0" (
    echo Server exited normally.
) else (
    echo Server appears to have crashed or terminated unexpectedly.
)

echo.
echo Restarting in %DELAY% seconds...
echo Press CTRL+C to stop the launcher.
echo.

timeout /t %DELAY% /nobreak >nul

goto :restart
```
