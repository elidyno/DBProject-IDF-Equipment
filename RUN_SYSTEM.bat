@echo off
setlocal
title Military Equipment Database Project

cd /d "%~dp0PhaseE\backend"

where node >nul 2>nul
if errorlevel 1 (
    echo Node.js is not installed.
    echo Install Node.js and run this file again.
    pause
    exit /b 1
)

if not exist ".env" (
    echo Missing file: PhaseE\backend\.env
    echo The submitted package is incomplete.
    pause
    exit /b 1
)

powershell -NoProfile -Command "try { $r = Invoke-RestMethod 'http://localhost:3000/api/health' -TimeoutSec 2; if ($r.status -eq 'ok') { exit 0 } else { exit 1 } } catch { exit 1 }"
if not errorlevel 1 (
    start "" "http://localhost:3000"
    exit /b 0
)

if not exist "node_modules\express" (
    echo Installing required packages...
    call npm install
    if errorlevel 1 (
        echo Package installation failed.
        pause
        exit /b 1
    )
)

start "Database Project Server" cmd /k "cd /d ""%~dp0PhaseE\backend"" && npm start"

echo Starting the system...
powershell -NoProfile -Command "$ok = $false; for ($i = 0; $i -lt 30; $i++) { try { $r = Invoke-RestMethod 'http://localhost:3000/api/health' -TimeoutSec 2; if ($r.status -eq 'ok') { $ok = $true; break } } catch {}; Start-Sleep -Seconds 1 }; if ($ok) { exit 0 } else { exit 1 }"

if errorlevel 1 (
    echo The server did not start. Check the server window.
    pause
    exit /b 1
)

start "" "http://localhost:3000"
exit /b 0