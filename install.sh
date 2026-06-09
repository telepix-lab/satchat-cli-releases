#!/usr/bin/env sh
set -eu

SATCHAT_GITHUB_REPO="${SATCHAT_GITHUB_REPO:-telepix-lab/satchat-cli-releases}"
SATCHAT_VERSION="${SATCHAT_VERSION:-latest}"
PBS_RELEASE="${SATCHAT_PBS_RELEASE:-20250115}"   # python-build-standalone tag (pinned; bump to a current install_only release if it 404s)
PY_VERSION="${SATCHAT_PY_VERSION:-3.12.8}"
SATCHAT_HOME="${SATCHAT_HOME:-$HOME/.satchat}"
RUNTIME_DIR="$SATCHAT_HOME/runtime"
VENV_DIR="$SATCHAT_HOME/venv"
BIN_DIR="${SATCHAT_BIN_DIR:-$HOME/.local/bin}"

fetch() {  # fetch <url> <dest>
  if command -v curl >/dev/null 2>&1; then curl -LsSf "$1" -o "$2";
  elif command -v wget >/dev/null 2>&1; then wget -qO "$2" "$1";
  else echo "curl 또는 wget 이 필요합니다." >&2; exit 1; fi
}

os="$(uname -s)"; arch="$(uname -m)"
case "$os-$arch" in
  Darwin-arm64)   triple="aarch64-apple-darwin" ;;
  Darwin-x86_64)  triple="x86_64-apple-darwin" ;;
  Linux-x86_64)   triple="x86_64-unknown-linux-gnu" ;;
  Linux-aarch64)  triple="aarch64-unknown-linux-gnu" ;;
  *) echo "지원하지 않는 플랫폼: $os-$arch" >&2; exit 1 ;;
esac

mkdir -p "$RUNTIME_DIR"
PYROOT="$RUNTIME_DIR/cpython-${PY_VERSION}-${PBS_RELEASE}"
PYBIN="$PYROOT/python/bin/python3"
if [ ! -f "$PYBIN" ]; then
  pbs_url="https://github.com/astral-sh/python-build-standalone/releases/download/${PBS_RELEASE}/cpython-${PY_VERSION}+${PBS_RELEASE}-${triple}-install_only.tar.gz"
  echo "Downloading Python runtime: $pbs_url"
  fetch "$pbs_url" "$RUNTIME_DIR/python.tar.gz"
  mkdir -p "$PYROOT"
  tar -xzf "$RUNTIME_DIR/python.tar.gz" -C "$PYROOT"
  rm -f "$RUNTIME_DIR/python.tar.gz"
else
  echo "Python runtime already cached: $PYROOT"
fi

if [ "${SATCHAT_INSTALL_WHEEL_URL:-}" = "" ]; then
  if [ "$SATCHAT_VERSION" = "latest" ]; then
    api="https://api.github.com/repos/${SATCHAT_GITHUB_REPO}/releases/latest"
    tag="$(fetch "$api" /dev/stdout | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n1)"
  else
    tag="v${SATCHAT_VERSION}"
  fi
  if [ -z "$tag" ]; then
    echo "릴리스 태그를 확인할 수 없습니다. SATCHAT_VERSION 또는 SATCHAT_INSTALL_WHEEL_URL 를 지정하세요." >&2
    exit 1
  fi
  ver="${tag#v}"
  base="https://github.com/${SATCHAT_GITHUB_REPO}/releases/download/${tag}"
  wheel_url="${base}/satchat_cli-${ver}-py3-none-any.whl"
  : "${SATCHAT_CONSTRAINTS_URL:=${base}/constraints-${ver}.txt}"
else
  wheel_url="$SATCHAT_INSTALL_WHEEL_URL"
fi

"$PYBIN" -m venv "$VENV_DIR"

# 잠금(constraints) 적용 — uv.lock 고정 버전으로 deps 핀(= CI 검증 버전, 재현성). 없으면 일반 설치.
cons_args=""
if [ -n "${SATCHAT_CONSTRAINTS_URL:-}" ]; then
  CONS="$(mktemp)"
  if fetch "$SATCHAT_CONSTRAINTS_URL" "$CONS" 2>/dev/null && [ -s "$CONS" ]; then
    cons_args="-c $CONS"
    echo "Pinning deps to locked constraints: $SATCHAT_CONSTRAINTS_URL"
  else
    echo "경고: constraints 를 가져오지 못해 핀 없이 설치합니다." >&2
  fi
fi
echo "Installing SatCHAT: $wheel_url"
# shellcheck disable=SC2086
"$VENV_DIR/bin/pip" install --quiet $cons_args "$wheel_url"
if [ -n "$cons_args" ]; then rm -f "$CONS"; fi

mkdir -p "$BIN_DIR"
ln -sf "$VENV_DIR/bin/satchat" "$BIN_DIR/satchat"

echo ""
echo "SatCHAT 설치 완료. 실행: satchat"
echo "PATH 에 없으면: export PATH=\"$BIN_DIR:\$PATH\""
