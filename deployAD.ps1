#install domain-services
$cred = Import-Clixml -Path C:\files.xml
Invoke-command -VMName 'LABDC' -Credential $cred -ScriptBlock {
    Install-windoesfeature -Name Ad-Domain-services
}
#create a forest
'Password12' | ConvertTo-SecureString -force -asplaintext | Export-Clixml -path C:\PowerLab\Safemodeadminpassword.xml
$safeModePw = Import-Clixml -Path C:\Powerlab\Safemodeadminpassword.xml
$cred = Import-Clixml -Path C:\PowerLab\VMCredential.xml
$forestParams = @{ 
    DomainName = 'server2.com'
    DomainMode = 'Winthreshold'
    ForestMode = 'Winthreshold'
    Confirm = $false
    Safemodeadminpassword = $safeModePw
    WarningAction = 'Ignore'
}
