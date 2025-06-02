#!/bin/bash

#set -e

 #
 # Script For Building Android Kernel
 #

DIR=`readlink -f .`
MAIN=`readlink -f ${DIR}/..`
export CLANG_PATH=$MAIN/clang-r547379/bin
export PATH=${BINUTILS_PATH}:${CLANG_PATH}:${PATH}
make -j8 CC='ccache clang' ARCH=arm64 LLVM=1 LLVM_IAS=1 O=out gki_defconfig

THREAD="-j$(nproc --all)"

# Basic Information
DEFCONFIG="gki_defconfig"
DEVICE=garnet
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
TANGGAL=$(date +"%F%S")
ANYKERNEL3_DIR=$PWD/AnyKernel3/
FINAL_KERNEL_ZIP=WakacaW-${DEVICE}-${TANGGAL}.zip

# Verbose Build
VERBOSE=0

# Exports
export CLANG_PATH=$MAIN/clang-r547379/bin/
export PATH=${CLANG_PATH}:${PATH}
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=$MAIN/clang-r547379/bin/aarch64-linux-gnu- CC=clang CXX=clang++

export ARCH=arm64
export SUBARCH=$ARCH
export KBUILD_BUILD_USER=byben
export KBUILD_BUILD_HOST=wkcw

# Speed up build process
MAKE="./makeparallel"

# Start build
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Clean build always lol
mkdir -p out
make O=out clean

make CC="ccache clang" CXX="ccache clang++" LLVM=1 LLVM_IAS=1 O=out $DEFCONFIG
make CC='ccache clang' CXX="ccache clang++" LLVM=1 LLVM_IAS=1 O=out $THREAD \
    CONFIG_LTO_CLANG=y CONFIG_LTO_NONE=n \
    CONFIG_LTO_CLANG_THIN=y CONFIG_LTO_CLANG_FULL=n 2>&1  | tee kernel.log

# Verify Files
ls $PWD/out/arch/arm64/boot/Image.gz

# Anykernel 3 time!!
ls $ANYKERNEL3_DIR
rm -rf $ANYKERNEL3_DIR/Image.gz
rm -rf $ANYKERNEL3_DIR/dtbo.img
rm -rf $ANYKERNEL3_DIR/dtb.img
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP
cp $PWD/out/arch/arm64/boot/Image.gz $ANYKERNEL3_DIR/

cd $ANYKERNEL3_DIR/
zip -r9 "../$FINAL_KERNEL_ZIP" * -x README $FINAL_KERNEL_ZIP

cd ..
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP
rm -rf $ANYKERNEL3_DIR/Image.gz
rm -rf out/
rm -rf kernel.log

sha1sum $FINAL_KERNEL_ZIP

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
