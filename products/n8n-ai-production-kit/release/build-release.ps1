# Builds the Gumroad release ZIP for the n8n AI Workflow Production Kit.
# Refuses to build if any staged file trips the pre-export security scan.
param(
    [string]$Version = "0.2.0"
)

$ErrorActionPreference = "Stop"

$kitRoot = Split-Path -Parent $PSScriptRoot
$releaseDir = $PSScriptRoot
$packageName = "n8n-ai-production-kit-v$Version"
$staging = Join-Path $env:TEMP $packageName

Write-Host "== Staging $packageName =="
if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
New-Item -ItemType Directory -Force -Path $staging | Out-Null

# Docs at the ZIP root (README.md is the first thing a buyer should see).
Copy-Item (Join-Path $kitRoot "docs\*") $staging
Copy-Item (Join-Path $kitRoot "workflows") (Join-Path $staging "workflows") -Recurse
Copy-Item (Join-Path $kitRoot "test-data") (Join-Path $staging "test-data") -Recurse

# Buyer runtime files referenced by INSTALL.md: docker-compose + env template.
# The workflows mount path is rewritten to match the ZIP layout.
$repoRoot = Split-Path (Split-Path $kitRoot -Parent) -Parent
$compose = Get-Content (Join-Path $repoRoot "docker-compose.yml") -Raw
$compose = $compose.Replace('./products/n8n-ai-production-kit/workflows', './workflows')
[System.IO.File]::WriteAllText((Join-Path $staging "docker-compose.yml"), $compose)
Copy-Item (Join-Path $repoRoot ".env.example") (Join-Path $staging ".env.example")

# --- Gate 1: every workflow file must parse as JSON -------------------------
Write-Host "== Validating workflow JSON =="
$jsonErrors = @()
Get-ChildItem (Join-Path $staging "workflows") -Filter *.json | ForEach-Object {
    try {
        $null = Get-Content $_.FullName -Raw | ConvertFrom-Json
        Write-Host ("  OK   " + $_.Name)
    } catch {
        $jsonErrors += ($_.Name + ": " + $_.Exception.Message)
    }
}
if ($jsonErrors.Count -gt 0) {
    $jsonErrors | ForEach-Object { Write-Host ("  FAIL " + $_) -ForegroundColor Red }
    throw "JSON validation failed. Fix the workflow files and rebuild."
}

# --- Gate 2: secret / real-email scan ---------------------------------------
# Patterns are assembled by concatenation so this script never flags itself.
Write-Host "== Scanning for secrets and real email addresses =="
$patterns = @(
    ("openai_style_key",   ('sk' + '-[A-Za-z0-9_-]{10,}')),
    ("slack_bot_token",    ('xox' + 'b-[A-Za-z0-9-]{10,}')),
    ("github_token",       ('gh' + 'p_[A-Za-z0-9]{20,}')),
    ("github_pat",         ('github' + '_pat_[A-Za-z0-9_]{20,}')),
    ("aws_access_key_id",  ('AKIA' + '[0-9A-Z]{16}')),
    ("bearer_literal",     ('Bearer' + ' [A-Za-z0-9._~+/=-]{15,}')),
    ("real_email",         ('[A-Za-z0-9._%+-]+' + '@(?!example\.(com|org|net))[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}'))
)

$findings = @()
Get-ChildItem $staging -Recurse -File | ForEach-Object {
    $file = $_
    $text = Get-Content $file.FullName -Raw
    foreach ($p in $patterns) {
        $label = $p[0]
        $regex = $p[1]
        $matches2 = [regex]::Matches($text, $regex)
        foreach ($m in $matches2) {
            $preview = $m.Value
            if ($preview.Length -gt 8) { $preview = $preview.Substring(0, 4) + "***" + $preview.Substring($preview.Length - 2) }
            $findings += [pscustomobject]@{
                File    = $file.FullName.Substring($staging.Length + 1)
                Pattern = $label
                Preview = $preview
            }
        }
    }
}

if ($findings.Count -gt 0) {
    Write-Host "SECURITY SCAN FAILED - build refused:" -ForegroundColor Red
    $findings | Format-Table -AutoSize | Out-String | Write-Host
    throw ("{0} finding(s). Fix the source files (see shared/checklists/pre-export-security-checklist.md) and rebuild." -f $findings.Count)
}
Write-Host "  Clean."

# --- Package -----------------------------------------------------------------
$zipPath = Join-Path $releaseDir ($packageName + ".zip")
if (Test-Path $zipPath) { Remove-Item -Force $zipPath }
Compress-Archive -Path (Join-Path $staging "*") -DestinationPath $zipPath
Remove-Item -Recurse -Force $staging

Write-Host "== Built $zipPath =="
Write-Host "Next: import into a CLEAN n8n instance and follow INSTALL.md from scratch before uploading to Gumroad."
