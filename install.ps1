$ErrorActionPreference = "Stop"

$Repo    = if ($env:SATCHAT_GITHUB_REPO) { $env:SATCHAT_GITHUB_REPO } else { "telepix-lab/satchat-cli-releases" }
$Version = if ($env:SATCHAT_VERSION) { $env:SATCHAT_VERSION } else { "latest" }
$PbsRel  = if ($env:SATCHAT_PBS_RELEASE) { $env:SATCHAT_PBS_RELEASE } else { "20250115" }
$PyVer   = if ($env:SATCHAT_PY_VERSION) { $env:SATCHAT_PY_VERSION } else { "3.12.8" }
$Home_   = if ($env:SATCHAT_HOME) { $env:SATCHAT_HOME } else { Join-Path $HOME ".satchat" }
$Runtime = Join-Path $Home_ "runtime"
$Venv    = Join-Path $Home_ "venv"
$BinDir  = if ($env:SATCHAT_BIN_DIR) { $env:SATCHAT_BIN_DIR } else { Join-Path $HOME ".local\bin" }

$arch = if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { throw "32-bit unsupported" }
$triple = "$arch-pc-windows-msvc"

New-Item -ItemType Directory -Force -Path $Runtime | Out-Null
$PyRoot = Join-Path $Runtime "cpython-$PyVer-$PbsRel"
$PyBin  = Join-Path $PyRoot "python\python.exe"
if (-not (Test-Path $PyBin)) {
    $pbsUrl = "https://github.com/astral-sh/python-build-standalone/releases/download/$PbsRel/cpython-$PyVer+$PbsRel-$triple-install_only.tar.gz"
    Write-Host "Downloading Python runtime: $pbsUrl"
    $tarFile = Join-Path $Runtime "python.tar.gz"
    Invoke-WebRequest -Uri $pbsUrl -OutFile $tarFile
    New-Item -ItemType Directory -Force -Path $PyRoot | Out-Null
    tar -xzf $tarFile -C "$PyRoot"
    Remove-Item -Force $tarFile
} else {
    Write-Host "Python runtime already cached: $PyRoot"
}

$ConstraintsUrl = $env:SATCHAT_CONSTRAINTS_URL
if ($env:SATCHAT_INSTALL_WHEEL_URL) {
    $wheelUrl = $env:SATCHAT_INSTALL_WHEEL_URL
} else {
    if ($Version -eq "latest") {
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
        $tag = $rel.tag_name
    } else { $tag = "v$Version" }
    if (-not $tag) {
        Write-Error "릴리스 태그를 확인할 수 없습니다. SATCHAT_VERSION 또는 SATCHAT_INSTALL_WHEEL_URL 를 지정하세요."
    }
    $ver = $tag.TrimStart("v")
    $base = "https://github.com/$Repo/releases/download/$tag"
    $wheelUrl = "$base/satchat_cli-$ver-py3-none-any.whl"
    if (-not $ConstraintsUrl) { $ConstraintsUrl = "$base/constraints-$ver.txt" }
}

& $PyBin -m venv $Venv

# 잠금(constraints): uv.lock 고정 버전으로 deps 핀(= CI 검증 버전, 재현성)
$pipArgs = @("install", "--quiet")
if ($ConstraintsUrl) {
    $cons = Join-Path $Venv "constraints.txt"
    try {
        Invoke-WebRequest -Uri $ConstraintsUrl -OutFile $cons
        $pipArgs += @("-c", $cons)
        Write-Host "Pinning deps to locked constraints: $ConstraintsUrl"
    } catch { Write-Host "경고: constraints 를 가져오지 못해 핀 없이 설치합니다." }
}
Write-Host "Installing SatCHAT: $wheelUrl"
& (Join-Path $Venv "Scripts\pip.exe") @pipArgs "$wheelUrl"

New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
Copy-Item -Force (Join-Path $Venv "Scripts\satchat.exe") (Join-Path $BinDir "satchat.exe")

Write-Host ""
Write-Host "SatCHAT 설치 완료. 실행: satchat"
Write-Host "PATH 에 없으면 $BinDir 를 PATH 에 추가하세요."
