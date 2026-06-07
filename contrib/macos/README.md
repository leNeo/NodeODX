# Native NodeODX for Apple Silicon

This profile runs NodeODX and ODX directly on macOS instead of inside a
Linux container.

It provides:

- native ARM64 binaries compiled in Release mode with `-O3 -mcpu=native`;
- OpenMP and Accelerate framework thread tuning;
- ONNX Runtime CoreML acceleration for sky and background removal;
- a persistent CoreML model cache;
- automatic CPU fallback when CoreML cannot execute a model.

OpenMVS dense matching remains CPU-only. Its GPU implementation is CUDA-based
and does not currently have a Metal backend.

## Install

```sh
git clone --branch codex/apple-silicon-coreml \
  https://github.com/leNeo/NodeODX.git

cd NodeODX
contrib/macos/install-native.sh
```

The ODX native build is substantial and can take a while.

ODX is installed outside cloud-synchronized folders by default:

```text
~/Library/Application Support/NodeODX/ODX
```

Keeping Git repositories and native build trees outside iCloud avoids
truncated Git packfiles and partial compiler outputs. If an existing ODX
repository at this location is corrupt, the installer preserves it with a
`.corrupt.<timestamp>` suffix and creates a clean clone.

## Run

```sh
contrib/macos/run-native.sh
```

The default tuning uses the performance-core count, processes one
photogrammetry task at a time, and exposes NodeODX on port `3000`.

Optional environment variables:

```sh
NODEODX_PORT=3000
NODEODX_TOKEN=choose-a-long-random-token
NODEODX_NATIVE_ROOT="/path/to/native/runtime"
ODX_DIR=/path/to/ODX
ODX_COREML_COMPUTE_UNITS=ALL
ODX_COREML_PROFILE=0
```

`ODX_COREML_COMPUTE_UNITS` accepts `ALL`, `CPUAndGPU`,
`CPUAndNeuralEngine`, or `CPUOnly`.

## Connect WebODM

When WebODM runs in Docker Desktop, register the processing node using:

- hostname: `host.docker.internal`
- port: `3000`
- token: the value of `NODEODX_TOKEN`, when configured

Do not add `--gpus all`; that option is for NVIDIA CUDA on Linux.
