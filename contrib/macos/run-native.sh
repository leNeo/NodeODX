#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODEODX_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ODX_DIR="${ODX_DIR:-$(cd "${NODEODX_DIR}/.." && pwd)/ODX}"
NODEODX_PORT="${NODEODX_PORT:-3000}"
NODEODX_TOKEN="${NODEODX_TOKEN:-}"

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
    echo "This launcher requires an Apple Silicon Mac." >&2
    exit 1
fi

odx_python=""
for candidate in \
    "${ODX_DIR}/venv/bin/python3" \
    "${ODX_DIR}/venv/bin/python"
do
    if [[ -x "${candidate}" ]]; then
        odx_python="${candidate}"
        break
    fi
done

densify_point_cloud="${ODX_DIR}/SuperBuild/install/bin/OpenMVS/DensifyPointCloud"

if [[ \
    ! -x "${ODX_DIR}/run.sh" ||
    -z "${odx_python}" ||
    ! -x "${densify_point_cloud}" \
]]; then
    echo "The native ODX installation is incomplete in ${ODX_DIR}." >&2
    echo "Expected:" >&2
    echo "  ${ODX_DIR}/venv/bin/python3" >&2
    echo "  ${densify_point_cloud}" >&2
    echo "Run contrib/macos/install-native.sh first." >&2
    exit 1
fi

performance_cores="$(
    sysctl -n hw.perflevel0.physicalcpu 2>/dev/null ||
    sysctl -n hw.ncpu
)"

export OMP_NUM_THREADS="${OMP_NUM_THREADS:-${performance_cores}}"
export OPENBLAS_NUM_THREADS="${OPENBLAS_NUM_THREADS:-${performance_cores}}"
export VECLIB_MAXIMUM_THREADS="${VECLIB_MAXIMUM_THREADS:-${performance_cores}}"
export OMP_PROC_BIND="${OMP_PROC_BIND:-spread}"
export OMP_PLACES="${OMP_PLACES:-cores}"

export ODX_COREML_COMPUTE_UNITS="${ODX_COREML_COMPUTE_UNITS:-ALL}"
export ODX_COREML_CACHE_DIR="${ODX_COREML_CACHE_DIR:-${ODX_DIR}/storage/models/coreml-cache}"

mkdir -p \
    "${NODEODX_DIR}/data" \
    "${NODEODX_DIR}/tmp" \
    "${ODX_COREML_CACHE_DIR}"

cd "${NODEODX_DIR}"
arguments=(
    index.js
    --odx_path "${ODX_DIR}"
    --port "${NODEODX_PORT}"
    --parallel_queue_processing 1
    --max_concurrency "${performance_cores}"
)

if [[ -n "${NODEODX_TOKEN}" ]]; then
    arguments+=(--token "${NODEODX_TOKEN}")
fi

exec node "${arguments[@]}"
