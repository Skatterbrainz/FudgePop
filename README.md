# FudgePop (PowerShell Module)

2.0.0  - 2025.12.10
- Replaced XML configuration model with JSON
- Added support for Winget and Chocolatey
- Added support for deploying Python3 packages
- Massive code updates and rewrites

1.0.18 - 2024.03.09

## The FudgePop project is not under active development.

The repository remains available for reference, and pull requests will be considered, but no active work is being done on this project.

# Overview

Centrally manage Windows 10 and 11 computers using a local script which reads instructions from a remote XML control file.

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

# Why 'FudgePop'?

  * Because it started with Chocolatey, and a strange bet with a colleague over beer and coffee.
  * I know that makes no sense at all, but it still tastes pretty darn good!

# Installation

  1. Use the Install-Module cmdlet to install FudgePop: ```Install-Module FudgePop```
  2. Copy and Edit the source **control.xml** and place it somewhere accessible to the remote computers
  3. Run ```Configure-FudgePop``` to configure the control XML location and scheduled task options.
  4. Run ```Start-FudgePop``` to test on the first machine
  5. Repeat steps 2 and 3 for other devices.

  * Note: You can use multiple control XML files for different devices or groups of devices if you prefer.

# Management

  * Edit the control JSON file to provide the configuration data you desire.
  * Increment the [version] attribute within the [control] element (to insure JSON data is read properly on clients)
  * Allow time for clients to run scheduled task to invoke control data updates (or force task to run)

# Functions

Refer to Docs folder for more details about functions, parameters, and examples.

## Start-FudgePop

  * Runs a FudgePop policy cycle

## Install-FudgePop

  * Configures and enables FudgePop

## Remove-FudgePop

  * Removes scheduled task and registry entries, optionally removes module.

## Show-FudgePop

  * Displays version and configuration information.

## Get-FudgePopInventory

  * Generates basic HTML inventory report of basic computer hardware, software and operating system information.
