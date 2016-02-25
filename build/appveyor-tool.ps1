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

  Progress "Adding GnuWin32 tools to PATH"
  $env:PATH = "C:\Program Files (x86)\Git\bin;" + $env:PATH

    InstallCFTools

  if ( Test-Path "/**/src" ) {
    InstallRtools
  }
  Else {
    Progress "Skipping download of Rtools because src/ directory is missing."
  }

  Progress "Downloading and installing travis-tool.sh"
  Invoke-WebRequest http://raw.github.com/krlmlr/r-travis/master/scripts/travis-tool.sh -OutFile "..\travis-tool.sh"
  echo '@bash.exe ../travis-tool.sh %*' | Out-File -Encoding ASCII .\travis-tool.sh.cmd
  cat .\travis-tool.sh.cmd
  bash -c "echo '^travis-tool\.sh\.cmd$' >> .Rbuildignore"
  cat .\.Rbuildignore

  $env:PATH.Split(";")

  Progress "Setting R_LIBS_USER"
  $env:R_LIBS_USER = 'c:\RLibrary'
  mkdir $env:R_LIBS_USER

  Progress "Bootstrap: Done"
}

Function InstallCFTools {
  [CmdletBinding()]
  Param()
    $url= "https://github.com/dicko2/CompactFrameworkBuildBins/blob/master/NETCFSetupv35.msi";
    Progress ("Downloading NETCFSetupv35 from: " + $url)
    Exec { bash -c ("curl --silent -o ../R-win.exe -L " + $url) }
    
    $url= "https://github.com/dicko2/CompactFrameworkBuildBins/blob/master/NETCFv35PowerToys.msi";
    Progress ("Downloading NETCFv35PowerToys from: " + $url)
    Exec { bash -c ("curl --silent -o ../R-win.exe -L " + $url) }
  
    Progress "Running NETCFSetupv35 installer"
  
    $msi = @("NETCFSetupv35.msi","NETCFv35PowerToys.msi")
    foreach ($msifile in $msi) 
    {
    Start-Process -FilePath "$env:systemroot\system32\msiexec.exe" -ArgumentList "/i `"$msifile`" /qn /norestart" -Wait -WorkingDirectory $pwd
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