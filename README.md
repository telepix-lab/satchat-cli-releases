# SatCHAT CLI

위성 영상 **검색 · 주문 · 분석 · 리포트**를 터미널에서 수행하는 에이전트형 CLI (`satchat`).

- **소스**: Bitbucket `telepix/satchat-cli-demo` (private)
- **릴리스**: 이 저장소 `telepix-lab/satchat-cli-releases` (public) — 릴리스가 공개이므로 **설치에 인증이 필요 없습니다.**

설치 스크립트는 독립 실행형 Python 런타임을 `~/.satchat/runtime` 에 내려받고 `~/.satchat/venv` 에 격리 설치한 뒤, `satchat` 실행 파일을 `~/.local/bin`(Windows: `%USERPROFILE%\.local\bin`)에 링크합니다. 시스템 Python 은 건드리지 않습니다.

## 설치

### macOS / Linux

```sh
curl -LsSf https://github.com/telepix-lab/satchat-cli-releases/releases/latest/download/install.sh | sh
```

### Windows (PowerShell)

```powershell
irm https://github.com/telepix-lab/satchat-cli-releases/releases/latest/download/install.ps1 | iex
```

`satchat` 명령을 찾지 못하면 설치 경로를 PATH 에 추가하세요.

- macOS / Linux: `export PATH="$HOME/.local/bin:$PATH"`
- Windows: `%USERPROFILE%\.local\bin` 를 PATH 에 추가

### 특정 버전 설치

기본은 최신 릴리스입니다. 버전을 고정하려면 `SATCHAT_VERSION` 을 지정하세요.

```sh
# macOS / Linux
curl -LsSf https://github.com/telepix-lab/satchat-cli-releases/releases/latest/download/install.sh | SATCHAT_VERSION=0.1.4 sh
```

```powershell
# Windows
$env:SATCHAT_VERSION = "0.1.4"; irm https://github.com/telepix-lab/satchat-cli-releases/releases/latest/download/install.ps1 | iex
```

## 사용법

```sh
# 1) 로그인 (Telepix SSO)
satchat auth login

# 2) 대화형 모드 — 대시보드 + 채팅 REPL
satchat

# 3) 한 줄 요청 (원샷)
satchat "여의도 AOI 만들고 Sentinel-2 영상 검색해줘"
```

자주 쓰는 명령:

| 명령 | 설명 |
|------|------|
| `satchat status` | 인증 · 설정 · 프로젝트 상태 확인 |
| `satchat doctor` | 로컬 환경 점검 (`--network` 로 네트워크 점검 포함) |
| `satchat auth login` · `auth status` | 로그인 · 인증 상태 |
| `satchat init` | 현재 디렉터리를 SatCHAT 프로젝트로 초기화 |
| `satchat aoi …` | 관심 영역(AOI) 생성 · 검증 · 임포트 |
| `satchat imagery …` | 위성 영상 검색 · 다운로드 |
| `satchat analysis …` | 지수 분석(NDVI 등) · 변화 탐지 · 시계열 |
| `satchat report …` | 분석 리포트 생성 |
| `satchat qgis …` | QGIS 프로젝트 동기화 · 열기 |

각 명령의 옵션은 `satchat <명령> --help` 로 확인하세요.

> SatCHAT 은 **현재 작업 디렉터리($PWD)** 를 프로젝트 루트로 사용하며, 생성물(AOI · 영상 · 분석 · 리포트)은 그 아래에 저장됩니다.

## 업데이트 / 제거

업데이트는 위 설치 명령을 다시 실행하면 최신 릴리스로 갱신됩니다.

제거:

```sh
# macOS / Linux
rm -rf ~/.satchat ~/.local/bin/satchat
```

```powershell
# Windows
Remove-Item -Recurse -Force "$HOME\.satchat", "$HOME\.local\bin\satchat.exe"
```
