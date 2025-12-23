#!/bin/bash

# --- CONFIGURATION ---
# No branch specified -> Clones the default branch automatically
KERNEL_REPO="https://github.com/aqbaloch6205/android_kernel_lge_sm8250-jhatpat.git"
CLANG_REPO="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86"
AK3_REPO="https://github.com/osm0sis/AnyKernel3"

# --- 1. SETUP WORKSPACE ---
echo "--- Cleaning and Setting Up ---"
mkdir -p build && cd build

echo "Cloning Kernel (Default Branch)..."
git clone --depth=1 $KERNEL_REPO kernel

echo "Cloning Clang..."
git clone --depth=1 $CLANG_REPO -b master clang

echo "Cloning AnyKernel3..."
git clone --depth=1 $AK3_REPO anykernel

# --- 2. SETUP TOOLCHAIN ---
# Automatically find the version folder (e.g., clang-r522817)
CLANG_VERSION=$(ls clang | grep clang-r | head -n 1)
export PATH="$(pwd)/clang/$CLANG_VERSION/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64

cd kernel

# --- 3. DETECT DEFCONFIG ---
# We prioritize kona-perf because it is the standard for SM8250
if [ -f "arch/arm64/configs/vendor/kona-perf_defconfig" ]; then
    DEFCONFIG="vendor/kona-perf_defconfig"
elif [ -f "arch/arm64/configs/kona-perf_defconfig" ]; then
    DEFCONFIG="kona-perf_defconfig"
else
    # Fallback: Just grab the first config that looks like a vendor perf config
    DEFCONFIG=$(find arch/arm64/configs -name "*perf_defconfig" | head -n 1 | xargs basename)
fi

echo "--- Building with Config: $DEFCONFIG ---"

# --- 4. COMPILE ---
make O=out $DEFCONFIG

# LLVM=1 handles all tools (ar, nm, objcopy) automatically
make -j$(nproc) O=out \
    CC=clang \
    LLVM=1 \
    LLVM_IAS=1 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    DTC=dtc

# --- 5. PACKAGE ---
if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
    echo "--- Build Success! Packaging... ---"
    cp out/arch/arm64/boot/Image.gz-dtb ../anykernel/
    cd ../anykernel
    
    # Disable device check so it flashes on any V60 variant
    sed -i 's/do.devicecheck=1/do.devicecheck=0/g' anykernel.sh
    
    zip -r9 ../../LGV60-Kernel.zip *
    echo "--- DONE: LGV60-Kernel.zip is ready ---"
else
    echo "!!! Build Failed: Image.gz-dtb not found !!!"
    exit 1
fi

