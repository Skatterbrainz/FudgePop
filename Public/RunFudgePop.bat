@echo off
rem RunFudgePop.bat
rem Version 1.0.18 - 03/03/2024
PowerShell.exe -ExecutionPolicy ByPass -NoProfile -Command "& {Import-Module FudgePop;Invoke-FudgePop -Verbose}" >%SYSTEMROOT%\TEMP\FudgePop.txt
