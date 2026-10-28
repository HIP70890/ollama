#!/usr/bin/env bash
# Check that an Ollama image carries a usable ROCm backend for gfx906.
#
# Usage: gfx906/check-image.sh <image-ref> <ollama-version>
# Prints one "ok:", "SKIP:" or "FAIL:" line per check; exits 1 on any FAIL.
set -euo pipefail

if [ $# -ne 2 ]; then
    echo "usage: $0 <image-ref> <ollama-version>" >&2
    exit 2
fi
image=$1
version=${2#v}

docker run --rm -i --platform linux/amd64 --entrypoint sh "$image" -s "$version" <<'EOF'
dir=/usr/lib/ollama/rocm_v7_2
lib=$dir/libggml-hip.so
rc=0
ok() { echo "ok: $*"; }
fail() { echo "FAIL: $*"; rc=1; }

if [ -f "$lib" ]; then ok "libggml-hip.so present"; else fail "missing $lib"; fi

# discover/amd.go only keeps a GPU whose gfx target has a Tensile library here
if [ -f "$dir/rocblas/library/TensileLibrary_lazy_gfx906.dat" ]; then
    ok "rocBLAS Tensile library for gfx906"
else
    fail "no rocBLAS Tensile library for gfx906"
fi

if [ -f "$lib" ]; then
    if grep -aq 'amdgcn-amd-amdhsa--gfx906' "$lib"; then
        ok "gfx906 code objects in libggml-hip.so"
    elif grep -aq 'CCOB' "$lib"; then
        # compressed offload bundles hide the target IDs; checked at build time instead
        echo "SKIP: offload bundles are compressed, gfx906 code objects not visible"
    else
        fail "no gfx906 code objects in libggml-hip.so"
    fi

    missing=$(LD_LIBRARY_PATH=$dir:/usr/lib/ollama ldd "$lib" | grep 'not found' || true)
    if [ -z "$missing" ]; then ok "all libraries resolve"; else fail "unresolved libraries: $missing"; fi
fi

v=$(ollama --version 2>&1 || true)
case "$v" in
    *"version is $1"*) ok "ollama version $1" ;;
    *) fail "expected ollama version $1, got: $v" ;;
esac

exit $rc
EOF
