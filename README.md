<div align="center">

# 🛰 SatCHAT CLI

**전문가 검증을 거친 분석 슬라이스를 확보부터 보고서까지 한 번에 돌리는 위성영상 분석 하네스**

[![release](https://img.shields.io/github/v/release/telepix-lab/satchat-cli-releases?label=release&color=2b8a3e)](https://github.com/telepix-lab/satchat-cli-releases/releases/latest)
[![python](https://img.shields.io/badge/python-3.12%2B-3776ab)](https://www.python.org/)
[![platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)](#설치)

</div>

---

SatCHAT은 영상 확보 → 전처리(구름·수역 마스크, 반사율 환산) → 분석 → 해석 → 보고서를 한 번에 돌리는 터미널 앱입니다. 단계마다 품질 기준이 고정돼 있어, 사건이 나면 자연어 한 줄로 근거가 붙은 첫 보고서까지 빠르게 갑니다.

- **지금 되는 슬라이스**: 산불 신속분석(dNBR 피해 심각도, 활성 화재, 핫스팟, 보고서). 다음은 홍수입니다.
- **하지 않는 일**: 영상 주문·구매. 사용자 본인의 무료 계정(Copernicus CDSE, USGS, NASA FIRMS)과 실제로 접근을 시험한 공공 오픈데이터로 받을 수 있는 데이터만 씁니다. 산불 분석은 CDSE 자격 하나로도 끝까지 돕니다.

## 설치

```sh
# macOS / Linux
curl -LsSf https://raw.githubusercontent.com/telepix-lab/satchat-cli-releases/main/install.sh | sh
```

```powershell
# Windows (PowerShell) — 아직 검증 중입니다
irm https://raw.githubusercontent.com/telepix-lab/satchat-cli-releases/main/install.ps1 | iex
```

설치 스크립트는 독립 실행형 Python 런타임과 격리된 가상환경을 `~/.satchat/`에 만들고 `satchat`을 `~/.local/bin`(Windows: `%USERPROFILE%\.local\bin`)에 링크합니다. 시스템 Python은 건드리지 않습니다. `satchat`을 찾지 못하면 그 경로를 PATH에 추가하세요.

특정 버전을 설치하려면 `SATCHAT_VERSION`을 지정합니다.

```sh
curl -LsSf https://raw.githubusercontent.com/telepix-lab/satchat-cli-releases/main/install.sh | SATCHAT_VERSION=0.2.0 sh
```

```powershell
$env:SATCHAT_VERSION = "0.2.0"; irm https://raw.githubusercontent.com/telepix-lab/satchat-cli-releases/main/install.ps1 | iex
```

## 처음 설정

| 자격 | 필요한 곳 | 설정 방법 |
|------|-----------|-----------|
| LLM 공급자 키 (OpenAI·Anthropic·Google 중 하나) | 에이전트 | 앱에서 `/provider`, 또는 `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / `GOOGLE_API_KEY` |
| Telepix 로그인 | 대화형 앱 시작 | 첫 실행 때 브라우저 SSO 또는 API 키 선택. 미리 하려면 `satchat auth login` |
| Copernicus CDSE OAuth 클라이언트 | Sentinel-1 SAR, Copernicus 다운로드 | `/config → Copernicus keys`, 또는 `COPERNICUS_CLIENT_ID` / `COPERNICUS_CLIENT_SECRET` |
| NASA FIRMS MAP_KEY | 활성 화재(북미 AOI는 자동) | `/config → FIRMS key`, 또는 `FIRMS_MAP_KEY`([무료 발급](https://firms.modaps.eosdis.nasa.gov/api/)) |
| USGS ERS 사용자명 + M2M 앱 토큰 | Landsat 8/9 다운로드 | `/config → USGS M2M (Landsat)`, 또는 `USGS_M2M_USERNAME` / `USGS_M2M_TOKEN`. ERS 프로필 → Access Request에서 M2M(MACHINE) 접근 승인(영업일 1–2일) 후 앱 토큰 발급 |

검색은 자격 없이 됩니다(Sentinel-2 Earth Search, Sentinel-1·대체 Sentinel-2 CDSE 카탈로그, Landsat USGS LandsatLook). 자격 상태는 `satchat auth status`, 공개 소스 접근은 `satchat doctor --network`로 확인합니다.

## 산불 신속분석 시작하기

SatCHAT은 현재 디렉터리를 프로젝트로 쓰고, 모든 산출물을 그 아래에 저장합니다.

```sh
mkdir ~/fire-uiseong && cd ~/fire-uiseong
satchat        # 처음이면 trust 확인과 로그인 뒤 대시보드가 열립니다
```

앱 안에서 `/init`으로 프로젝트를 만든 뒤 자연어로 요청합니다.

```text
의성군 일대(128.60,36.32,128.78,36.46) AOI 만들고 2025년 3월 산불 피해를 분석해서 보고서까지 작성해줘
@aoi/uiseong_fire.kml 참고해서 산불 전후 dNBR 피해 심각도 분석해줘
```

에이전트는 먼저 확보 진단으로 사용 가능한 관측일·사건 전후 최근접 장면·비용을 확인하고, 전·후 장면(Sentinel-2, 맑은 쌍이 없으면 Landsat)을 골라 구름 게이트를 통과한 장면으로 dNBR과 USGS 심각도 등급을 계산하고, 사후 장면의 핫스팟과 (북미 AOI면) FIRMS 활성 화재를 더해 burn-severity 보고서를 씁니다. 결과는 프로젝트의 QGIS 파일(`<project>.qgz`)에 자동으로 등록됩니다. 보고서 저장처럼 되돌리기 어려운 단계는 실행 전에 승인을 묻습니다.

같은 흐름을 명령으로도 돌릴 수 있습니다.

```sh
satchat init
satchat aoi create --name fire-aoi --bbox 128.60,36.32,128.78,36.46
satchat imagery diagnose --aoi fire-aoi --from 2025-03-01 --to 2025-04-30 \
    --event-date 2025-03-22 --event-end 2025-03-28 --slice wildfire --task-name fire
satchat analysis dnbr --filter fire-sentinel-2-stac --profile burn-severity \
    --before-scene <PRE_SCENE_ID> --after-scene <POST_SCENE_ID>
satchat report generate --template burn-severity --title "산불 피해 분석"
```

## 품질 기준

- 구름 게이트: Sentinel-2 SCL, Landsat QA_PIXEL로 유효 화소 70% 미만 장면은 차단, 90% 미만은 경고하고 대체 장면을 최대 3번 시도합니다.
- burn severity는 수역을 빼고 유효 육지 면적 기준으로 등급 비율을 냅니다.
- 지수는 반사율로 환산한 값으로 계산합니다.
- 보고서의 QC 블록에 장면별 구름 유효율, 면적 분모, 적용 기준, 완화 여부가 실립니다. 기준 완화는 사용자가 요청해야만 하고 보고서에 남습니다.
- 식생·도시화·맹그로브 보고서, Landsat 경로 결과, 에이전트가 직접 짠 코드의 결과는 "미검증"으로 표시됩니다.

## 도움말

- 명령 목록: `satchat --help`, `satchat <명령> --help`, 앱 안에서 `/help`
- 상태 점검: `satchat status`, `satchat doctor`(`--network`로 네트워크 점검 포함)
- 확장: 반복 작업은 스킬(`/skill-create`), 강제 정책은 훅(`/hook-create`), 외부 도구는 MCP(`satchat mcp add`, 기본 승인 필요)로 붙입니다.
- 변경 사항: [Releases](https://github.com/telepix-lab/satchat-cli-releases/releases)

## 업데이트 / 제거

```sh
satchat check-update   # 현재/최신 버전 확인
satchat update         # 새 버전이 있으면 설치 (--force: 강제 재설치)
```

설치 명령을 다시 실행해도 최신 릴리스로 갱신됩니다. 시작할 때의 업데이트 알림은 `SATCHAT_NO_UPDATE_CHECK=1`로 끕니다.

```sh
# 제거 (macOS / Linux) — ~/.satchat 에는 인증·설정도 들어 있습니다
rm -rf ~/.satchat ~/.local/bin/satchat
```

```powershell
# 제거 (Windows)
Remove-Item -Recurse -Force "$HOME\.satchat", "$HOME\.local\bin\satchat.exe"
```

---

<div align="center">

© Telepix

</div>
