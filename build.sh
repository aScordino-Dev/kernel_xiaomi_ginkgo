#!/usr/bin/env bash

# Variables
DEFCONFIG="vendor/ginkgo-perf_defconfig"
TOOLCHAIN="kdrag0n/proton-clang"
TOOLCHAIN_DIR="/home/$USER/toolchain"

# Options
if [[ ${1-} == "-c" || ${1-} == "--clean" ]]; then
    rm -rf out/
    echo "[!] Cleaned output directory."
fi

# Clone toolchain
if [ -d "$TOOLCHAIN_DIR" ]; then
    echo "[!] Toolchain directory exists. Skipping..."
else
    echo "[…] Cloning ${TOOLCHAIN}..."
    git clone https://github.com/"${TOOLCHAIN}" "${TOOLCHAIN_DIR}" --depth=1 >/dev/null 2>&1
fi

# Building
PATH="${TOOLCHAIN_DIR}/bin/:$PATH"
export KBUILD_COMPILER_STRING="${TOOLCHAIN_DIR}/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
export KBUILD_BUILD_USER="antonino"
export KBUILD_BUILD_HOST="scordino"

echo "[…] Starting compilation..."
make ${DEFCONFIG} >/dev/null 2>&1
make -j$(nproc --all) \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CC=clang
