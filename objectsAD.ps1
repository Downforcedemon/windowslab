#Import excel users file
# Import-Excel -Path 'C:\Program Files\WindowsPowerShell\Modules\PowerLab\
# ActiveDirectoryObjects.xlsx' -WorksheetName Users | Format-Table -AutoSize
#import group file
#Import-Excel -Path 'C:\Program Files\WindowsPowerShell\Modules\PowerLab\
# ActiveDirectoryObjects.xlsx' -WorksheetName Groups | Format-Table -AutoSize
# creating Ad-Object
# Import users data from an Excel file located at 'C:\' with worksheet name 'Users'
$users = Import-Excel -Path 'C:\' -WorksheetName Users

# Import groups data from an Excel file located at 'C:\' with worksheet name 'Groups'
$groups = Import-Excel -path 'C:\' -WorksheetName Groups

# Loop through each group in the $groups array
foreach ($group in $groups ) {

    # Check if an Active Directory Organizational Unit (OU) named "OUName" exists. If it doesn't exist, then create a new OU with the same name.
    if (-not (Get-AdOrganizationalUnit -Filter "Name -eq 'OUName'")) {
        New-ADOrganizationalUnit -Name OUName 
    }

    # Check if an Active Directory group named "GroupName" exists. If it doesn't exist, then create a new group with the same name, a specified group scope (which can be "DomainLocal", "Global", or "Universal"), and place it in the OU named "OUName".
    if (-not (Get-ADGroup -Filter "Name -eq 'GroupName'")) { 
        New-ADGroup -Name GroupName -GroupScope GroupScope -path "OU=OUName, DC=server1, DC=com"
    }

    # Loop through each user in the $users array
    foreach ($user in $users) {

        # Check if an Active Directory user named "Username" exists. If it doesn't exist, then create a new user with the same name and place it in the OU named "OUName" in the Active Directory domain specified by the DC (domain controller) values.
        if (-not (Get-ADUser -Filter "Name -eq 'Username'")) { 
            New-AzADUser -Name $user.UserName -Path "OU=OUName,DC=server1,DC=com"
        }

        # Check if the user named "Username" is a member of the group named "GroupName". If the user is not a member of the group, then add the user to the group.
        if (UserName -notin (Get-AdGrouMemeber -Identity GroupName).Name) {
            Add-AdGroupMember -Identity GroupName -Members UserName
        }
    }
}

