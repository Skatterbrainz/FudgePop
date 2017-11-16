@echo off
rem RunFudgePop.bat
rem Version 1.0.10 - 11/14/2017
PowerShell.exe -ExecutionPolicy ByPass -NoProfile -Command "& {Import-Module FudgePop;Invoke-FudgePop -Verbose}" >%SYSTEMROOT%\TEMP\FudgePop.txt
