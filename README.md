# 🛰 SatCHAT CLI

**전문가 검증을 거친 분석 슬라이스를 확보부터 보고서까지 한 번에 돌리는 위성영상 분석 하네스**

[![release](https://img.shields.io/github/v/release/telepix-lab/satchat-cli-releases?label=release&color=2b8a3e)](https://github.com/telepix-lab/satchat-cli-releases/releases/latest) [![python](https://img.shields.io/badge/python-3.12%2B-3776ab)](https://www.python.org/) [![platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)](#markdown-header-설치) [![packaging](https://img.shields.io/badge/packaging-uv%20%2F%20hatchling-blueviolet)](https://docs.astral.sh/uv/)

---

SatCHAT은 위성영상 분석을 **슬라이스** 단위로 돌립니다. 슬라이스는 영상 확보 → 전처리(구름·수역 마스크, 반사율 환산) → 분석 → 해석 → 보고서까지 이어지는 한 묶음이고, 단계마다 품질 기준이 코드에 고정돼 있습니다. 핵심은 속도입니다. 사건이 나면 자연어 한 줄로 첫 보고서까지 갑니다.

- **지금 되는 슬라이스**: 산불 신속분석(dNBR 피해 심각도, 활성 화재, 핫스팟, 보고서). 다음은 홍수입니다.
- **하지 않는 일**: 영상 주문·구매. 사용자 본인의 무료 계정(Copernicus CDSE, USGS, NASA FIRMS)과, 실제로 접근을 시험한 공공기관 오픈데이터로 받을 수 있는 데이터만 씁니다. 산불 슬라이스는 CDSE 자격 하나로도 끝까지 돕니다.
- **두 가지 진입로**: 대화형 에이전트(`satchat`)와 명시적 CLI(`satchat analysis dnbr ...`). 두 경로는 같은 오케스트레이션을 거치므로 입력이 같으면 같은 장면을 고르고 같은 품질 게이트를 통과합니다.

소스는 Bitbucket `telepix/satchat-cli-demo`(private, 이 저장소), 릴리스는 GitHub `telepix-lab/satchat-cli-releases`(public)에 게시합니다.

## 설치

배포 채널은 셸 설치기 하나입니다. 릴리스 저장소가 공개라 설치에 인증이 필요 없습니다.

```bash
# macOS / Linux
curl -LsSf https://raw.githubusercontent.com/telepix-lab/satchat-cli-releases/main/install.sh | sh
```

```powershell
# Windows (PowerShell) — 아직 end-to-end 검증 전입니다(docs/backlog.md B-29)
irm https://raw.githubusercontent.com/telepix-lab/satchat-cli-releases/main/install.ps1 | iex
```

설치기는 독립 실행형 Python 런타임을 `~/.satchat/runtime`에, 패키지를 `~/.satchat/venv`에 격리 설치하고 `satchat`을 `~/.local/bin`에 링크합니다(시스템 Python은 건드리지 않습니다). `satchat`을 찾지 못하면 `export PATH="$HOME/.local/bin:$PATH"`를 추가하세요.

- **버전 고정**: `curl ... | SATCHAT_VERSION=0.2.0 sh` (Windows: `$env:SATCHAT_VERSION = "0.2.0"` 뒤 설치 명령)
- **업데이트**: `satchat update`(`--force`는 강제 재설치), 확인만 할 때는 `satchat check-update`. 시작할 때 하루 한 번 새 버전을 알려주며 `SATCHAT_NO_UPDATE_CHECK=1`로 끕니다.
- **제거**: `rm -rf ~/.satchat ~/.local/bin/satchat`. `~/.satchat`에는 인증·설정·trust 목록도 들어 있으니, 설정을 남기려면 `~/.satchat/runtime`, `~/.satchat/venv`, 실행 파일만 지웁니다.

## 처음 설정 (자격 정보)

| 자격 | 필요한 곳 | 설정 방법 |
|------|-----------|-----------|
| LLM 공급자 키 (OpenAI·Anthropic·Google 중 하나) | 에이전트(대화형 앱, 한 줄 요청) | 앱에서 `/provider`, 또는 `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / `GOOGLE_API_KEY`. 우선순위는 프로젝트 > 환경변수 > `~/.satchat` |
| Telepix 로그인 | 대화형 앱 시작 관문 | 첫 실행 때 브라우저 SSO 또는 API 키 중 선택. 미리 하려면 `satchat auth login`(헤드리스는 `--no-browser`), 또는 `TELEPIX_API_KEY` / `TELEPIX_ACCESS_TOKEN`(환경변수가 `~/.satchat/auth.json`보다 우선) |
| Copernicus CDSE OAuth 클라이언트 | Sentinel-1 SAR, Copernicus 다운로드 | `/config → Copernicus keys`, 또는 `COPERNICUS_CLIENT_ID` / `COPERNICUS_CLIENT_SECRET` |
| NASA FIRMS MAP_KEY | 활성 화재 포인트(북미 AOI는 자동, 그 외는 요청할 때) | `/config → FIRMS key`, 또는 `FIRMS_MAP_KEY`([무료 발급](https://firms.modaps.eosdis.nasa.gov/api/)) |
| USGS ERS 사용자명 + M2M 앱 토큰 | Landsat 8/9 다운로드 | `/config → USGS M2M (Landsat)`, 또는 `USGS_M2M_USERNAME` / `USGS_M2M_TOKEN`. ERS 프로필에서 M2M 접근을 신청(승인 영업일 1–2일)한 뒤 "Create Application Token"으로 발급 |

검색은 모두 자격 없이 됩니다: Sentinel-2는 Earth Search, Sentinel-1과 Sentinel-2 대체 경로는 CDSE 카탈로그, Landsat은 USGS LandsatLook. 참조 레이어(DEM 등)도 공개 저장소에서 받습니다. 기본 모델과 추론 강도는 앱 안에서 `/model`, `/effort`로 바꿉니다. 자격 상태는 `satchat auth status`, 공개 소스 접근은 `satchat doctor --network`로 확인합니다.

## 산불 신속분석 퀵스타트

### 1. 프로젝트 열기

SatCHAT은 현재 디렉터리(`$PWD`)를 프로젝트 루트로 씁니다. 모든 산출물이 그 아래에 쌓입니다.

```bash
mkdir ~/fire-uiseong && cd ~/fire-uiseong
satchat
```

처음 들어가는 디렉터리면 trust 확인을, 로그인 전이면 Telepix 로그인을 거친 뒤 대시보드가 열립니다. 앱 안에서 `/init`(또는 셸에서 `satchat init`)으로 프로젝트 구조를 만듭니다.

### 2. 채팅으로 요청

```text
의성군 일대(128.60,36.32,128.78,36.46) AOI 만들고 2025년 3월 산불 피해를 분석해서 보고서까지 작성해줘
@aoi/uiseong_fire.kml 참고해서 산불 전후 dNBR 피해 심각도 분석해줘
```

`@파일`로 프로젝트 안의 AOI(geojson, json, kml, shp)나 문서를 바로 참조할 수 있습니다. 에이전트는 기본 스킬 `wildfire-analysis`의 순서를 따릅니다.

1. AOI를 정하고 **확보 진단**으로 센서·소스별 사용 가능한 관측일, 기간 내 공백, 산불 전·후 최근접 장면, 비용(용량·CDSE 처리 단위)을 먼저 봅니다. Sentinel-2에 맑은 쌍이 없으면 Landsat을 대안으로 계획합니다.
2. 장면마다 구름 게이트로 판정하고(필요하면 대체 장면으로 교체) dNBR, USGS 7등급 분류, QGIS에서 경계를 끌어 조정할 수 있는 심각도 레이어를 만듭니다. 수역은 제외합니다.
3. AOI가 북미면 FIRMS 활성 화재 포인트를 받아 옵니다.
4. 사후 장면으로 TAI 핫스팟(고온 후보)을 탐지합니다.
5. burn-severity 보고서(USGS dNBR 기준표, 등급별 분포, QC 블록)를 씁니다.
6. 산출물이 `<project>.qgz`에 자동 등록됩니다.

보고서 저장, FIRMS 조회, 여러 장면을 받기 전 견적(장면 수·용량·예상 시간) 같은 단계는 실행 전에 승인을 묻습니다.

### 3. 같은 흐름을 CLI로

```bash
satchat init
satchat aoi create --name fire-aoi --bbox 128.60,36.32,128.78,36.46
satchat imagery diagnose --aoi fire-aoi --from 2025-03-01 --to 2025-04-30 \
    --event-date 2025-03-22 --event-end 2025-03-28 --slice wildfire --task-name fire
# 진단이 권하는 전·후 장면으로 (Earth Search 경로)
satchat analysis dnbr --filter fire-sentinel-2-stac --profile burn-severity \
    --before-scene <PRE_SCENE_ID> --after-scene <POST_SCENE_ID>
satchat report generate --template burn-severity --title "산불 피해 분석"
```

CDSE만으로 돌릴 때(Earth Search가 안 될 때 등)는 하루 단위로 렌더해 확보 산출물(메타데이터 JSON)을 바로 분석합니다.

```bash
satchat imagery copernicus download --aoi fire-aoi --from 2025-03-14 --to 2025-03-14 --bands B03,B04,B08,B12
satchat imagery copernicus download --aoi fire-aoi --from 2025-03-31 --to 2025-03-31 --bands B03,B04,B08,B12
satchat analysis dnbr --profile burn-severity \
    --before-acquisition imageries/fire-aoi/<사전>.json --after-acquisition imageries/fire-aoi/<사후>.json
```

- `--profile burn-severity`를 줘야 수역 마스크가 켜집니다(기본 `full`은 수역을 빼지 않습니다).
- 진단은 검색 번들(`search_filters/results/<task>/`)을 남기므로 그 필터 이름으로 바로 분석할 수 있습니다. 필터를 직접 만들 때는 `imagery filter create --from/--to`로 기간을 지정합니다.
- Copernicus 렌더는 Sentinel-2에 SCL을 자동으로 붙여 구름 게이트가 돌고, 같은 요청은 로컬 캐시에서 처리 단위 없이 다시 씁니다.
- CLI 경로는 dNBR과 보고서까지입니다. 활성 화재는 `satchat imagery firms fetch fire-aoi`로 따로 받고, 핫스팟은 채팅 경로에서 돌립니다.

## 할 수 있는 일

- **영역 정하기**: bbox, 중심점+크기, 파일(geojson·json·kml·shp)로 AOI를 만들고 검증합니다.
- **확보 진단** (`satchat imagery diagnose`): AOI·기간·사건일을 주면 다운로드 없이 센서·소스별로 사용 가능한 관측일(AOI 80% 이상, 광학은 구름 게이트 기준 이내), 가장 긴 공백, 사건 전·후 최근접 관측(S1은 같은 궤도), 비용을 보여 주고 그대로 따라 할 확보 계획을 냅니다.
- **영상 확보**
  - Sentinel-2 L2A: Earth Search COG를 창 단위로 스트리밍해 AOI만 잘라 받습니다(밴드는 병렬). 대체 경로는 CDSE Process API 하루 렌더입니다. AOI 커버리지 100% 우선, 80% 미만 제외.
  - Sentinel-1 GRD: CDSE 카탈로그에서 궤도 방향·상대 궤도·편파로 찾고, Process API에서 지형보정 gamma0(FLOAT32)로 하루·한 패스씩 받습니다(`--orbit-direction`). 중위도는 VV·VH, 극지는 HH·HV. 후방산란만 지원하고 InSAR·지표 변위는 범위 밖입니다.
  - Landsat 8/9 C2 L2: USGS LandsatLook에서 찾고 본인 M2M 토큰으로 필요한 밴드 파일만 받습니다(통파일 후 AOI 자르기). 결과에는 전문가 확인 전까지 "미검증"이 붙습니다.
  - 참조 레이어(`satchat imagery reference fetch`): Copernicus DEM, HAND, JRC 지표수, ESA WorldCover를 AOI 창만 받아 영구 캐시합니다.
  - Copernicus 렌더는 예상 처리 단위(무료 월 10,000)를 보여 주고, 같은 요청은 캐시에서 다시 씁니다.
  - 센서를 말하지 않으면 요청을 보고 광학/SAR을 고르고, 애매하면(예: 홍수) 한 번 묻습니다.
- **산불 분석**: dNBR 변화탐지와 USGS 심각도 등급, 조정 가능한 Burn Severity Class 레이어, Sentinel-2 TAI 핫스팟, Landsat 열적외 핫스팟, NASA FIRMS 활성 화재.
- **그 밖의 분석**: 분광지수(NDVI·NDWI·NDBI·NBR·MVI 등), 변화탐지 프로필(식생·수체·도시화), 시계열. 식생·도시화·맹그로브 분석은 아직 전문가 검증 전입니다(아래 품질 기준 참고).
- **보고서**: 템플릿 기반 Markdown 보고서와 요약. 언어는 사용자 요청을 따릅니다.
- **시각화**: 산출물은 `<project>.qgz`에 파일명 규칙에 맞는 스타일로 자동 등록되고, QGIS에서 사용자가 고친 그룹·스타일은 덮어쓰지 않습니다. PNG가 필요하면 요청할 때만 만듭니다(`satchat imagery quicklook <tif>`).

## 품질 기준 (QC)

산불 슬라이스의 기준은 코드에 고정돼 있고, 보고서가 그 적용 결과를 그대로 보여 줍니다.

- **구름 게이트**: 변화탐지는 장면마다 품질 밴드(Sentinel-2 SCL, Landsat QA_PIXEL — 같은 기준)를 먼저 받아 구름을 판정한 뒤에만 분석 밴드를 받습니다. 유효 화소가 70% 미만이면 차단, 90% 미만이면 경고합니다. 장면은 최대 3번 교체하고, 모두 실패하면 `ANALYSIS_CLOUD_COVER_EXCEEDED`로 시도 내역과 대안을 알려 줍니다.
- **수역 마스크**: burn severity는 전·후 NDWI로 수역을 제외하고, 등급 비율은 유효 육지 면적 기준으로 계산합니다.
- **반사율 환산**: 지수는 원시 DN이 아니라 반사율로 계산합니다(STAC scale/offset, Copernicus 렌더 0.0001, Landsat C2 L2 제품 정의값). 보정값이 없는 예전 검색 번들은 다시 검색해야 합니다.
- **완화는 사용자만**: 기준 완화는 사용자 요청을 인용해야 허용되고, 쓰인 완화는 보고서에 남습니다. `analysis.cloud_gate`로 게이트를 끄면 끈 사실이 QC 블록에 표시됩니다.
- **QC 블록**: 보고서와 요약에 장면별 구름 유효율, 면적 분모, 적용 기준, 완화 여부, 입력 추적이 실립니다.
- **미검증 표시**: 식생·도시화·맹그로브 보고서와 Landsat 경로 결과에는 "미검증" 안내가 붙습니다. 에이전트가 내장 툴 밖에서 직접 짠 코드(자유 모드)로 낸 결과도 "미검증"으로 표시합니다.

## 프로젝트 구조

`satchat init`이 만드는 구조입니다(정본: `src/satchat/project/workspace.py::PROJECT_DIRS`).

```text
<project>/
├── SATCHAT.md               # 자동 생성 — 손으로 고치지 말 것
├── <project>.qgz            # 자동 관리되는 QGIS 프로젝트
├── aoi/
├── search_filters/          # 검색 필터와 검색 결과 번들
├── imageries/<task>/
├── references/  docs/       # 참고 자료
├── analysis/
│   ├── spectral_analysis/  change_detection/  timeseries_analysis/
│   ├── hotspot/  active_fires/
│   └── reports/<task>/
└── .satchat/                # 프로젝트 상태: memories/, skills/, hooks/, qgis/
```

프로젝트별 규칙이나 고객 요구사항은 `SATCHAT.md`가 아니라 `.satchat/memories/AGENTS.md`나 스킬에 적습니다.

## 확장 (스킬 · 훅 · MCP)

확장은 두 층입니다. 내장 툴은 전문가 기준 검증을 거쳐 개발자만 추가하고, 사용자는 내장 툴을 엮는 **스킬**까지 확장합니다([ADR 0002](docs/adr/0002-two-tier-extension.md)).

- **스킬**: `.satchat/skills/<이름>/`(프로젝트) 또는 `~/.satchat/skills/`(전역)에 둡니다. `SKILL.md` 지침형과 `skill.json` Python 플러그인형이 있습니다. 앱에서 `/skill-create <요청>`으로 초안을 만들고 `/skill-doctor`로 점검합니다.
  - 기본 스킬 `wildfire-analysis`는 대화형 세션을 처음 열 때 `~/.satchat/skills/`로 복사됩니다(사용자가 고친 사본은 덮어쓰지 않음). `satchat skill run wildfire-analysis`는 이미 수행된 분석으로 burn-severity 보고서를 결정적으로 다시 만듭니다.
  - 설계: [Python Skills Plugin](docs/skills-python-plugin.md) · [skill.json 스키마](docs/skill.schema.json)
- **훅**: 툴 호출 전후(`PreToolUse`/`PostToolUse`)와 세션 시작·종료에 스크립트나 Python 함수를 실행해 정책을 코드로 강제합니다(예: AOI 면적 한도 초과 시 다운로드 차단). `.satchat/hooks.json`과 `~/.satchat/hooks.json`이 합쳐지고, 앱에서 `/hook-create <요청>`으로 초안을 만듭니다. 서브에이전트의 툴 호출은 훅을 거치지 않습니다. 예시는 `docs/hooks-examples/`, 상세는 [Hooks 가이드](docs/hooks-guide.md).
- **MCP**: `satchat mcp add`로 stdio MCP 서버를 `~/.satchat/mcp.json`에 등록하면 그 도구가 `mcp__<서버>__<도구>`로 에이전트에 붙습니다. 기본으로 실행 전 승인을 받고, 읽기 전용 도구만 `--auto-approve`로 승인을 면제할 수 있습니다. MCP 결과는 분석 산출물의 정식 경로가 아닙니다. 열려 있는 QGIS 세션을 제어하는 QGIS MCP는 [docs/qgis-mcp-integration.md](docs/qgis-mcp-integration.md) 참고.
- **서브에이전트**: `satchat agents`로 관리합니다. 사용자 서브에이전트는 MCP 도구를 쓸 수 없습니다(승인 우회 방지).

## 문제 해결

- `satchat status` — 프로젝트 초기화, 인증, AOI·영상·분석 개수
- `satchat doctor` — 설정·인증·디렉터리·의존성·MCP·훅을 로컬에서 점검합니다. 네트워크 도달성은 `--network`로 켜며, 실패는 오류가 아니라 경고입니다.
- 한 줄 요청(`satchat "<요청>"`)이 승인 단계에서 멈추면 `satchat`을 열고 `/pending` → `/resume`으로 이어 갑니다.
- 오류 메시지 앞의 코드(`AUTH_*`, `CONFIG_*`, `AOI_*`, `SEARCH_*`, `DOWNLOAD_*`, `ANALYSIS_*`)가 어느 단계에서 막혔는지 알려 줍니다.

## 명령 전체 목록

명령과 옵션은 자주 바뀌므로 여기 옮겨 적지 않습니다. 실행 중인 버전에서 직접 확인하세요.

- 셸: `satchat --help`, `satchat <명령> --help`
- 앱 안: `/help`(슬래시 명령), `/keys`(단축키)
- 버전별 변경 사항: [CHANGELOG.md](CHANGELOG.md)

## 개발자 문서

모든 명령은 `uv` 아래에서 실행합니다(`pip`/`python` 직접 호출 금지).

```bash
uv sync --group dev                  # 개발 의존성 (CI와 동일)
uv run pytest                        # 전체 테스트 — 완료 전 반드시 통과
uv tool install --editable .         # 로컬 전역 설치 (의존성 변경 뒤 --reinstall)
```

- 코드 구조·규칙·테스트 정책: [CLAUDE.md](CLAUDE.md)
- 설계·운영 문서 인덱스: [docs/README.md](docs/README.md) — 남은 작업은 [docs/backlog.md](docs/backlog.md)
- CI는 Bitbucket Pipelines(`bitbucket-pipelines.yml`)입니다. `v*` 태그는 wheel과 잠금 constraints를 공개 GitHub 릴리스에 게시하고, 설치 스크립트와 공개 README(`release/README.md`)는 릴리스 저장소 루트에 동기화됩니다.

---

© Telepix
