#Remoting via PS
Invoke-Command -ComputerName -ScriptBlock {  }
#PS direct
## prompt the user to enter username/password. export-clixml will serialize the resulting 'PSCredential' and same into path
Get-Credential | Export-Clixml -Path C:\PowerLab\VMCredential.xml
# 
$cred = Import-Clixml -Path C:\PowerLab\VMCredential.xml
# 
Invoke-Command -VMName LABDC -ScriptBlock { hostname } -Credential $cred
