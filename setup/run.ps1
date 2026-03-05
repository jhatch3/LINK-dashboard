Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Repo root = parent of /setup
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

function Get-PythonCmd {
  if (Get-Command python -ErrorAction SilentlyContinue) { return "python" }
  if (Get-Command py -ErrorAction SilentlyContinue) { return "py -3" }
  if (Get-Command python3 -ErrorAction SilentlyContinue) { return "python3" }
  throw "Python not found. Install Python 3.x and try again."
}

$Py = Get-PythonCmd

$VenvDir = Join-Path $RepoRoot ".venv"
$WinScriptsDir = Join-Path $VenvDir "Scripts"
$Activate = Join-Path $WinScriptsDir "Activate.ps1"
$VenvPython = Join-Path $WinScriptsDir "python.exe"

# If .venv exists but is a Unix/WSL venv (bin/activate) or missing Windows scripts, rebuild
$UnixActivate = Join-Path $VenvDir "bin\activate"
$NeedsRebuild = $false

if (Test-Path $VenvDir) {
  if (-not (Test-Path $Activate) -or -not (Test-Path $VenvPython)) {
    $NeedsRebuild = $true
  }
  if ((Test-Path $UnixActivate) -and (-not (Test-Path $Activate))) {
    $NeedsRebuild = $true
  }
}

if (-not (Test-Path $VenvDir) -or $NeedsRebuild) {
  if (Test-Path $VenvDir) {
    Write-Host "Existing .venv is not a Windows venv (missing Scripts\Activate.ps1). Rebuilding..."
    Remove-Item -Recurse -Force $VenvDir
  }
  & $Py -m venv .venv
  Write-Host "Created virtual environment: $VenvDir"
} else {
  Write-Host "Virtual environment already exists: $VenvDir"
}

# ✅ Activate venv in this script session
if (-not (Test-Path $Activate)) {
  throw "Activate.ps1 still not found at: $Activate"
}
. $Activate

# Sanity check: confirm venv is active
if (-not $env:VIRTUAL_ENV) { throw "Venv activation failed (VIRTUAL_ENV not set)." }
$PyPath = (Get-Command python).Source
if ($PyPath -notmatch "\\.venv\\Scripts\\python\.exe$") {
  throw "Not using venv python. Current python: $PyPath"
}

# Upgrade tooling inside venv
python -m pip install --upgrade pip setuptools wheel

# Install deps inside venv
if (Test-Path "requirements.txt") {
  python -m pip install -r requirements.txt
  Write-Host "Installed dependencies from requirements.txt"
} elseif (Test-Path "pyproject.toml") {
  python -m pip install -e .
  Write-Host "Installed project from pyproject.toml (editable)"
} else {
  Write-Warning "No requirements.txt or pyproject.toml found. Nothing to install."
}

Write-Host "`nDone."