function Write-FPLog {
    <#
    .SYNOPSIS
        Output Writing Handler
    .DESCRIPTION
        Yet another stupid Write-Log function like everyone else has
    .PARAMETER Category
        Describes type of information as 'Info','Warning','Error' (default is 'Info')
    .PARAMETER Message
        Information to display or write to log file
    .EXAMPLE
        Write-FPLog -Category 'Info' -Message 'This is a message'
    #>
        param (
            [parameter(Mandatory = $True)]
            [ValidateNotNullOrEmpty()]
            [string] $Message,
            [parameter(Mandatory = $False)]
            [ValidateSet('Info', 'Warning', 'Error')]
            [string] $Category = 'Info'
        )
        Write-Verbose "$(Get-Date -f 'yyyy-M-dd HH:mm:ss')  $Category  $Message"
        "$(Get-Date -f 'yyyy-M-dd HH:mm:ss')  $Category  $Message" | Out-File $Script:FPLogFile -Encoding Default -Append
}
