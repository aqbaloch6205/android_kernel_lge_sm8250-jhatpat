#!/bin/bash

# --- CONFIG ---
KERNEL_REPO="https://github.com/aqbaloch6205/android_kernel_lge_sm8250-jhatpat.git"
AK3_REPO="https://github.com/osm0sis/AnyKernel3"
DEFCONFIG="vendor/kona-perf_defconfig"

# --- ENV SETUP ---
export ARCH=arm64
export SUBARCH=arm64
export PATH="$CLANG_PATH/bin:$PATH"
export KBUILD_COMPILER_STRING=$(clang --version | head -n 1)

# --- PREPARE ---
echo ">>> Cloning Sources..."
git clone --depth=1 $KERNEL_REPO kernel
git clone --depth=1 $AK3_REPO anykernel

cd kernel

# --- COMPILE ---
echo ">>> Starting Compilation..."
make O=../out $DEFCONFIG
make -j$(nproc) O=../out \
    CC=clang \
    LLVM=1 \
    LLVM_IAS=1 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    DTC=dtc

# --- PACKAGING ---
if [ -f "../out/arch/arm64/boot/Image" ]; then
    echo ">>> Packaging with AnyKernel3..."
    cp ../out/arch/arm64/boot/Image ../anykernel/
    
    # Correctly grab the DTB for SM8250
    find ../out/arch/arm64/boot/dts/vendor/qcom/ -name "*.dtb" -exec cp {} ../anykernel/dtb \;
    
    cd ../anykernel
    # Disable device check for easier flashing across V60 variants
    sed -i 's/do.devicecheck=1/do.devicecheck=0/g' anykernel.sh
    
    zip -r9 ../../LGV60-Jhatpat-Kernel.zip *
    echo ">>> ZIP Created Successfully!"
else
    echo "!!! Build Failed: Kernel Image not found !!!"
    exit 1
fi

