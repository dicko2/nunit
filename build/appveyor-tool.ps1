## Pilferd from https://github.com/krlmlr/r-appveyor/blob/master/scripts/appveyor-tool.ps1
## Thanks to Kirill Müller
Function Exec
{
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=1)]
        [scriptblock]$Command,
        [Parameter(Position=1, Mandatory=0)]
        [string]$ErrorMessage = "Execution of command failed.`n$Command"
    )
    $ErrorActionPreference = "Continue"
    & $Command 2>&1 | %{ "$_" }
    if ($LastExitCode -ne 0) {
        throw "Exec: $ErrorMessage`nExit code: $LastExitCode"
    }
}

Function Bootstrap {
  [CmdletBinding()]
    Param()

    Progress "Bootstrap: Start"

    if(!(Test-Administrator)) 
    {
        throw "Current executing user is not an administrator, please check your settings and try again."
    }  
    Progress "Adding GnuWin32 tools to PATH"
    $env:PATH = "C:\Program Files (x86)\Git\bin;" + $env:PATH

    InstallCFTools

    Progress "Bootstrap: Done"
}

Function InstallCFTools {
  [CmdletBinding()]
  Param()
   $url= "https://github.com/dicko2/CompactFrameworkBuildBins/raw/master/NETCFSetupv35.msi";
    Progress ("Downloading NETCFSetupv35 from: " + $url)
    Invoke-WebRequest -Uri $url -OutFile NETCFSetupv35.msi
    
    $url= "https://github.com/dicko2/CompactFrameworkBuildBins/raw/master/NETCFv35PowerToys.msi";
    Progress ("Downloading NETCFv35PowerToys from: " + $url)
    Invoke-WebRequest -Uri $url -OutFile NETCFv35PowerToys.msi
    
    Get-ChildItem -Path C:\Windows\Microsoft.NET -Filter Microsoft.CompactFramework.Common.targets -Recurse
    dir C:\Windows\Microsoft.NET\Framework\v3.5\
    dir C:\Windows\Microsoft.NET\Framework64\v3.5\
    
    Progress("Running NETCFSetupv35 installer")
  
    $msi = @("NETCFSetupv35.msi","NETCFv35PowerToys.msi")
    foreach ($msifile in $msi) 
    {
    if(!(Test-Path($msi)))
    {
        throw "MSI files are not present, please check logs."
    }
    Progress("Installing msi " + $msifile )
    Start-Process -FilePath "$env:systemroot\system32\msiexec.exe" -ArgumentList "/i `"$msifile`" /qn /norestart" -Wait -WorkingDirectory $pwd  -RedirectStandardOutput stdout.txt -RedirectStandardError stderr.txt
    $OutputText = get-content stdout.txt
    Progress($OutputText)
    $OutputText = get-content stderr.txt
    Progress($OutputText) 
    }
    if(!(Test-Path("C:\Windows\Microsoft.NET\Framework\v3.5\Microsoft.CompactFramework.CSharp.targets")))
    {
        throw "Compact framework files not found after install, install may have failed, please check logs."
    }
}

Function Progress
{
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=0)]
        [string]$Message = ""
    )
    $ProgressMessage = '== ' + (Get-Date) + ': ' + $Message

    Write-Host $ProgressMessage -ForegroundColor Magenta
}

function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}