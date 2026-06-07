#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODEODX_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ODX_DIR="${ODX_DIR:-$(cd "${NODEODX_DIR}/.." && pwd)/ODX}"
ODX_REPOSITORY="${ODX_REPOSITORY:-https://github.com/leNeo/ODX.git}"
ODX_BRANCH="${ODX_BRANCH:-codex/apple-silicon-coreml}"

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
    echo "This installer requires an Apple Silicon Mac." >&2
    exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required: https://brew.sh/" >&2
    exit 1
fi

performance_cores="$(
    sysctl -n hw.perflevel0.physicalcpu 2>/dev/null ||
    sysctl -n hw.ncpu
)"

brew install \
    boost \
    cgal \
    cmake \
    eigen \
    gdal \
    libomp \
    node \
    p7zip \
    python@3.12 \
    tbb

if [[ ! -d "${ODX_DIR}/.git" ]]; then
    git clone --branch "${ODX_BRANCH}" "${ODX_REPOSITORY}" "${ODX_DIR}"
fi

(
    cd "${ODX_DIR}"
    git fetch origin "${ODX_BRANCH}"
    git switch "${ODX_BRANCH}"
    git pull --ff-only origin "${ODX_BRANCH}"
    bash configure_macos.sh install "${performance_cores}"
)

odx_python="${ODX_DIR}/venv/bin/python3"
densify_point_cloud="${ODX_DIR}/SuperBuild/install/bin/OpenMVS/DensifyPointCloud"

if [[ ! -x "${odx_python}" || ! -x "${densify_point_cloud}" ]]; then
    echo "ODX installation did not produce all required native files." >&2
    echo "Missing or non-executable:" >&2
    [[ -x "${odx_python}" ]] || echo "  ${odx_python}" >&2
    [[ -x "${densify_point_cloud}" ]] || echo "  ${densify_point_cloud}" >&2
    exit 1
fi

(
    cd "${NODEODX_DIR}"
    npm install --omit=dev
    mkdir -p data tmp
)

cat <<EOF
NodeODX is ready.

Start it with:
  ODX_DIR="${ODX_DIR}" contrib/macos/run-native.sh

Register this processing node in WebODM:
  hostname: host.docker.internal
  port: 3000
EOF
