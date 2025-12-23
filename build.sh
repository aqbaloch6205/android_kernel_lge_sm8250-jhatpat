#!/bin/bash

# --- CONFIG ---
KERNEL_URL="https://github.com/aqbaloch6205/android_kernel_lge_sm8250-jhatpat.git"
# No branch specified = Clones default branch automatically
AK3_URL="https://github.com/osm0sis/AnyKernel3"
CLANG_URL="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86"
DEFCONFIG="vendor/kona-perf_defconfig"

# --- PREPARE ---
mkdir -p build && cd build
echo "Cloning Kernel Source..."
git clone --depth=1 $KERNEL_URL kernel
echo "Cloning Clang Toolchain..."
git clone --depth=1 $CLANG_URL -b master clang
echo "Cloning AnyKernel3..."
git clone --depth=1 $AK3_URL anykernel

# --- SET TOOLCHAIN ---
# We use the latest clang-r folder found in the toolchain
CLANG_VERSION=$(ls clang | grep clang-r | head -n 1)
export PATH="$(pwd)/clang/$CLANG_VERSION/bin:$PATH"
export KBUILD_BUILD_USER="Gemini"
export KBUILD_BUILD_HOST="CI-Build"

cd kernel

# --- COMPILATION ---
echo "Starting compilation..."
make O=out ARCH=arm64 $DEFCONFIG

make -j$(nproc) O=out \
    ARCH=arm64 \
    CC=clang \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    LLVM=1 \
    LLVM_IAS=1 \
    DTC=dtc

# --- VERIFICATION & PACKAGING ---
if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
    echo "Kernel compiled successfully!"
    cp out/arch/arm64/boot/Image.gz-dtb ../anykernel/
    cd ../anykernel
    
    # Simple AnyKernel3 setup for LG V60
    sed -i 's/do.devicecheck=1/do.devicecheck=0/g' anykernel.sh
    
    zip -r9 ../../LGV60-Kernel.zip *
    echo "ZIP created successfully."
else
    echo "Build failed! Image.gz-dtb not found."
    exit 1
fi
