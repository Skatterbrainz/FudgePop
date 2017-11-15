# FudgePop (Module) 1.0.9
## README.md

Centrally manage Windows 10 computers using a local script which reads instructions from a remote XML control file.

* Install, Upgrade and Remove Chocolatey Packages
* Create, Delete and Empty Folders
* Copy, Rename, Move or Delete Files
* Start, Stop and Reconfigure Services
* Add, Modify, Delete Shortcuts
* Add, Modify Registry Keys and Values
* Install or Remove Win32 Applications (on-prem sources or local)
* Uninstall Local Apps (exe, msi)
* Uninstall Appx Store Apps (Candy Crush, MineCraft, etc.)
* Modify Folder and File Permissions
* Force Windows Update Scan/Download/Install Cycle

# Installation

  1. Use the Install-Module cmdlet to install FudgePop: **Install-Module FudgePop**
  2. Edit the source **control.xml** and place it somewhere accessible to the remote computers
  3. Run **Configure-FudgePop** to configure the control XML location and scheduled task options.
  4. Run **Invoke-FudgePop** to test on the first machine
  5. Repeat steps 3 and 4 for other devices.

# Management

  * Edit the control XML file to provide the configuration data you desire.
  * Increment the [version] attribute within the [control] element (to insure XML data is read properly on clients)
  * Allow time for clients to run scheduled task to invoke control data updates (or force task to run)
  
# Functions

## Invoke-FudgePop

  * **TestMode**

  Switch. Invokes specialized -WhatIf processing.  Also supports -Verbose

## Install-FudgePop

  Prompts for input to control FudgePop client settings.
  
  * **UseDefaults**
  
  Automatically configures the default settings: 
  * Uses the sample template on this Github repo (not a good idea, but hey)
  * Uses 1 hour interval for scheduled task to invoke FudgePop

## Remove-FudgePop

  * Removes scheduled task and registry entries.  Still requires Remove-Module to completely remove.

## Show-FudgePop

  * Displays version and configuration information

## Get-FudgePopInventory

Generates basic HTML inventory report of basic computer hardware, software and operating system information.

  * **ComputerName**
  
Name(s) of computers to query. Default is local computer.
  
  * **FilePath**
  
  Path to store report files.  Default is $env:USERPROFILE\Documents
