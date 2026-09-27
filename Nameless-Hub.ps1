$projects = @(
  @{
    Name = "USB-Connections - live info of every fat32 connected to the system"
    Url  = "https://raw.githubusercontent.com/NameLessF0/USB-Connections/refs/heads/main/USB-Connections"
    File = "USB-Connections.ps1"
  }
  @{
    Name = "Mod-Reviewer - Scans the minecraft mods folder (or the provided path) for cheats"
    Url  = "https://raw.githubusercontent.com/NameLessF0/Mod-Reviewer/refs/heads/main/Mod-Reviewer.ps1"
    File = "Mod-Reviewer.ps1"
  }
  @{
    Name = "Detective - scans every drive for .jar .bat .exe .dll (might take A LOT OF TIME to finish)"
    Url  = "https://raw.githubusercontent.com/NameLessF0/Detective/refs/heads/main/Detective.ps1"
    File = "Detective.ps1"
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
  Write-Host "Launching in child process..." -ForegroundColor Cyan

  try {
    Start-Process -FilePath "powershell.exe" `
      -WorkingDirectory $env:TEMP `
      -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$dest`"" `
      -ErrorAction Stop
  }
  catch {
    Write-Warning "Child process blocked ($($_.Exception.Message)). Running in background job instead."
    Start-Job -ScriptBlock { param($f) & powershell -ExecutionPolicy Bypass -File $f } -ArgumentList $dest | Out-Null
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