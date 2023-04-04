#Data protection API under Get-Credential and outputs PScredential object
# Encrypt the password and save it to a file
$securePassword = ConvertTo-SecureString 'MyPassword' -AsPlainText -Force
$securePassword | ConvertFrom-SecureString | Out-File 'C:\path\to\password.txt'

# Decrypt the password from the file
$encryptedPassword = Get-Content 'C:\path\to\password.txt' | ConvertTo-SecureString
$credential = New-Object System.Management.Automation.PSCredential ('username', $encryptedPassword)

# Use the credential object in your script
Connect-RemoteServer -Credential $credential
