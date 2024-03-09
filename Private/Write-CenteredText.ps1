function Write-CenteredText {
	<#
    .SYNOPSIS
    Print Text with Center Justification sort of
    
    .DESCRIPTION
    Kind of sort of in a way make it look centered
    
    .PARAMETER Caption
    Text to print
    
    .PARAMETER Filler
    Characters to print before and after as a divider
    
    .PARAMETER MaxLen
    Total number of characters to show on the line
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
	param (
		[parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string] $Caption,
		[parameter(Mandatory = $False)][string] $Filler = "*",
		[parameter(Mandatory = $False)][int] $MaxLen = 73
	)
	$caplen  = $Caption.Length + 2
	$remlen  = $MaxLen - $caplen
	$halflen = [math]::Round($remlen / 2, 0)
	$text    = "$($Filler*$halflen) $Caption $($Filler*$halflen)"
	if ($text.Length -lt $MaxLen) {
		$remx = $MaxLen - $text.Length
		$text += "$($Filler*$remx)"
	}
	Write-Output $text
}