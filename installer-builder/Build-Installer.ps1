$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$PayloadExe = Join-Path $Root 'payload\KODARAStudioCode.exe'
$IssFile = Join-Path $Root 'KODARAStudioCode.iss'
$OutputDir = Join-Path $Root 'dist'

function Find-Iscc {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
        (Join-Path $env:LOCALAPPDATA 'Inno Setup 6\ISCC.exe')
    ) | Where-Object { $_ -and (Test-Path $_ -PathType Leaf) }
    if ($candidates) { return $candidates[0] }
    $cmd = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

try {
    if (!(Test-Path $PayloadExe -PathType Leaf)) {
        Write-Host 'ERROR: executable not found.' -ForegroundColor Red
        Write-Host "Copy your file to: $PayloadExe"
        Write-Host 'The filename must be exactly KODARAStudioCode.exe.'
        throw 'Missing payload executable.'
    }
    if ((Get-Item $PayloadExe).Length -lt 1000000) {
        Write-Host 'WARNING: the executable is smaller than 1 MB; check that it is the full application.' -ForegroundColor Yellow
    }
    if (!(Test-Path $IssFile -PathType Leaf)) { throw "Installer definition is missing: $IssFile" }
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

    $iscc = Find-Iscc
    if (!$iscc) {
        $winget = Get-Command 'winget.exe' -ErrorAction SilentlyContinue
        if ($winget) {
            Write-Host 'Inno Setup 6 was not found. It is needed to compile the installer.' -ForegroundColor Yellow
            $answer = Read-Host 'Install Inno Setup 6 through winget now? [Y/n]'
            if ([string]::IsNullOrWhiteSpace($answer) -or $answer -match '^(y|yes|д|да)$') {
                & $winget.Source install --id JRSoftware.InnoSetup --exact --accept-package-agreements --accept-source-agreements
                if ($LASTEXITCODE -ne 0) {
                    Write-Host 'winget could not install Inno Setup automatically.' -ForegroundColor Yellow
                }
                $iscc = Find-Iscc
            }
        }
    }
    if (!$iscc) {
        Write-Host 'Please install Inno Setup 6 from the official website:' -ForegroundColor Red
        Write-Host 'https://jrsoftware.org/isdl.php'
        throw 'Inno Setup compiler (ISCC.exe) not found.'
    }

    Write-Host "Compiler: $iscc"
    Write-Host "Input:    $PayloadExe"
    Write-Host 'Building the installer...'
    & $iscc "/O$OutputDir" $IssFile
    if ($LASTEXITCODE -ne 0) { throw "ISCC returned exit code $LASTEXITCODE" }

    $setup = Join-Path $OutputDir 'KODARAStudioCode_Setup.exe'
    if (!(Test-Path $setup -PathType Leaf)) { throw "Build completed without expected output: $setup" }
    Write-Host ''
    Write-Host 'SUCCESS: installer was created.' -ForegroundColor Green
    Write-Host "Installer: $setup"
    Write-Host ('Size:      {0:N1} MB' -f ((Get-Item $setup).Length / 1MB))
    Start-Process explorer.exe -ArgumentList "/select,`"$setup`""
} catch {
    Write-Host "`nBUILD ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
