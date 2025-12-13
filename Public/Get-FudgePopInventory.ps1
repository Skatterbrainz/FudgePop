function Get-FudgePopInventory {
	<#
	.SYNOPSIS
		Display Hardware and Software Inventory for local computer
	.DESCRIPTION
		Displays hardware and software inventory for the local computer.
	.PARAMETER ExportPath
		Path and filename for the inventory report.
		If not specified, the report is displayed to the console.
	.EXAMPLE
		Get-FudgePopInventory

		Returns the inventory report to the console.
	.EXAMPLE
		Get-FudgePopInventory -ExportPath "c:\users\dave\documents"

		Exports the inventory report to the specified path.
	#>
	[CmdletBinding(SupportsShouldProcess = $True)]
	param (
		[parameter(Mandatory = $false)][string]$ExportPath
	)
	if ($IsWindows) {
		$FPPlatform = "Windows"
		$osRaw    = Get-CimInstance -ClassName Win32_OperatingSystem
		$csRaw    = Get-CimInstance -ClassName Win32_ComputerSystem
		$biosRaw  = Get-CimInstance -ClassName Win32_BIOS
		$procRaw  = Get-CimInstance -ClassName Win32_Processor
		$disksRaw = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
		$nicRaw   = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled=true"
		$appsRaw  = Get-CimInstance -ClassName Win32_Product
		
		# Create structured inventory object for Windows
		$inventory = [PSCustomObject]@{
			Platform              = $FPPlatform
			OperatingSystem       = $osRaw
			ComputerSystem        = $csRaw
			BIOS                  = $biosRaw
			Processor             = $procRaw
			Disks                 = $disksRaw
			NetworkInterfaces     = $nicRaw
			InstalledApplications = $appsRaw
		}
		
		$os    = $inventory.OperatingSystem
		$cs    = $inventory.ComputerSystem
		$bios  = $inventory.BIOS
		$proc  = $inventory.Processor
		$disks = $inventory.Disks
		$nic   = $inventory.NetworkInterfaces
		$apps  = $inventory.InstalledApplications
	} elseif ($IsMacOS) {
		$FPPlatform = "MacOS"
		# MacOS implementation would go here
		$inventory = [PSCustomObject]@{
			Platform              = $FPPlatform
			OperatingSystem       = "MacOS implementation needed"
			ComputerSystem        = "MacOS implementation needed"
			BIOS                  = "MacOS implementation needed"
			Processor             = "MacOS implementation needed"
			Disks                 = "MacOS implementation needed"
			NetworkInterfaces     = "MacOS implementation needed"
			InstalledApplications = "MacOS implementation needed"
		}
	} else {
		$FPPlatform = "Linux"
		$osRaw    = Invoke-Command -ScriptBlock { lsb_release -a 2>/dev/null }
		$csRaw    = Invoke-Command -ScriptBlock { hostnamectl 2>/dev/null }
		$biosRaw  = Invoke-Command -ScriptBlock { sudo dmidecode -t bios 2>/dev/null }
		$procRaw  = Invoke-Command -ScriptBlock { lscpu }
		$disksRaw = Invoke-Command -ScriptBlock { lsblk -o NAME,SIZE,TYPE,MOUNTPOINT }
		$fsRaw    = Invoke-Command -ScriptBlock { lsblk -f }
		$dfRaw    = Invoke-Command -ScriptBlock { df -BM }
		$physicalRaw = Invoke-Command -ScriptBlock { lsblk -d -o NAME,SIZE,ROTA,TYPE }
		$hwRaw    = Invoke-Command -ScriptBlock { bash -c 'for dir in /sys/block/*/device; do [ -d "$dir" ] || continue; diskname=$(basename $(dirname $dir)); echo "=== $diskname ==="; [ -f "$dir/model" ] && echo "Model: $(cat $dir/model | tr -d " ")"; [ -f "$dir/vendor" ] && echo "Vendor: $(cat $dir/vendor | tr -d " ")"; [ -f "$dir/serial" ] && echo "Serial: $(cat $dir/serial | tr -d " ")"; done' }
		$nicRaw   = Invoke-Command -ScriptBlock { ip addr show }
		$routeRaw = Invoke-Command -ScriptBlock { ip route show }
		$dnsRaw   = Invoke-Command -ScriptBlock { cat /etc/resolv.conf 2>/dev/null }
		$appsRaw  = Invoke-Command -ScriptBlock { dpkg --list }
		
		# Create structured inventory object
		$inventory = [PSCustomObject]@{
			Platform = $FPPlatform
			OperatingSystem = [PSCustomObject]@{
				RawOutput   = $osRaw -join "`n"
				Distributor = ($osRaw | Where-Object { $_ -like "Distributor ID:*" }) -replace "Distributor ID:\s*", ""
				Description = ($osRaw | Where-Object { $_ -like "Description:*" }) -replace "Description:\s*", ""
				Release     = ($osRaw | Where-Object { $_ -like "Release:*" }) -replace "Release:\s*", ""
				Codename    = ($osRaw | Where-Object { $_ -like "Codename:*" }) -replace "Codename:\s*", ""
			}
			ComputerSystem = [PSCustomObject]@{
				RawOutput   = $csRaw -join "`n"
				Hostname    = ($csRaw | Where-Object { $_ -like "Static hostname:*" }) -replace "\s*Static hostname:\s*", ""
				ChassisType = ($csRaw | Where-Object { $_ -like "Chassis:*" }) -replace "\s*Chassis:\s*", ""
				Kernel      = ($csRaw | Where-Object { $_ -like "Kernel:*" }) -replace "\s*Kernel:\s*", ""
			}
			BIOS = [PSCustomObject]@{
				RawOutput = $biosRaw -join "`n"
			}
			Processor = [PSCustomObject]@{
				#RawOutput    = $procRaw -join "`n"
				ModelName    = ($procRaw | Where-Object { $_ -like "Model name:*" }) -replace "Model name:\s*", ""
				Cores        = ($procRaw | Where-Object { $_ -like "CPU(s):*" }) -replace "CPU\(s\):\s*", ""
				Architecture = ($procRaw | Where-Object { $_ -like "Architecture:*" }) -replace "Architecture:\s*", ""
			}
			Disks = [PSCustomObject]@{
				#RawOutput = $disksRaw -join "`n"
				#FilesystemInfo = $fsRaw -join "`n"
				#UsageInfo = $dfRaw -join "`n"
				LogicalDisks = @(
					# Parse mounted filesystems from df output
					$dfRaw | Where-Object { $_ -match '^/dev/' } | ForEach-Object {
						if ($_ -match '^(/dev/[^\s]+)\s+([0-9]+)M\s+([0-9]+)M\s+([0-9]+)M\s+[0-9]+%\s+(.+)$') {
							$devicePath = $matches[1]
							$totalMB = [int]$matches[2]
							$usedMB = [int]$matches[3]
							$mountPoint = $matches[5]
							
							# Extract device name from path
							$deviceName = $devicePath -replace '^/dev/', ''
							
							# Get filesystem type from lsblk -f output
							$fsType = ""
							$fsLine = $fsRaw | Where-Object { $_ -match "^$([regex]::Escape($deviceName))\s+([^\s]+)" }
							if ($fsLine) {
								if ($fsLine -match "^$([regex]::Escape($deviceName))\s+([^\s]+)") {
									$fsType = $matches[2]
								}
							}
							
							# Get label if available
							$label = ""
							$labelLine = $fsRaw | Where-Object { $_ -match "^$([regex]::Escape($deviceName))\s+[^\s]+\s+[^\s]*\s+([^\s]+)" }
							if ($labelLine) {
								if ($labelLine -match "^$([regex]::Escape($deviceName))\s+[^\s]+\s+[^\s]*\s+([^\s]+)") {
									$label = $matches[2]
								}
							}
							
							[PSCustomObject]@{
								Name = if ($label -and $label -ne "") { $label } else { $deviceName }
								Id = $devicePath
								FilesystemType = $fsType
								SizeMB = $totalMB
								UsedMB = $usedMB
								AvailableMB = $totalMB - $usedMB
								UsedPercent = [math]::Round(($usedMB / $totalMB) * 100, 1)
								MountPoint = $mountPoint
							}
						}
					}
				)
				PhysicalDisks = @(
					# Parse physical disk information
					$physicalRaw | Where-Object { $_ -match '^\w+' -and $_ -notmatch '^NAME' } | ForEach-Object {
						if ($_ -match '^([^\s]+)\s+([^\s]+)\s+([01])\s+(.+)$') {
							$diskName = $matches[1]
							$diskSize = $matches[2]
							$isRotational = $matches[3] -eq "1"
							$diskType = $matches[4]
							
							# Get hardware details from hwRaw
							$model = ""
							$vendor = ""
							$serial = ""
							
							# Find the hardware info section for this disk
							$currentDisk = $false
							$hwRaw | ForEach-Object {
								if ($_ -match "^=== $([regex]::Escape($diskName)) ===") {
									$currentDisk = $true
								} elseif ($_ -match "^=== .+ ===") {
									$currentDisk = $false
								} elseif ($currentDisk) {
									if ($_ -match '^Model:\s*(.+)') {
										$model = $matches[1].Trim()
									} elseif ($_ -match '^Vendor:\s*(.+)') {
										$vendor = $matches[1].Trim()
									} elseif ($_ -match '^Serial:\s*(.+)') {
										$serial = $matches[1].Trim()
									}
								}
							}
							
							# Determine Make (prefer vendor, fallback to extracted from model)
							$make = $vendor
							if (-not $make -and $model) {
								if ($model -match '^(WD|WESTERN_DIGITAL|Samsung|Intel|Crucial|Kingston|SanDisk|Seagate|Toshiba|Hitachi)') {
									$make = $matches[1]
								}
							}
							
							# Determine disk type based on rotation and name
							$type = if ($diskName -match "^nvme") {
								"NVMe SSD"
							} elseif ($isRotational) {
								"HDD"
							} else {
								"SSD"
							}
							
							[PSCustomObject]@{
								Name = $diskName
								Make = $make
								Model = $model
								PartNumber = $model  # Often model serves as part number
								SerialNumber = $serial
								Size = $diskSize
								Type = $type
								IsRotational = $isRotational
							}
						}
					}
				)
			}
			NetworkInterfaces = [PSCustomObject]@{
				#RawOutput = $nicRaw -join "`n"
				#RouteInfo = $routeRaw -join "`n"
				#DNSInfo = $dnsRaw -join "`n"
				Interfaces = @(
					# Parse network interfaces from ip addr output
					$currentInterface = $null
					$interfaces = @()
					
					$nicRaw | ForEach-Object {
						if ($_ -match '^(\d+):\s+([^:]+):\s+<([^>]+)>.*mtu\s+(\d+).*state\s+(\w+)') {
							# New interface line
							if ($currentInterface) {
								$interfaces += $currentInterface
							}
							$currentInterface = [PSCustomObject]@{
								Index = [int]$matches[1]
								Name = $matches[2]
								Flags = $matches[3] -split ','
								MTU = [int]$matches[4]
								State = $matches[5]
								Type = ""
								IPv4Addresses = @()
								IPv6Addresses = @()
								Description = ""
								Gateway = ""
								Subnet = ""
							}
						} elseif ($_ -match '^\s+link/(\w+)') {
							# Link type line
							if ($currentInterface) {
								$currentInterface.Type = $matches[1]
							}
						} elseif ($_ -match '^\s+inet\s+([^/]+)/(\d+).*scope\s+(\w+)') {
							# IPv4 address line
							if ($currentInterface) {
								$currentInterface.IPv4Addresses += [PSCustomObject]@{
									Address = $matches[1]
									PrefixLength = [int]$matches[2]
									Scope = $matches[3]
								}
							}
						} elseif ($_ -match '^\s+inet6\s+([^/]+)/(\d+).*scope\s+(\w+)') {
							# IPv6 address line
							if ($currentInterface) {
								$currentInterface.IPv6Addresses += [PSCustomObject]@{
									Address = $matches[1]
									PrefixLength = [int]$matches[2]
									Scope = $matches[3]
								}
							}
						}
					}
					
					# Add the last interface
					if ($currentInterface) {
						$interfaces += $currentInterface
					}
					
					# Add routing and gateway information
					$routeRaw | ForEach-Object {
						if ($_ -match 'default via ([^\s]+) dev ([^\s]+)') {
							# Default gateway
							$gateway = $matches[1]
							$device = $matches[2]
							$interface = $interfaces | Where-Object { $_.Name -eq $device }
							if ($interface) {
								$interface.Gateway = $gateway
							}
						} elseif ($_ -match '([^\s]+/\d+) dev ([^\s]+).*scope link') {
							# Subnet information
							$subnet = $matches[1]
							$device = $matches[2]
							$interface = $interfaces | Where-Object { $_.Name -eq $device }
							if ($interface) {
								$interface.Subnet = $subnet
							}
						}
					}
					
					# Add DNS information
					$dnsServers = @($dnsRaw | Where-Object { $_ -match '^nameserver\s+(.+)' } | ForEach-Object { $matches[1] })
					
					# Set description based on interface type
					$interfaces | ForEach-Object {
						if ($_.Name -eq "lo") {
							$_.Description = "Loopback Interface"
						} elseif ($_.Name -like "wl*") {
							$_.Description = "Wireless Network Interface"
						} elseif ($_.Name -like "en*" -or $_.Name -like "eth*") {
							$_.Description = "Ethernet Network Interface"
						} else {
							$_.Description = "Network Interface"
						}
					}
					
					$interfaces
				)
				DNSServers = @($dnsRaw | Where-Object { $_ -match '^nameserver\s+(.+)' } | ForEach-Object { $matches[1] })
			}
			InstalledApplications = [PSCustomObject]@{
				RawOutput = $appsRaw -join "`n"
				PackageCount = ($appsRaw | Where-Object { $_ -match '^ii\s+' }).Count
				Applications = @(
					($appsRaw | Where-Object { $_ -match '^ii\s+' } | ForEach-Object {
						# Parse dpkg output format: ii  name  version  architecture  description
						if ($_ -match '^ii\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+(.+)$') {
							[PSCustomObject]@{
								Name = $matches[1]
								Version = $matches[2]
								Architecture = $matches[3]
								Description = $matches[4]
							}
						}
					})
				)
			}
		}
		
		$os    = $inventory.OperatingSystem
		$cs    = $inventory.ComputerSystem
		$bios  = $inventory.BIOS
		$proc  = $inventory.Processor
		$disks = $inventory.Disks
		$nic   = $inventory.NetworkInterfaces
		$apps  = $inventory.InstalledApplications
	}
	
	# Return the inventory object (can be converted to JSON)
	return $inventory
}
