#!/usr/bin/env bash
set -euo pipefail

# Variables
DEFCONFIG="vendor/rubik_defconfig"
TOOLCHAIN="kdrag0n/proton-clang"
AK3="aScordino-Dev/AnyKernel3"
TOOLCHAIN_DIR="/home/$USER/toolchain"
AK3_DIR="/home/$USER/AnyKernel3"
KDIR="$(pwd)"

# Options
if [[ ${1-} == "-c" || ${1-} == "--clean" ]]; then
    rm -rf out/
    echo "[!] Cleaned output directory."
fi

if [[ ${1-} == "-r" || ${1-} == "--regen" ]]; then
    cp out/.config arch/arm64/configs/${DEFCONFIG}
    echo -e "[!] Defconfig regenerated successfully."
    exit 0
fi

# Clone toolchain & AnyKernel3
if [ -d "$TOOLCHAIN_DIR" ]; then
    echo "[!] Toolchain directory exists. Skipping..."
else
    echo "[…] Cloning ${TOOLCHAIN}..."
    git clone https://github.com/"${TOOLCHAIN}" "${TOOLCHAIN_DIR}" -b ginkgo --depth=1 >/dev/null 2>&1
fi

if [ -d "$AK3_DIR" ]; then
    echo "[!] AnyKernel3 directory exists. Skipping..."
else
    echo "[…] Cloning ${AK3}"
    git clone https://github.com/"${AK3}" "${AK3_DIR}" --depth=1 >/dev/null 2>&1
fi

# Building
PATH="${TOOLCHAIN_DIR}/bin/:$PATH"
export KBUILD_COMPILER_STRING="${TOOLCHAIN_DIR}/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
export KBUILD_BUILD_USER="antonino"
export KBUILD_BUILD_HOST="scordino"
read -rp "[?] Insert kernel version: " VERSION
if [ -f out/arch/arm64/boot/Image ]; then rm -rf out/arch/arm64/boot/Image; fi

echo "[…] Starting compilation..."
make ${DEFCONFIG} >/dev/null 2>&1
make -j$(nproc --all) \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CC=clang

# Zipping
NAME="rubik"
CODENAME="ginkgo"
ZIP="$NAME"-"$CODENAME"-"$VERSION".zip

if [ -f out/arch/arm64/boot/Image ]; then
    cp "out/arch/arm64/boot/Image" "${AK3_DIR}"
    cd "${AK3_DIR}" || exit
    zip -rq9 "${KDIR}/../${ZIP}" * -x "README.md"  || { echo -e "[✘] Failed to create ZIP file."; exit 0; }
    cd "$KDIR" || exit
    echo -n [i] "Link: $(curl -s -T "${KDIR}/../$ZIP" oshi.at | head -n -2 | tail -n -1 | cut -d' ' -f1)"
        printf "\n"
    echo -n "[i] MD5: $(md5sum ../"${ZIP}" | cut -d' ' -f1)"
    echo "[✓] Kernel successfully zipped."
fi
