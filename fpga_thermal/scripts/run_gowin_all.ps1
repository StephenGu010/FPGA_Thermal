$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Gowin = "F:\application\Gowin\Gowin_V1.9.11.03_Education_x64\IDE\bin\gw_sh.exe"
$Script = Join-Path $Root "scripts\run_gowin_all.tcl"

if (!(Test-Path $Gowin)) {
  throw "gw_sh.exe not found at $Gowin"
}

Push-Location $Root
try {
  & $Gowin $Script
  if ($LASTEXITCODE -ne 0) {
    throw "Gowin implementation failed with exit code $LASTEXITCODE"
  }
}
finally {
  Pop-Location
}
