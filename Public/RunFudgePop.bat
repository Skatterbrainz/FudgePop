@echo off
rem RunFudgePop.bat
rem Version 1.0.15 - 12/27/2017
PowerShell.exe -ExecutionPolicy ByPass -NoProfile -Command "& {Import-Module FudgePop;Invoke-FudgePop -Verbose}" >%SYSTEMROOT%\TEMP\FudgePop.txt
