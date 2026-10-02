@echo off
REM ===========================================================================
REM  install-harness-rules.cmd
REM  One-click installer for the Harness engineering rules docs, for users who
REM  live in CMD rather than PowerShell.
REM
REM  What it does: downloads install-harness-rules.ps1 from a mirror and runs it
REM  with -File. All argument handling, mirror fallback, content checking and
REM  Chinese output live in the .ps1, so there is exactly ONE implementation.
REM  Using -File (instead of `irm | iex`) keeps the UTF-8 BOM intact, which is
REM  what Windows PowerShell 5.1 needs to read the Chinese text correctly.
REM
REM  Usage:
REM    install-harness-rules.cmd
REM    install-harness-rules.cmd -Only new
REM    install-harness-rules.cmd -Only existing -Dir docs
REM
REM  NOTE: this file is deliberately ASCII-only. CMD parses .cmd/.bat using the
REM  system ANSI codepage (GBK on Chinese Windows), so UTF-8 Chinese inside a
REM  batch file can easily turn into mojibake. Chinese output is the .ps1's job.
REM ===========================================================================

setlocal

set "PSURL=https://ghproxy.net/https://raw.githubusercontent.com/Tairraos/harness-go/master/scripts/install-harness-rules.ps1"
set "TMPPS=%TEMP%\install-harness-rules.ps1"

where powershell >nul 2>nul
if errorlevel 1 (
  echo [ERROR] powershell not found on this machine.
  echo         Use scripts/install-harness-rules.sh under Git Bash or WSL instead.
  exit /b 1
)

echo Downloading installer script ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-WebRequest -UseBasicParsing $env:PSURL -OutFile $env:TMPPS"

if errorlevel 1 (
  echo.
  echo [ERROR] Could not download the installer script.
  echo         Network blocked, or the mirror is unavailable.
  echo         Manual fallback: open https://github.com/Tairraos/harness-go
  echo         download the repo, and copy files from rules\ into doc\ yourself.
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%TMPPS%" %*
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
  echo.
  echo [ERROR] Installer exited with code %RC%.
)

exit /b %RC%
