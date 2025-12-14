function Get-FudgePopInventory {
	<#
	.SYNOPSIS
		Display Hardware and Software Inventory for local computer
	.DESCRIPTION
		Displays hardware and software inventory for the local computer.
	.PARAMETER ExportPath
		Path and filename for the inventory report.
		If not specified, the report is displayed to the console.
	.PARAMETER Category
		Specifies which category of inventory to return. Valid values are:
		"All", "OperatingSystem", "ComputerSystem", "BIOS", "Processor", "Disks", "NetworkInterfaces", "InstalledApplications", "Video", "Audio"
		Default is "All" which returns the complete inventory.
	.EXAMPLE
		Get-FudgePopInventory

		Returns the complete inventory report to the console.
	.EXAMPLE
		Get-FudgePopInventory -Category Video

		Returns only the Video inventory information.
	.EXAMPLE
		Get-FudgePopInventory -Category Audio

		Returns only the Audio inventory information.
	.EXAMPLE
		Get-FudgePopInventory -ExportPath "c:\users\dave\documents"

		Exports the complete inventory report to the specified path.
	#>
	[CmdletBinding(SupportsShouldProcess = $True)]
	param (
		[parameter(Mandatory = $false)][string]$ExportPath,
		[parameter(Mandatory = $false)]
		[ValidateSet("All", "OperatingSystem", "ComputerSystem", "BIOS", "Processor", "Disks", "NetworkInterfaces", "InstalledApplications", "Video", "Audio")]
		[string]$Category = "All"
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
		
		# Conditionally collect data based on Category parameter for performance
		if ($Category -eq "All" -or $Category -eq "OperatingSystem") {
			$osRaw = Invoke-Command -ScriptBlock { lsb_release -a 2>/dev/null }
		} else {
			$osRaw = @()
		}
		
		if ($Category -eq "All" -or $Category -eq "ComputerSystem") {
			$csRaw = Invoke-Command -ScriptBlock { hostnamectl 2>/dev/null }
			$dmiRaw = Invoke-Command -ScriptBlock { cat /sys/devices/virtual/dmi/id/sys_vendor /sys/devices/virtual/dmi/id/product_name /sys/devices/virtual/dmi/id/chassis_type 2>/dev/null }
		} else {
			$csRaw = @()
			$dmiRaw = @()
		}
		
		if ($Category -eq "All" -or $Category -eq "BIOS") {
			$biosRaw = Invoke-Command -ScriptBlock { timeout 5 sudo -n dmidecode -t bios 2>/dev/null || echo "BIOS info requires sudo access" }
		} else {
			$biosRaw = @()
		}
		
		if ($Category -eq "All" -or $Category -eq "Processor") {
			$procRaw = Invoke-Command -ScriptBlock { lscpu }
		} else {
			$procRaw = @()
		}
		
		if ($Category -eq "All" -or $Category -eq "Disks") {
			$disksRaw = Invoke-Command -ScriptBlock { lsblk -o NAME,SIZE,TYPE,MOUNTPOINT }
			$fsRaw = Invoke-Command -ScriptBlock { lsblk -f }
			$dfRaw = Invoke-Command -ScriptBlock { df -BM }
			$physicalRaw = Invoke-Command -ScriptBlock { lsblk -d -o NAME,SIZE,ROTA,TYPE }
			$hwRaw = Invoke-Command -ScriptBlock { timeout 15 bash -c 'for dir in /sys/block/*/device; do [ -d "$dir" ] || continue; diskname=$(basename $(dirname $dir)); echo "=== $diskname ==="; [ -f "$dir/model" ] && echo "Model: $(cat $dir/model | tr -d " ")"; [ -f "$dir/vendor" ] && echo "Vendor: $(cat $dir/vendor | tr -d " ")"; [ -f "$dir/serial" ] && echo "Serial: $(cat $dir/serial | tr -d " ")"; done' || echo "Hardware detection timed out" }
		} else {
			$disksRaw = @()
			$fsRaw = @()
			$dfRaw = @()
			$physicalRaw = @()
			$hwRaw = @()
		}
		
		if ($Category -eq "All" -or $Category -eq "NetworkInterfaces") {
			$nicRaw = Invoke-Command -ScriptBlock { ip addr show }
			$routeRaw = Invoke-Command -ScriptBlock { ip route show }
			$dnsRaw = Invoke-Command -ScriptBlock { cat /etc/resolv.conf 2>/dev/null }
		} else {
			$nicRaw = @()
			$routeRaw = @()
			$dnsRaw = @()
		}
		
		if ($Category -eq "All" -or $Category -eq "InstalledApplications") {
			$appsRaw = Invoke-Command -ScriptBlock { dpkg --list }
		} else {
			$appsRaw = @()
		}
		
		if ($Category -eq "All" -or $Category -eq "Video") {
			$videoRaw = Invoke-Command -ScriptBlock { lspci | grep -i "vga\|3d\|display" }
			$videoDetailRaw = Invoke-Command -ScriptBlock { lspci -v | grep -A 10 -i "vga\|3d\|display" }
			$nvidiaRaw = Invoke-Command -ScriptBlock { timeout 10 nvidia-smi --query-gpu=driver_version,vbios_version,name --format=csv 2>/dev/null || echo "" }
			$glxRaw = Invoke-Command -ScriptBlock { timeout 10 glxinfo 2>/dev/null | head -30 || echo "" }
		} else {
			$videoRaw = @()
			$videoDetailRaw = @()
			$nvidiaRaw = @()
			$glxRaw = @()
		}
		
		if ($Category -eq "All" -or $Category -eq "Audio") {
			$audioRaw = Invoke-Command -ScriptBlock { lspci | grep -i audio }
			$audioDevRaw = Invoke-Command -ScriptBlock { aplay -l 2>/dev/null }
			$pipewireRaw = Invoke-Command -ScriptBlock { timeout 10 pipewire --version 2>/dev/null || echo "" }
			$wireplumberRaw = Invoke-Command -ScriptBlock { timeout 10 wireplumber --version 2>/dev/null || echo "" }
			$pactlRaw = Invoke-Command -ScriptBlock { timeout 10 pactl info 2>/dev/null || echo "" }
			$wpctlRaw = Invoke-Command -ScriptBlock { timeout 15 wpctl status 2>/dev/null || echo "" }
		} else {
			$audioRaw = @()
			$audioDevRaw = @()
			$pipewireRaw = @()
			$wireplumberRaw = @()
			$pactlRaw = @()
			$wpctlRaw = @()
		}
		
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
				#RawOutput = $csRaw -join "`n"
				DMIRawOutput = $dmiRaw -join "`n"
				Name = ($csRaw | Where-Object { $_ -like "*Static hostname:*" }) -replace ".*Static hostname:\s*", ""
				Manufacturer = 
					if ($csRaw | Where-Object { $_ -like "*Hardware Vendor:*" }) {
						($csRaw | Where-Object { $_ -like "*Hardware Vendor:*" }) -replace ".*Hardware Vendor:\s*", ""
					} elseif ($dmiRaw -and $dmiRaw.Count -ge 1) {
						($dmiRaw -split "`n")[0].Trim()
					} else {
						"Unknown"
					}
				Model = 
					if ($csRaw | Where-Object { $_ -like "*Hardware Model:*" }) {
						($csRaw | Where-Object { $_ -like "*Hardware Model:*" }) -replace ".*Hardware Model:\s*", ""
					} elseif ($dmiRaw -and $dmiRaw.Count -ge 2) {
						($dmiRaw -split "`n")[1].Trim()
					} else {
						"Unknown"
					}
				ChassisType = 
					if ($csRaw | Where-Object { $_ -like "*Chassis:*" }) {
						($csRaw | Where-Object { $_ -like "*Chassis:*" }) -replace ".*Chassis:\s*", "" -replace " .*", ""
					} elseif ($dmiRaw -and $dmiRaw.Count -ge 3) {
						# Convert DMI chassis type number to descriptive text
						$chassisNum = ($dmiRaw -split "`n")[2].Trim()
						switch ($chassisNum) {
							"1" { "Other" }
							"2" { "Unknown" }
							"3" { "Desktop" }
							"4" { "Low Profile Desktop" }
							"5" { "Pizza Box" }
							"6" { "Mini Tower" }
							"7" { "Tower" }
							"8" { "Portable" }
							"9" { "Laptop" }
							"10" { "Notebook" }
							"11" { "Hand Held" }
							"12" { "Docking Station" }
							"13" { "All In One" }
							"14" { "Sub Notebook" }
							"15" { "Space-saving" }
							"16" { "Lunch Box" }
							"17" { "Main Server Chassis" }
							"18" { "Expansion Chassis" }
							"19" { "Sub Chassis" }
							"20" { "Bus Expansion Chassis" }
							"21" { "Peripheral Chassis" }
							"22" { "RAID Chassis" }
							"23" { "Rack Mount Chassis" }
							"24" { "Sealed-case PC" }
							default { "Unknown ($chassisNum)" }
						}
					} else {
						"Unknown"
					}
				# Legacy fields for backward compatibility
				Hostname = ($csRaw | Where-Object { $_ -like "*Static hostname:*" }) -replace ".*Static hostname:\s*", ""
				Kernel = ($csRaw | Where-Object { $_ -like "*Kernel:*" }) -replace ".*Kernel:\s*", ""
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
			Video = @(
				# Parse video cards and extract Type, Manufacturer, Model, Firmware Version
				$videoRaw | ForEach-Object {
					if ($_ -match '^([^\s]+)\s+(.+?):\s*(.+)$') {
						$pciId = $matches[1]
						$deviceType = $matches[2]
						$description = $matches[3]
						
						# Extract manufacturer and model from description
						$manufacturer = ""
						$model = $description
						
						if ($description -match '^(Intel|NVIDIA|AMD|ATI)\s+(.+)$') {
							$manufacturer = $matches[1]
							$model = $matches[2]
						} elseif ($description -match '^(.+?)\s+(Corporation|Corp\.?)\s+(.+)$') {
							$manufacturer = "$($matches[1]) $($matches[2])"
							$model = $matches[3]
						}
						
						# Get firmware version based on manufacturer
						$firmwareVersion = "Unknown"
						
						if ($manufacturer -eq "NVIDIA" -and $nvidiaRaw) {
							# Parse NVIDIA firmware info
							$nvidiaLines = $nvidiaRaw -split "`n"
							foreach ($line in $nvidiaLines) {
								if ($line -match '^([^,]+),\s*([^,]+),\s*(.+)$') {
									$driverVer = $matches[1].Trim()
									$vbiosVer = $matches[2].Trim()
									$gpuName = $matches[3].Trim()
									if ($gpuName -like "*$model*" -or $model -like "*$gpuName*") {
										$firmwareVersion = "Driver: $driverVer, VBIOS: $vbiosVer"
										break
									}
								}
							}
						} elseif ($manufacturer -eq "Intel" -and $videoDetailRaw) {
							# Get Intel driver version from lspci detailed output
							$videoDetailLines = $videoDetailRaw -split "`n"
							foreach ($line in $videoDetailLines) {
								if ($line -match "$([regex]::Escape($pciId)).*$([regex]::Escape($description))") {
									# Found matching device, look for driver info in next few lines
									$startIndex = [array]::IndexOf($videoDetailLines, $line)
									for ($i = $startIndex; $i -lt [math]::Min($startIndex + 10, $videoDetailLines.Count); $i++) {
										if ($videoDetailLines[$i] -match "Kernel driver in use:\s*(.+)") {
											$firmwareVersion = "Driver: $($matches[1])"
											break
										}
									}
									break
								}
							}
						}
						
						# Determine type based on device type and manufacturer
						$type = if ($deviceType -like "*VGA*") {
							if ($manufacturer -eq "NVIDIA") {
								"Discrete Graphics Card"
							} elseif ($manufacturer -eq "Intel") {
								"Integrated Graphics"
							} elseif ($manufacturer -eq "AMD" -or $manufacturer -eq "ATI") {
								"Graphics Card"
							} else {
								"Graphics Controller"
							}
						} elseif ($deviceType -like "*3D*") {
							"3D Graphics Controller"
						} else {
							"Display Controller"
						}
						
						[PSCustomObject]@{
							Type = $type
							Manufacturer = $manufacturer
							Model = $model
							FirmwareVersion = $firmwareVersion
						}
					}
				}
			)
			Audio = @(
				# Parse audio controllers and extract Type, Manufacturer, Model, Firmware Version
				$audioRaw | ForEach-Object {
					if ($_ -match '^([^\s]+)\s+(.+?):\s*(.+)$') {
						$pciId = $matches[1]
						$deviceType = $matches[2]
						$description = $matches[3]
						
						# Extract manufacturer and model from description
						$manufacturer = ""
						$model = $description
						
						if ($description -match '^(Intel|NVIDIA|AMD|ATI|Realtek|Creative|VIA|C-Media|ESS|Ensoniq)\s+(.+)$') {
							$manufacturer = $matches[1]
							$model = $matches[2]
						} elseif ($description -match '^(.+?)\s+(Corporation|Corp\.?|Technology|Tech)\s+(.+)$') {
							$manufacturer = "$($matches[1]) $($matches[2])"
							$model = $matches[3]
						}
						
						# Determine firmware/driver version (basic kernel driver info)
						$firmwareVersion = "Unknown"
						# Could be enhanced with detailed driver version extraction if needed
						
						# Determine type based on device type and manufacturer
						$type = if ($deviceType -like "*Audio*") {
							if ($manufacturer -eq "NVIDIA") {
								"HDMI Audio Controller"
							} elseif ($manufacturer -eq "Intel") {
								"Integrated Audio Controller"
							} elseif ($manufacturer -eq "Realtek") {
								"Audio Codec"
							} elseif ($manufacturer -eq "AMD" -or $manufacturer -eq "ATI") {
								"HD Audio Controller"
							} else {
								"Audio Controller"
							}
						} elseif ($deviceType -like "*Sound*") {
							"Sound Card"
						} else {
							"Audio Device"
						}
						
						[PSCustomObject]@{
							Type = $type
							Manufacturer = $manufacturer
							Model = $model
							FirmwareVersion = $firmwareVersion
						}
					}
				}
			)
			AudioStack = [PSCustomObject]@{
				PipewireVersion = 
					if ($pipewireRaw -and $pipewireRaw -match 'libpipewire\s+([\d\.]+)') {
						$matches[1]
					} else {
						"Not Available"
					}
				WirePlumberVersion = 
					if ($wireplumberRaw -and $wireplumberRaw -match 'libwireplumber\s+([\d\.]+)') {
						$matches[1]
					} else {
						"Not Available"
					}
				ServerInfo = 
					if ($pactlRaw -and $pactlRaw -match 'Server Name:\s*(.+)') {
						$matches[1].Trim()
					} else {
						"Unknown"
					}
				ServerVersion = 
					if ($pactlRaw -and $pactlRaw -match 'Server Version:\s*([\d\.]+)') {
						$matches[1]
					} else {
						"Unknown"
					}
				DefaultSampleFormat = 
					if ($pactlRaw -and $pactlRaw -match 'Default Sample Specification:\s*(.+)') {
						$matches[1].Trim()
					} else {
						"Unknown"
					}
				DefaultSink = 
					if ($pactlRaw -and $pactlRaw -match 'Default Sink:\s*(.+)') {
						$matches[1].Trim()
					} else {
						"Unknown"
					}
				DefaultSource = 
					if ($pactlRaw -and $pactlRaw -match 'Default Source:\s*(.+)') {
						$matches[1].Trim()
					} else {
						"Unknown"
					}
				ActiveSinks = @(
					# Parse wpctl status for active sinks
					if ($wpctlRaw) {
						$wpctlLines = $wpctlRaw -split "`n"
						$inSinksSection = $false
						foreach ($line in $wpctlLines) {
							if ($line -match '^\s*├─ Sinks:') {
								$inSinksSection = $true
								continue
							} elseif ($line -match '^\s*├─|^\s*└─' -and $inSinksSection) {
								$inSinksSection = $false
							} elseif ($inSinksSection -and $line -match '^\s*[\*\s]\s*(\d+)\.\s*(.+?)\s*\[vol:\s*([\d\.]+)\]') {
								$isDefault = $line -match '^\s*\*'
								$sinkId = [int]$matches[1]
								$sinkName = $matches[2].Trim()
								$volume = [decimal]$matches[3]
								[PSCustomObject]@{
									Id = $sinkId
									Name = $sinkName
									Volume = $volume
									IsDefault = $isDefault
								}
							}
						}
					}
				)
				ActiveSources = @(
					# Parse wpctl status for active sources
					if ($wpctlRaw) {
						$wpctlLines = $wpctlRaw -split "`n"
						$inSourcesSection = $false
						foreach ($line in $wpctlLines) {
							if ($line -match '^\s*├─ Sources:') {
								$inSourcesSection = $true
								continue
							} elseif ($line -match '^\s*├─|^\s*└─' -and $inSourcesSection) {
								$inSourcesSection = $false
							} elseif ($inSourcesSection -and $line -match '^\s*[\*\s]\s*(\d+)\.\s*(.+?)\s*\[vol:\s*([\d\.]+)\]') {
								$isDefault = $line -match '^\s*\*'
								$sourceId = [int]$matches[1]
								$sourceName = $matches[2].Trim()
								$volume = [decimal]$matches[3]
								[PSCustomObject]@{
									Id = $sourceId
									Name = $sourceName
									Volume = $volume
									IsDefault = $isDefault
								}
							}
						}
					}
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
		$video = $inventory.Video
		$audio = $inventory.Audio
	}
	
	# Return the requested category or full inventory
	if ($Category -eq "All") {
		return $inventory
	} else {
		# Return only the requested category
		switch ($Category) {
			"OperatingSystem" { return $inventory.OperatingSystem }
			"ComputerSystem" { return $inventory.ComputerSystem }
			"BIOS" { return $inventory.BIOS }
			"Processor" { return $inventory.Processor }
			"Disks" { return $inventory.Disks }
			"NetworkInterfaces" { return $inventory.NetworkInterfaces }
			"InstalledApplications" { return $inventory.InstalledApplications }
			"Video" { return $inventory.Video }
			"Audio" { 
				# For Audio, return both hardware and stack info
				return [PSCustomObject]@{
					Hardware = $inventory.Audio
					Stack = $inventory.AudioStack
				}
			}
			default { return $inventory }
		}
	}
}
