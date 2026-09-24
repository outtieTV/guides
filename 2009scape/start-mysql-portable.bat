@echo off
rem -------------------------------------------------
rem MySQL 5.7.44 – start script (Windows)
rem -------------------------------------------------
rem Location of the unpacked MySQL zip
set MYSQL_HOME=E:\2009scape\SQLServer

rem Add the bin folder to PATH
set PATH=%MYSQL_HOME%\bin;%PATH%

rem -----------------------------------------------------------------
rem Initialise the data directory (run only once, or when it is empty)
rem -----------------------------------------------------------------
rem The first time you run this batch file the data directory will be empty.
rem MySQL 5.7 uses mysqld --initialize‑insecure to create the system tables
rem without a root password (you can set one later with ALTER USER).
if not exist "%MYSQL_HOME%\data\ibdata1" (
    echo Initialising MySQL data directory …
    mysqld --initialize-insecure --datadir="%MYSQL_HOME%\data"
    if errorlevel 1 (
        echo *** FAILED TO INITIALISE DATA DIRECTORY ***
        pause
        exit /b 1
    )
)

rem -----------------------------------------------------------------
rem Optional: run once as Administrator to create the EventLog key
rem -----------------------------------------------------------------
rem If you have admin rights, uncomment the next line, run the batch,
rem then comment it again. This creates the registry key so the warning
rem goes away on subsequent runs.
rem   (run as Administrator only!)
rem   net start MySQL57   (if you installed it as a service)
rem   REM or simply:  mysqld --install
rem   REM then stop it:  net stop MySQL57

rem -----------------------------------------------------------------
rem Start the server – suppress Windows EventLog writes
rem -----------------------------------------------------------------
rem   --log_syslog=0   disables EventLog logging (prevents the “registry key” error)
rem   --console       shows error output in this window (useful for debugging)
rem   --skip-grant-tables   (remove after you have set a root password)
rem   --explicit_defaults_for_timestamp   silences the timestamp warning
cd /d "%MYSQL_HOME%\bin"
mysqld ^
    --datadir="%MYSQL_HOME%\data" ^
    --log_syslog=0 ^
    --explicit_defaults_for_timestamp ^
    --console

rem Keep the console open so you can read any messages.
pause
