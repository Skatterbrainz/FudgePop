function Invoke-FPControls {
	<#
    .SYNOPSIS
        Main process invocation
    .DESCRIPTION
        Main process for executing FudgePop services
    .PARAMETER DataSet
        XML data from control file import
    .EXAMPLE
        Invoke-FPControls -DataSet $xmldata
    #>
    param (
        [parameter(Mandatory = $True)] 
		[ValidateNotNullOrEmpty()] 
		$DataSet
    )
    $ModuleData = Get-Module FudgePop
    $ModuleVer  = $ModuleData.Version -join '.'

    Write-FPLog -Category "Info" -Message $(Write-CenteredText -Caption "control processing: begin")
    $MyPC = $env:COMPUTERNAME
    Write-FPLog "module version.....: $ModuleVer"
    Write-FPLog "device name........: $MyPC"
    $collections = Get-FPDeviceCollections -XmlData $DataSet
    if ($collections -ne "") {
        Write-FPLog -Category 'Info' -Message "collections........: $($collections -join ',')"
    }
    $priority    = $DataSet.configuration.priority.order
    $installs    = Get-FPFilteredSet -XmlData $DataSet.configuration.deployments.deployment -Collections $collections
    $removals    = Get-FPFilteredSet -XmlData $DataSet.configuration.removals.removal -Collections $collections
    $folders     = Get-FPFilteredSet -XmlData $DataSet.configuration.folders.folder -Collections $collections
    $files       = Get-FPFilteredSet -XmlData $DataSet.configuration.files.file -Collections $collections
    $registry    = Get-FPFilteredSet -XmlData $DataSet.configuration.registry.reg -Collections $collections
    $services    = Get-FPFilteredSet -XmlData $DataSet.configuration.services.service -Collections $collections
    $shortcuts   = Get-FPFilteredSet -XmlData $DataSet.configuration.shortcuts.shortcut -Collections $collections
    $opapps      = Get-FPFilteredSet -XmlData $DataSet.configuration.opapps.opapp -Collections $collections
    $updates     = Get-FPFilteredSet -XmlData $DataSet.configuration.updates.update -Collections $collections
    $appx        = Get-FPFilteredSet -XmlData $DataSet.configuration.appxremovals.appxremoval -Collections $collections
    $modules     = Get-FPFilteredSet -XmlData $DataSet.configuration.modules.module -Collections $collections
    $permissions = Get-FPFilteredSet -XmlData $DataSet.configuration.permissions.permission -Collections $collections
	
    Write-FPLog "template version...: $($DataSet.configuration.version)"
    Write-FPLog "template comment...: $($DataSet.configuration.comment)"
    Write-FPLog "control version....: $($DataSet.configuration.control.version) ***"
    Write-FPLog "control enabled....: $($DataSet.configuration.control.enabled)"
    Write-FPLog "control comment....: $($DataSet.configuration.control.comment)"

    Set-FPConfiguration -Name "TemplateVersion" -Data $DataSet.configuration.version | Out-Null
    Set-FPConfiguration -Name "ControlVersion" -Data $DataSet.configuration.control.version | Out-Null

    if (!(Get-FPServiceAvailable -DataSet $DataSet)) { Write-FPLog 'FudgePop is not enabled'; break }
	
    Write-FPLog "priority list: $($priority -replace(',',' '))"
	
    foreach ($key in $priority -split ',') {
        switch ($key) {
            'folders' { 
                if ($folders) {
                    Set-FPControlFolders -DataSet $folders
                }
                else {
                    Write-FPLog -Category 'Info' -Message "no assignments for group: Folders"
                }
                break
            }
            'files' { 
                if ($files) {
                    Set-FPControlFiles -DataSet $files
                }
                else {
                    Write-FPLog -Category 'Info' -Message "no assignments for group: Files"
                }
                break
            }
            'registry' {
                if ($registry) {
                    Set-FPControlRegistry -DataSet $registry
                }
                else {
                    Write-FPLog -Category 'Info' -Message "no assignments for group: Registry"
                }
                break
            }
            'deployments' {
                if ($installs) {
                    Set-FPControlPackages -DataSet $installs
                }
                else {
                    Write-FPLog -Category 'Info' -Message "no assignments for group: Package Installs"
                }
                break
            }
            'removals' { 
                if ($removals) {
                    Set-FPControlRemovals -DataSet $removals
                }
                else {
                    Write-FPLog -Category 'Info' -Message "no assignments for group: Package Removals"
                }
                break
            }
            'appxremovals' { 
                if ($appx) {
                    Set-FPControlAppxRemovals -DataSet $appx
                }
                else {
                    Write-FPLog -Category 'Info' -Message "no assignments for group: AppxRemovals"
                }
                break
            }
            'services' { 
                if ($services) {
                    Set-FPControlServices -DataSet $services
                }
                else {
                    Write-FPLog -Category 'Info' -Message "no assignments for group: Services"
                }
                break
            }
            'shortcuts' { 
                if ($shortcuts) {
                    Set-FPControlShortcuts -DataSet $shortcuts
                }
                else {
                    Write-FPLog -Category 'Info' -Message "no assignments for group: Shortcuts"
                }
                break
            }
            'opapps' { 
                if ($opapps) {
                    Set-FPControlWin32Apps -DataSet $opapps
                }
                else {
                    Write-FPLog -Category 'Info' -Message "no assignments for group: Win32 Apps"
                }
                break
            }
            'permissions' { 
                if ($permissions) {
                    Set-FPControlPermissions -DataSet $permissions
                }
                else {
                    Write-FPLog -Category 'Info' -Message "no assignments for group: Permissions"
                }
                break
            }
            'updates' { 
                if ($updates) {
                    Set-FPControlWindowsUpdate -DataSet $updates
                }
                else {
                    Write-FPLog -Category 'Info' -Message "no assignments for group: WindowsUpdate"
                }
                break
            }
            'modules' { 
                if ($modules) {
                    Set-FPControlModules -DataSet $modules
                }
                else {
                    Write-FPLog -Category 'Info' -Message "no assignments for group: PowerShell Modules"
                }
                break
            }
            'upgrades' { 
                break
            }
            default { 
                Write-FPLog -Category 'Error' -Message "invalid priority key: $key"; break }
        } # switch
    } # foreach
    Write-FPLog -Category "Info" -Message $(Write-CenteredText -Caption "control processing: finish")
}