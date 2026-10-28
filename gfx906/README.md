# Ollama with ROCm for gfx906

This fork builds the official Ollama image with a ROCm runner for gfx906
GPUs (Radeon VII, Instinct MI50/MI60). Current ROCm releases and the official
Ollama image no longer support gfx906. The runner here is built against the
gfx906 ROCm of [mixa3607/ML-gfx906](https://github.com/mixa3607/ML-gfx906).

## Branches

| Branch | Content |
|---|---|
| `main` | Upstream Ollama, unchanged |
| `feat/rocm-build-options` | `ROCM_AMDGPU_TARGETS` build argument for the ROCm runner in the upstream `Dockerfile`; meant as a pull request to Ollama |
| `gfx906/build` | This directory and `.github/workflows/gfx906-image.yml`, on top of `feat/rocm-build-options` |

Both feature branches are based on an Ollama release tag, not on `main`: the
runner replaces the one in `ollama/ollama:<version>` and must come from the
same sources.

## Images

`ghcr.io/hip70890/ollama-gfx906:<ollama-version>-<variant>-<commit>`

| Variant | ROCm |
|---|---|
| `rocm7.14` | ML-gfx906, `ROCM_IMAGE` in `versions.env` (pinned by digest) |
| `rocm7.2.1-upstream` | Official ROCm of the Ollama `Dockerfile`, built with `ROCM_AMDGPU_TARGETS=gfx906` |

The image labels `org.opencontainers.image.revision` and
`org.opencontainers.image.base.*` record the commit and the ROCm image.

How it is built:

1. `Dockerfile.gfx906` builds only the ROCm runner (`lib/ollama/rocm_v7_2`).
2. `Dockerfile.overlay` puts that runner into the official image of the same version.
3. `check-image.sh` checks the result:
   - the runner library is present;
   - the rocBLAS Tensile library for gfx906 is present (Ollama's GPU discovery requires it);
   - the runner contains gfx906 code objects;
   - all shared libraries resolve;
   - the Ollama version matches.

## Updating to a new Ollama release

1. Sync `main` with upstream and fetch the tags.
2. Rebase `feat/rocm-build-options` onto the new release tag.
3. Rebase `gfx906/build` onto `feat/rocm-build-options`.
4. Set `OLLAMA_VERSION` in `versions.env`.
5. Push. The workflow builds and pushes the `rocm7.14` variant. Other variants run via *Run workflow*.
