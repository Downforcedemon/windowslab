#create a blank module--> on a hyper v
# New-Item -path c:\Program files\ WindoewsPowershell/Modules/Powerlab -itemtype Directory
# create a manifest using New-ModuleManifest -path

# get0module -name Powerlab -listavailable    (test if it imports)

#1. check vSwitch is present, create one if not
function New-PowerLabSwitch {
    param (
        [Parameter()] [String]$SwitchName = 'Powerlab',
        [Parameter()] [string]$SwitchType = 'External'
    )
    if (-not (Get-VmSwitch -Name $SwitchName -SwitchType $SwitchType -ErrorAction Silentlycontinue)) {
        $null = New-VMSwitch -Name $SwitchName -SwitchType $SwitchType
    }
    else {
        Write-Host -Message "The Switch [$($SwitchName)] has already been created"
    } 
}
# automate vm creation
function New-PowerLabVm 
{param(
    [Parameter(Mandatory)] [string]$Name,
    [Parameter()] [string]$path = 'C:\Powerlab/VMs',
    [Parameter()][string]$Memory = 4GB,
    [Parameter()][string]$Switch = 'Powerlab',
    [Parameter ()][ValidateRange (1,2)][int]$Generation = 2
)
if (-not (Get-Vm -Name $Name -ErrorAction Silentlycontinue)) {
    $null = New-Vm -Name $Name -path $path -MemoryStartupBytes $Memory -Switch $Switch -Generation $Generation
}
else {
    Write-Verbose "The VM [$($Name)] has already been created"
}
} 
#VHD creation, don't use this if creating VHD from iso
function New-PowerLabVhd {
    param (
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandaory)][string]$AttachtoVm,
        [Parameter()][Validaterange(512MB, 1TB)] [int64]$size = 50GB,
        [Parameter()][ValidateSet('Dynamic','Fixed')][string]$Sizing = 'Dynamic',
        [Parameter()][string]$path = 'C:\PowerLab\VHDs'
    )
    $vhdxfileName = "$name.vhdx"
    $vhdxFilepath = Join-path -Path $path -childPath "$Name.vhdx"
    ### ensure don't create another vhd if there is another one
    if (-not (Test-Path -Path $vhdxFilepath -PathType Leaf)) {
        $params = @{
            Sizebytes = $size
            Path = $vhdxFilepath
        }
        if ($Sizing -eq 'Dynamic') {
            $params.Dynamic = $true
        }
        elseif ($Sizing -eq 'fixed') {
            $params.Fixed = $true
        }
        New-VHD @params Write-Verbose -Message "Created new VHD at path [$($vhdxFilepath)]"
    }
    if ($PSBoundParameters.ContainsKey('AttachToVm')) {
        if (-not ($vm = Get-VM -Name $AttachToVm -ErrorAction SilentlyContinue)) {
            Write-Warning -Message "The VM [$($AttachToVm)] does not exist. Unable to attach VHD."
        }
        elseif (-not ($vm | Get-VMHardDiskDrive | Where-Object { $_.Path -eq $vhdxFilepath })) {
            $vm | Add-VMHardDiskDrive -Path $vhdxFilepath
            Write-Verbose -Message "Attached VHDX [$($vhdxFilepath)] to VM [$($AttachToVM)]."
        }
        else {
            Write-Verbose -Message "VHDX [$($vhdxFilepath)] already attached to VM [$($AttachToVm)]."
        }
    }
    #converting iso file to Vhdx by script in answerFilePath
$isofilepath = 'C:\PowerLab\ISOs\en_windoes_server_2016_x64_dvd_9718492.iso'
$answerFilePath = 'C:\PowerShellforSysadmins\Part2|Automating Operating system Installs\LABDC.xml'
$convertParams = @{
    SourcePath = $isofilepath
    SizeBytes = 40GB 
    Edition = 'ServerStandardCore'
    VHDFormat = 'VHDX'
    VHDPath = 'C:\PowerLab\VHDs\LABDC.vhdx'
    VHDType = 'Dynamic'
    VHDPartitionStyle = 'GPT'
    UnattendPath = $answerFilePath

}
#dot source covertWindowsimage.ps1 to covert ISO into working oS. output should be file.vhdx ready to boot
."$PSScriptRoot\Covert-WindowsImage.ps1"
# attach file.vhdx file to VM
$vm = Get-Vm -Name = 'LABDC'
Add-VMHardDiskDrive -VMName 'LABDC' -Path 'C:\PowerLab\VHDs\LABDC.vhdx'
#set VHDx as first boot device
$vm | Set-VMFirmware -FirstBootDevice $vm.HardDrives[0]

