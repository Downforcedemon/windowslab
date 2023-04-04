function New-PowerLabSqlServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [pscredential]$DomainCredential,

        [Parameter(Mandatory)]
        [pscredential]$VMCredential,

        [Parameter()]
        [string]$VMPath = 'C:\PowerLab\VMs',

        [Parameter()]
        [int64]$Memory = 4GB,

        [Parameter()]
        [string]$Switch = 'PowerLab',

        [Parameter()]
        [int]$Generation = 2,

        [Parameter()]
        [string]$DomainName = 'powerlab.local',

        [Parameter()]
        [string]$AnswerFilePath = "C:\Program Files\WindowsPowerShell\Modules\PowerLab\SqlServer.ini"
    )

    ## Build the VM
    $vmParams = @{
        Name       = $Name
        Path       = $VmPath
        Memory     = $Memory
        Switch     = $Switch
        Generation = $Generation
    }
    New-PowerLabVm @vmParams

    Install-PowerLabOperatingSystem -VmName $Name
    Start-VM -Name $Name

    Wait-Server -Name $Name -Status Online -Credential $VMCredential

    $addParams = @{
        DomainName = $DomainName
        Credential = $DomainCredential
        Restart    = $true
        Force      = $true
    }
    Invoke-Command -VMName $Name -ScriptBlock { Add-Computer @using:addParams } -Credential $VMCredential

    Wait-Server -Name $Name -Status Offline -Credential $VMCredential
    Wait-Server -Name $Name -Status Online -Credential $DomainCredential

    $tempFile = Copy-Item -Path $AnswerFilePath -Destination "C:\Program Files\WindowsPowerShell\Modules\PowerLab\temp.ini" -PassThru

    Install-PowerLabSqlServer -ComputerName $Name -AnswerFilePath $tempFile.FullName -DomainCredential $DomainCredential
}
