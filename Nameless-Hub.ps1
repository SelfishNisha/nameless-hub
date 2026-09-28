$projects = @(
  @{
    Name = "USB Connections - live info of every fat32 connected to the system"
    Url  = "https://raw.githubusercontent.com/NameLessF0/USB-Connections/refs/heads/main/USB-Connections"
    File = "USB-Connections.ps1"
  }
  @{
    Name = "Mod Reviewer - Scans the minecraft mods folder (or the provided path) for cheats"
    Url  = "https://raw.githubusercontent.com/NameLessF0/Mod-Reviewer/refs/heads/main/Mod-Reviewer.ps1"
    File = "Mod-Reviewer.ps1"
  }
  @{
    Name = "Detective - scans every drive for .jar .bat .exe .dll (might take A LOT OF TIME to finish)"
    Url  = "https://raw.githubusercontent.com/NameLessF0/Detective/refs/heads/main/Detective.ps1"
    File = "Detective.ps1"
  }
  @{
    Name = "Service Checker - Checks if certain services are disabled or enabled"
    Url  = "https://raw.githubusercontent.com/NameLessF0/Service-Checker/refs/heads/main/Service-Checker.ps1"
    File = "Service-Checker.ps1"
  }
)

function Boot {
  Write-Host "-------------------------------"
  Write-Host "Nameless Hub"
  Write-Host ""
  Write-Host "Github: https://github.com/NameLessF0"
  Write-Host "Source Code: https://github.com/SelfishNisha/nameless-hub"
  Write-Host "-------------------------------"
}

function Get-PowerShellPath {
  # Prefer PowerShell 7+ (pwsh.exe), fall back to Windows PowerShell 5.1
  $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
  if ($pwsh) { return $pwsh.Source }

  $candidates = @(
    "$env:ProgramFiles\PowerShell\7\pwsh.exe",
    "$env:ProgramFiles\PowerShell\7-preview\pwsh.exe",
    "${env:ProgramFiles(x86)}\PowerShell\7\pwsh.exe",
    "$env:LOCALAPPDATA\Microsoft\PowerShell\pwsh.exe",
    "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe"
  )
  foreach ($c in $candidates) {
    if ($c -and (Test-Path $c)) { return $c }
  }

  return "powershell.exe"
}

function Start-Project {
  param($project)

  $dest = Join-Path $env:TEMP $project.File

  Write-Host "Downloading $($project.Name)..." -ForegroundColor Cyan
  # curl.exe ships with Windows 10 1803+ / Server 2019+. -L follows redirects, -f fails on HTTP errors.
  & curl.exe -L -f -s -o $dest $project.Url

  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $dest)) {
    Write-Host "Download failed (curl exit $LASTEXITCODE)." -ForegroundColor Red
    return
  }

  Write-Host "Saved to: $dest"

  $psExe = Get-PowerShellPath
  $psName = if ($psExe -like "*pwsh.exe") { "PowerShell 7" } else { "Windows PowerShell 5.1 (PowerShell 7 not found)" }
  Write-Host "Launching in child process using $psName..." -ForegroundColor Cyan

  try {
    Start-Process -FilePath $psExe `
      -WorkingDirectory $env:TEMP `
      -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$dest`"" `
      -ErrorAction Stop
  }
  catch {
    Write-Warning "Child process blocked ($($_.Exception.Message)). Running in background job instead."
    Start-Job -ScriptBlock {
      param($exe, $f)
      & $exe -ExecutionPolicy Bypass -File $f
    } -ArgumentList $psExe, $dest | Out-Null
  }
}

function Show-Projects {
  for ($i = 0; $i -lt $projects.Count; $i++) {
    Write-Host ("[{0}] {1}" -f ($i + 1), $projects[$i].Name)
  }
  Write-Host ""
  Write-Host "[0] Exit"
  Write-Host ""

  $choice = Read-Host "Select a project"

  if ($choice -eq "0") {
    Write-Host "Goodbye."
    return
  }

  $index = [int]$choice - 1
  if ($index -ge 0 -and $index -lt $projects.Count) {
    Start-Project -project $projects[$index]
  }
  else {
    Write-Host "Invalid selection." -ForegroundColor Red
  }
}

Boot
Show-Projects