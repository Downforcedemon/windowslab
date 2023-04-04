#create a VM using previous functions
New-PowerLabVM -Name 'Sqlserver'
#need an xml file--> change computername, ip
Copy-Item -Path 'C:\Program Files\WindoesPowerShell\Modules\PowerLab\LABDC.xml' -Destination 'C:\Program Files\WindowsPowerShell\Modules\PowerLab\Sqlserver.xml'
#create an os
Install-PowerLabOperationSystem -VmName 'Sqlserver'
Start-VM -Name Sqlserver
#check if Vm is online
$VmCred = Import-Clixml -Path 'C:\PowerLab\VMCredential.xml'

while (-not (Invoke-Command -VMName 'Sqlserver' -ScriptBlock { 1 } -Credential $VmCred -ErrorAction Ignore)) {
    Start-Sleep -Seconds 10
    Write-Host 'Waiting for Sqlserver to come up...'
}
#add to domain
$domainCred = Import-Clixml -Path 'C:\PowerLab\DomainCredential.xml'
$addParams = @{
    DomainName = 'server1.com'
    Credential = $domainCred
    Restart = $true 
    Force = $true
}
Invoke-Command -VMName 'Sqlserver' -ScriptBlock {
    Add-Computer @using:Addparams
} -Credential $domainCred     
#wait for it to go down and come back up 
while (Invoke-Command -VmName Sqlserver -Scriptblock {1} -Credential $domainCred -ErrorAction Ignore) {
    Start-Sleep -Seconds 10 Write-Host 'Waiting for Sqlserver to go down..'
}
while (-Not (Invoke-command -VMName Sqlserver -ScriptBlock {1} -Credential $domainCred -ErrorAction Ignore)) {
    Start-Sleep -Seconds 10 Write-Host 'Waiting for it come back up'
}
#installation
#copy files to server
$session = New-PSSession -VMName 'Sqlserver' -Credential $domainCred
$sqlServerAnswerfilePath = "C:\Program Files\WindowsPowerShell\Modules\PowerLab\SqlServer.ini"
$tempfile = Copy-Item -Path $sqlServerAnswerfilePath -Destination "C:\Program Files\.ini" -PassThru

#change config in tempfile
$configContents = Get-Content -Path $tempFile.FullName -Raw
$configContents = $configContents.Replace('SQLSVCACCOUNT=""', 'SQLSVCACCOUNT="PowerLabUser"')
$configContents = $configContents.Replace('SQLSVCPASSWORD=""', 'SQLSVCPASSWORD="P@$$w0rd12"')
$configContents = $configContents.Replace('SQLSYSADMINACCOUNTS=""', 'SQLSYSADMINACCOUNTS=
"PowerLabUser"')
Set-Content -Path $tempFile.FullName -Value $configContents

#copy tempfile and iso file to server

$copyParams = @{ 
    Path        = $tempFile.FullName 
    Destination = 'C:\' 
    ToSession   = $session
}
Copy-Item @copyParams
Remove-Item -Path $tempFile.FullName -ErrorAction Ignore
Copy-Item -Path 'C:\PowerLab\ISOs\en_sql_server_2016_standard_x64_dvd_8701871.iso' 
-Destination 'C:\' -Force -ToSession $session

#run the installer
$icmParams = @{
    Session = $session
    ArgumentList = $tempFile.Name
    ScriptBlock = {
        $image = Mount-DiskImage -ImagePath 'C:\en_sql_server_2016_standard_x64_dvd_8701871.iso' -PassThru
        $installerPath = "$(($image | Get-Volume).DriveLetter):"
        & "$installerPath\setup.exe" "/CONFIGURATIONFILE=C:\$($using:tempFile.Name)"
        $image | Dismount-DiskImage
    }
}

Invoke-Command @icmParams
