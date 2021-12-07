@ECHO OFF
REM mark.burns@dell.com
Echo Collecting Autopilot Hardware Hash
PowerShell -ExecutionPolicy Bypass -File %~dp0Get-WindowsAutoPilotInfo.ps1 -OutputFile %~dp0%ComputerName%.csv
Echo Shutdown PC
pause
shutdown /s /t 1