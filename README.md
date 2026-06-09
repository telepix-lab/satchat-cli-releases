<div align="center">

# 🛰 SatCHAT CLI

**위성 영상 검색 · 주문 · 분석 · 리포트를 터미널에서 끝내는 에이전트형 CLI**

자연어 한 줄이면 AOI 생성부터 STAC 검색, 다운로드, 분광 분석, QGIS 시각화, 보고서 작성까지 — `satchat`이 알아서 합니다.

[![release](https://img.shields.io/github/v/release/telepix-lab/satchat-cli-releases?label=release&color=2b8a3e)](https://github.com/telepix-lab/satchat-cli-releases/releases/latest)
[![python](https://img.shields.io/badge/python-3.12%2B-3776ab)](https://www.python.org/)
[![platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)](#설치)

</div>

---

SatCHAT CLI는 위성 영상 워크플로우를 **대화형 에이전트**로 묶은 터미널 제품입니다. 분석가가 GIS 도구·STAC API·밴드 수식을 일일이 다루지 않아도, 자연어 요청만으로 관심 영역(AOI) 설정 → 영상 검색·다운로드 → 분광지수/변화탐지/시계열 분석 → QGIS 레이어 동기화 → 보고서 작성까지 한 흐름으로 처리합니다.

- **소스**: Bitbucket `telepix/satchat-cli-demo` (private)
- **릴리스**: 이 저장소 `telepix-lab/satchat-cli-releases` (public) — 릴리스가 공개이므로 **설치에 인증이 필요 없습니다.**

> 설치 스크립트는 독립 실행형 Python 런타임을 `~/.satchat/runtime`에 내려받고 `~/.satchat/venv`에 격리 설치한 뒤, `satchat` 실행 파일을 `~/.local/bin`(Windows: `%USERPROFILE%\.local\bin`)에 링크합니다. **시스템 Python은 건드리지 않습니다.**

## 목차

- [주요 기능](#주요-기능)
- [설치](#설치)
- [빠른 시작](#빠른-시작)
- [자주 쓰는 명령](#자주-쓰는-명령)
- [환경변수](#환경변수)
- [업데이트 / 제거](#업데이트--제거)
- [문서 · 지원](#문서--지원)

## 주요 기능

- 🗣 **자연어 워크플로우** — `satchat "여의도 AOI 만들고 최근 Sentinel-2 검색해줘"` 한 줄로 멀티스텝 작업 수행
- 🔎 **STAC 영상 검색·다운로드** — AOI 커버리지 필터링, COG windowed-streaming, logical band subset, AOI crop 지원
- 📊 **분광 분석 스위트** — NDVI·NBR·NDBI·NDWI·UI·MVI 등 지수, 변화 탐지(dNBR 등), 시계열 분석
- 🗺 **QGIS 자동 연동** — 다운로드/분석 산출물을 `<project>.qgz`에 자동 등록·스타일링, 사용자 편집 보존
- 📝 **보고서 생성** — 템플릿 기반 Markdown 리포트 + executive summary
- 🧩 **확장 가능** — 프로젝트별 Skills(분석 규칙)와 Hooks(결정론적 정책)로 에이전트 행동을 커스터마이즈
- 🔐 **유연한 인증** — Telepix SSO / API key / 환경변수, Copernicus 별도 연동

## 설치

### macOS / Linux

```sh
curl -LsSf https://github.com/telepix-lab/satchat-cli-releases/releases/latest/download/install.sh | sh
```

### Windows (PowerShell)

```powershell
irm https://github.com/telepix-lab/satchat-cli-releases/releases/latest/download/install.ps1 | iex
```

설치 후 `satchat` 명령을 찾지 못하면 설치 경로를 PATH에 추가하세요.

- macOS / Linux: `export PATH="$HOME/.local/bin:$PATH"`
- Windows: `%USERPROFILE%\.local\bin`를 PATH에 추가

<details>
<summary><b>특정 버전 설치</b></summary>

기본은 최신 릴리스입니다. 버전을 고정하려면 `SATCHAT_VERSION`을 지정하세요.

```sh
# macOS / Linux
curl -LsSf https://github.com/telepix-lab/satchat-cli-releases/releases/latest/download/install.sh | SATCHAT_VERSION=0.1.5 sh
```

```powershell
# Windows
$env:SATCHAT_VERSION = "0.1.5"; irm https://github.com/telepix-lab/satchat-cli-releases/releases/latest/download/install.ps1 | iex
```

</details>

## 빠른 시작

```sh
# 1) 로그인 (Telepix SSO)
satchat auth login

# 2) 프로젝트 디렉터리로 이동 후 대화형 모드 — 대시보드 + 채팅 REPL
cd ~/my-project
satchat

# 3) 또는 한 줄 요청 (원샷)
satchat "여의도 AOI 만들고 최근 30일 Sentinel-2 영상 검색해줘"
```

자연어 요청 예시:

```text
@aoi/uiseong_fire.kml 참고해서 2025년 산불 피해 분석하고 요약 보고서까지 작성해줘
@aoi/obong-lake.geojson 기준으로 NDWI 수체 변화 시계열 분석해줘
2020년 3월과 2025년 3월을 비교해서 도시화 분석해줘
```

> SatCHAT은 **현재 작업 디렉터리(`$PWD`)** 를 프로젝트 루트로 사용하며, 생성물(AOI · 영상 · 분석 · 리포트)은 그 아래에 저장됩니다. 처음 들어가는 디렉터리에서는 trust 프롬프트가 한 번 뜹니다.

## 자주 쓰는 명령

| 명령 | 설명 |
|------|------|
| `satchat` | 대화형 모드 (대시보드 + 채팅 REPL) |
| `satchat "<요청>"` | 자연어 한 줄 요청 (원샷) |
| `satchat status` | 인증 · 설정 · 프로젝트 상태 확인 |
| `satchat doctor` | 로컬 환경 점검 (`--network`로 네트워크 점검 포함) |
| `satchat auth login` · `auth status` | 로그인 · 인증 상태 |
| `satchat init` | 현재 디렉터리를 SatCHAT 프로젝트로 초기화 |
| `satchat aoi …` | 관심 영역(AOI) 생성 · 검증 · 임포트 |
| `satchat imagery …` | 위성 영상 검색 · 다운로드 |
| `satchat analysis …` | 지수 분석(NDVI 등) · 변화 탐지 · 시계열 |
| `satchat report …` | 분석 리포트 생성 |
| `satchat qgis …` | QGIS 프로젝트 동기화 · 열기 |

각 명령의 옵션은 `satchat <명령> --help`로 확인하세요.

## 환경변수

SatCHAT을 제대로 쓰려면 모델 provider 키와 (필요 시) 데이터 제공자 인증을 준비하세요. 대화형 세션에서는 `/provider`로 키를 셋업할 수도 있습니다.

```sh
# 모델 provider — 최소 1개 (기본 모델 계열에 맞는 키)
export OPENAI_API_KEY="..."       # 또는 ANTHROPIC_API_KEY / GOOGLE_API_KEY

# Telepix 보호 명령 (또는 satchat auth login 으로 SSO)
export TELEPIX_API_KEY="..."

# Copernicus 다운로드/Process API (선택)
export COPERNICUS_CLIENT_ID="..."
export COPERNICUS_CLIENT_SECRET="..."
```

- Telepix 인증은 **환경변수 > 로컬 `~/.satchat/auth.json`** 순으로 우선합니다.
- Copernicus 인증은 Telepix 인증과 별개입니다.

## 업데이트 / 제거

업데이트는 위 설치 명령을 다시 실행하면 최신 릴리스로 갱신됩니다. 설치형은 `satchat update`(또는 시작 시 안내되는 self-update)로도 갱신할 수 있습니다.

```sh
satchat check-update   # 현재/최신 버전 확인
satchat update         # 최신 버전 설치
```

제거:

```sh
# macOS / Linux
rm -rf ~/.satchat ~/.local/bin/satchat
```

```powershell
# Windows
Remove-Item -Recurse -Force "$HOME\.satchat", "$HOME\.local\bin\satchat.exe"
```

## 문서 · 지원

- 전체 사용 가이드(설치 모드 · 대화형 명령 · Skills/Hooks · CLI 레퍼런스)는 소스 저장소의 README를 참고하세요.
- 문의 · 버그 리포트는 Telepix 내부 채널로 전달해 주세요.

---

<div align="center">

© Telepix — 사내 배포용 제품. 소스는 Bitbucket(private)에서 관리됩니다.

</div>
