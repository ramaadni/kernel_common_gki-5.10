#!/usr/bin/env bash

# Dependencies
# init
init() {
    mkdir ~/bin
    PATH=~/bin:$PATH
    curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
    chmod a+x ~/bin/repo
}

WORK_DIR=$(pwd)
ANYKERNEL="${WORK_DIR}/anykernel"
KERNEL_DIR="garnet"
IMAGE=$WORK_DIR/out/dist/Image
DATE=$(date +"%Y%m%d-%H%M")
START=$(date +"%s")
CACHE=1
export CACHE
export KBUILD_COMPILER_STRING
ARCH=arm64
export ARCH
KBUILD_BUILD_HOST="rmdn"
export KBUILD_BUILD_HOST
KBUILD_BUILD_USER="wakacaw"
export KBUILD_BUILD_USER
DEVICE="Poco X6 5G"
export DEVICE
CODENAME="garnet"
export CODENAME
DEFCONFIG="gki_defconfig"
export DEFCONFIG
COMMIT_HASH=$(git rev-parse --short HEAD)
export COMMIT_HASH
PROCS=$(nproc --all)
export PROCS
STATUS=STABLE
export STATUS
source "${HOME}"/.bashrc && source "${HOME}"/.profile
if [ $CACHE = 1 ]; then
    ccache -M 100G
    export USE_CCACHE=1
fi
LC_ALL=C
export LC_ALL

tg() {
    curl -sX POST https://api.telegram.org/bot"${token}"/sendMessage -d chat_id="${chat_id}" -d parse_mode=Markdown -d disable_web_page_preview=true -d text="$1" &>/dev/null
}

tgs() {
    MD5=$(md5sum "$1" | cut -d' ' -f1)
    curl -fsSL -X POST -F document=@"$1" https://api.telegram.org/bot"${token}"/sendDocument \
        -F "chat_id=${chat_id}" \
        -F "parse_mode=Markdown" \
        -F "caption=$2 | *MD5*: \`$MD5\`"
}

# Send Build Info
sendinfo() {
    tg "
• Compiler Action •
*Building on*: \`Github actions\`
*Date*: \`${DATE}\`
*Device*: \`${DEVICE} (${CODENAME})\`
*Branch*: \`$(git rev-parse --abbrev-ref HEAD)\`
*Last Commit*: [${COMMIT_HASH}](${REPO}/commit/${COMMIT_HASH})
*Compiler*: \`${KBUILD_COMPILER_STRING}\`
*Build Status*: \`${STATUS}\`"
}

sync() {
    cd $WORK_DIR
    echo "Syncing manifest"
    repo init -u https://github.com/ramaadni/kernel_manifest -b wakacaw
    repo sync
    sudo apt install -y ccache
    echo "Done"
}

# Push kernel to channel
push() {
    cd AnyKernel || exit 1
    ZIP=$(echo *.zip)
    tgs "${ZIP}" "Build took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s). | For *${DEVICE} (${CODENAME})* | ${KBUILD_COMPILER_STRING}"
}

# Catch Error
finderr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d sticker="CAACAgIAAxkBAAED3JViAplqY4fom_JEexpe31DcwVZ4ogAC1BAAAiHvsEs7bOVKQsl_OiME" \
        -d text="Build throw an error(s)"
    error_sticker
    exit 1
}

# Compile
compile() {

    if [ -d "out" ]; then
        rm -rf out && mkdir -p out
    fi

    cd $WORK_DIR
    LTO=thin BUILD_CONFIG=common/build.config.gki.custom build/build.sh

    if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
    fi

    git clone --depth=1 https://github.com/ramaadni/AnyKernel3.git "$ANYKERNEL" -b garnet
    cp "$IMAGE" "$ANYKERNEL"
}
# Zipping
zipping() {
    cd $ANYKERNEL || exit 1
    zip -r9 WakacaW-"${BRANCH}"-"${CODENAME}"-"${DATE}".zip ./*
    cd ..
}

init
sync
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$((END - START))
push
