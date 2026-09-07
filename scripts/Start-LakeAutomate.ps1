$ErrorActionPreference = "Stop"

$RepoRoot = "C:\Projects\LakeAutomate"
$Python = Join-Path $RepoRoot ".venv\Scripts\python.exe"

if (-not (Test-Path $Python)) {
    throw "LakeAutomate Python environment not found: $Python"
}

foreach ($name in @("LAKE_HA_URL", "LAKE_HA_TOKEN", "LAKE_API_KEY")) {
    if (-not [Environment]::GetEnvironmentVariable($name, "Machine")) {
        throw "Required machine environment variable is missing: $name"
    }
}

Set-Location $RepoRoot
Start-Sleep -Seconds 30

& $Python -m uvicorn lakeautomate.api:app `
    --app-dir "$RepoRoot\src" `
    --host 0.0.0.0 `
    --port 8780
