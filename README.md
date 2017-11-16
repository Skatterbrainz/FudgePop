# FudgePop (Module) 1.0.10
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
* Install PowerShell modules
* Force Windows Update Scan/Download/Install Cycle

# Targeting

* Target devices by specific name or via Collections, or both

# Installation

  1. Use the Install-Module cmdlet to install FudgePop: **Install-Module FudgePop**
  2. Import FudgePop: **Import-Module Fudgepop**
  3. Copy and Edit the source **control.xml** and place it somewhere accessible to the remote computers
  4. Run **Configure-FudgePop** to configure the control XML location and scheduled task options.
  5. Run **Invoke-FudgePop** to test on the first machine
  6. Repeat steps 3 and 4 for other devices.
  
  * Note: You can use multiple control XML files for different devices or groups of devices if you prefer.

# Management

  * Edit the control XML file to provide the configuration data you desire.
  * Increment the [version] attribute within the [control] element (to insure XML data is read properly on clients)
  * Allow time for clients to run scheduled task to invoke control data updates (or force task to run)
  
# Functions

Refer to Docs folder for more details about functions, parameters, and examples.

## Invoke-FudgePop

  * Runs a FudgePop policy cycle

## Install-FudgePop

  * Configures and enables FudgePop

## Remove-FudgePop

  * Removes scheduled task and registry entries, optionally removes module.

## Show-FudgePop

  * Displays version and configuration information.

## Get-FudgePopInventory

  * Generates basic HTML inventory report of basic computer hardware, software and operating system information.

