#set up vm
#set up IIS
function Install-PowerLabWebServer {
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [pscredential]$DomainCredential
    )

    $session = New-PSSession -VMName $ComputerName -Credential $DomainCredential
    Invoke-Command -Session $session -ScriptBlock {
        Add-WindowsFeature -Name 'Web-Server'
    }
    Remove-PSSession $session
}
#installation/setup
Install-PowerLabWebServer -ComputerName $Name -DomainCredential $DomainCredential

#working, import webadministration module
$session = New-PSSession -VMName Web-Server -Credential (Import-Clixml -Path C:\)
Enter-PSSession -Session $session
Import-Module webadministration

#Websites
Get-Website -Name 'Default Web Site' | remove-website     
#new
New-website -Name Powershell -physicalpath C:\ 

#apps pool

#config certificate
function New-IISCertificate {
    param(
        [Parameter(Mandatory)]
        [string]$WebServerName,
        [Parameter(Mandatory)]
        [SecureString]$PrivateKeyPassword,
        [Parameter()]
        [string]$CertificateSubject = 'PowerShellForSysAdmins',
        [Parameter()]
        [string]$PublicKeyLocalPath = 'C:\PublicKey.cer',
        [Parameter()]
        [string]$PrivateKeyLocalPath = 'C:\PrivateKey.pfx',
        [Parameter()]
        [string]$CertificateStore = 'Cert:\LocalMachine\My'
    )

    # Generate a new self-signed certificate
    $cert = New-SelfSignedCertificate `
        -DnsName $WebServerName `
        -CertStoreLocation $CertificateStore `
        -Subject $CertificateSubject `
        -FriendlyName $CertificateSubject `
        -KeyExportPolicy Exportable `
        -KeyAlgorithm RSA `
        -HashAlgorithm SHA256 `
        -KeyLength 2048 `
        -NotAfter (Get-Date).AddYears(5) `
        -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" `
        -KeyUsage DigitalSignature,KeyEncipherment `
        -Type SSLServerAuthentication

    # Export the public and private keys to files
    $pwd = ConvertTo-SecureString -String $PrivateKeyPassword -Force -AsPlainText
    Export-Certificate `
        -Cert $cert `
        -FilePath $PublicKeyLocalPath
    Export-PfxCertificate `
        -Cert $cert `
        -FilePath $PrivateKeyLocalPath `
        -Password $pwd

    # Display information about the certificate
    $cert | Format-List *

    # Install the certificate in the certificate store
    $certThumbprint = $cert.Thumbprint
    $certPath = "Cert:\LocalMachine\My\" + $certThumbprint
    Import-PfxCertificate `
        -FilePath $PrivateKeyLocalPath `
        -CertStoreLocation $CertificateStore `
        -Password $pwd `
        -Exportable:$true `
        -CertFriendlyName $CertificateSubject `
        -ErrorAction Stop
}
