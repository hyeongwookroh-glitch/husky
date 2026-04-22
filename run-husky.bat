@echo off
cd /d "%~dp0"
set MAGI_AGENT=husky

powershell -NoProfile -Command "if (Get-WmiObject Win32_Process -Filter \"name='claude.exe'\" | Where-Object { $_.CommandLine -like '*server:husky*' }) { exit 0 } else { exit 1 }" >NUL 2>&1
if not errorlevel 1 (
    echo [HUSKY] Already running. Exiting.
    timeout /t 3 >nul
    exit /b 1
)

:loop
rem Re-load .env on every spawn so restart tool also picks up env changes
if exist .env (
    for /f "usebackq tokens=1,* delims==" %%A in (".env") do (
        if not "%%A"=="" if not "%%A:~0,1%"=="#" set "%%A=%%B"
    )
)

claude --model opus --effort xhigh --dangerously-skip-permissions --strict-mcp-config --mcp-config .mcp-husky.json --dangerously-load-development-channels server:husky
echo [%date% %time%] Husky exited (code: %ERRORLEVEL%), restarting in 3s...
timeout /t 3 >nul
goto loop
