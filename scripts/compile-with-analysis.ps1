# compile-with-analysis.ps1
param(
    [string]$projectPath
)

Write-Host "Project path: $projectPath"

# Read app.json to get app details
$appJsonPath = Join-Path $projectPath 'app.json'
if (-not (Test-Path $appJsonPath)) {
    Write-Error "app.json not found at $appJsonPath"
    exit 1
}
$appJson = Get-Content $appJsonPath | ConvertFrom-Json
$appName = $appJson.name
$appVersion = $appJson.version
$publisher = $appJson.publisher

# Construct the output file name
$safeAppName = $appName -replace '[\\/:*?"<>|]', '' # Remove invalid file name characters
$outputFileName = "${publisher}_${safeAppName}_${appVersion}.app"

# Find the latest AL extension path
$alExtensionPath = Get-ChildItem -Path (Join-Path $env:USERPROFILE '.vscode\extensions\ms-dynamics-smb.al-*') | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
if (-not $alExtensionPath) {
    Write-Error "AL extension not found."
    exit 1
}

# Find alc.exe by searching recursively within the extension folder
$alcPath = (Get-ChildItem -Path $alExtensionPath.FullName -Recurse -Filter 'alc.exe' | Select-Object -First 1).FullName
if (-not $alcPath) {
    Write-Error "alc.exe not found in $($alExtensionPath.FullName)"
    exit 1
}

# Find analyzer DLLs based on your settings.json
$analyzerDlls = @(
    "Microsoft.Dynamics.Nav.CodeCop.dll",
    "Microsoft.Dynamics.Nav.UICop.dll"
)

$analyzerPaths = $analyzerDlls | ForEach-Object {
    $found = Get-ChildItem -Path $alExtensionPath.FullName -Recurse -Filter $_ -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $found.FullName
    } else {
        Write-Warning "Analyzer '$_' not found in $($alExtensionPath.FullName)"
    }
}

$analyzerArgs = $analyzerPaths | Where-Object { $_ } | ForEach-Object { "/analyzer:`"$_`"" }

# Define other paths
$packageCachePath = Join-Path $projectPath '.alpackages'
$outPath = Join-Path $projectPath $outputFileName

# Build argument list
$argumentList = @(
    "/project:`"$projectPath`"",
    "/out:`"$outPath`"",
    "/packagecachepath:`"$packageCachePath`""
) + $analyzerArgs

Write-Host "Starting AL compilation with full analysis..."
Write-Host "Compiler Path: $alcPath"
Write-Host "Output File:   $outPath"
Write-Host "Arguments: $($argumentList -join ' ')"

# Execute the compiler
try {
    & $alcPath $argumentList
    if ($LASTEXITCODE -ne 0) {
        Write-Host "##[error]Compilation failed with exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    } else {
        Write-Host "Compilation completed successfully."
    }
} catch {
    Write-Host "##[error]Compilation failed: $_"
    exit 1
}