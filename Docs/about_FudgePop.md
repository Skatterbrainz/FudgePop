# FudgePop
## about_FudgePop

# SHORT DESCRIPTION
Poor person's Windows device management solution

# LONG DESCRIPTION

FudgePop provides a means for centralized, remote management of
basic Windows 10 computer configuration and feature settings.

- Install, Upgrade or Remove Chocolatey packages
- Install Win32 Applications from on-Prem sources
- Remove Appx packages (if removeable)
- Add, Modify, Delete: Files, Folders, Registry, Services, Shortcuts
- Force Windows Update scans and installations
- Extract basic Inventory reports

It uses a centrally-hosted "control" XML policy file, which provides
instruction rules for clients to execute.  Clients use a local PowerShell
script which runs on a scheduled recurring task under the local SYSTEM
account.  Users do not need to be local administrators for FudgePop
to work.