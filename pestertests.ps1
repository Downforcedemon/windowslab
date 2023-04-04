BeforeAll { 
    $cred = Import-cliXml -Path C:\PowerLab\VMCredential.xml
    $session = New-PSSession -VMName 'LABDC -Credential $cred'
}
AfterAll {
    $session | Remove-PSSession
}
