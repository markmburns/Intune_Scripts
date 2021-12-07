@ECHO OFF
REM mark.burns@dell.com
Echo AutoPilot Diagnostics
PowerShell -ExecutionPolicy Bypass -File %~dp0Get-AutoPilotDiagnostics.ps1 -online