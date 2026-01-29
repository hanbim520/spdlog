#!/bin/bash
set -e
set -o pipefail

# ==================================================
# 1. 基本路径
# ==================================================
SPDLOG_DIR="$(cd "$(dirname "$0")" && pwd)"
IOS_BUILD_DIR="$SPDLOG_DIR/ios_build"
MACOS_BUILD_DIR="$SPDLOG_DIR/macos_build"
IOS_OUTPUT_DIR="$SPDLOG_DIR/ios_output"
MACOS_OUTPUT_DIR="$SPDLOG_DIR/macos_output"

IOS_TOOLCHAIN="./tools/ios-cmake/ios.toolchain.cmake"

mkdir -p "$IOS_OUTPUT_DIR" "$MACOS_OUTPUT_DIR"

# ==================================================
# 2. 架构设置
# ==================================================
IOS_ARCHS=("arm64")      # arm64: 设备, x86_64: 模拟器
MACOS_ARCHS=("arm64")

# ==================================================
# 3. iOS 编译
# ==================================================
echo "==================== iOS Build ===================="

for ARCH in "${IOS_ARCHS[@]}"; do
    CUR_BUILD="$IOS_BUILD_DIR/$ARCH"
    CUR_INSTALL="$CUR_BUILD/install"

    mkdir -p "$CUR_BUILD"
    pushd "$CUR_BUILD" > /dev/null

    echo "Building iOS for $ARCH..."

    if [ "$ARCH" == "x86_64" ]; then
        PLATFORM="SIMULATOR64"
    else
        PLATFORM="OS"
    fi

    cmake "$SPDLOG_DIR" \
        -G Xcode \
        -DCMAKE_TOOLCHAIN_FILE="$IOS_TOOLCHAIN" \
        -DPLATFORM=$PLATFORM \
        -DCMAKE_OSX_ARCHITECTURES=$ARCH \
        -DCMAKE_BUILD_TYPE=Release \
        -DSPDLOG_BUILD_SHARED=OFF \
        -DSPDLOG_BUILD_EXAMPLE=OFF \
        -DSPDLOG_BUILD_TESTS=OFF \
        -DCMAKE_INSTALL_PREFIX="$CUR_INSTALL"

    cmake --build . --config Release --target install

    mkdir -p "$IOS_OUTPUT_DIR/libs/$ARCH"
    cp "$CUR_INSTALL/lib/libspdlog.a" "$IOS_OUTPUT_DIR/libs/$ARCH/"

    if [ ! -d "$IOS_OUTPUT_DIR/include" ]; then
        cp -R "$CUR_INSTALL/include" "$IOS_OUTPUT_DIR/"
    fi

    popd > /dev/null
done

echo "iOS build finished: $IOS_OUTPUT_DIR"

# ==================================================
# 4. macOS 编译
# ==================================================
echo "==================== macOS Build ===================="

for ARCH in "${MACOS_ARCHS[@]}"; do
    CUR_BUILD="$MACOS_BUILD_DIR/$ARCH"
    CUR_INSTALL="$CUR_BUILD/install"

    mkdir -p "$CUR_BUILD"
    pushd "$CUR_BUILD" > /dev/null

    echo "Building macOS for $ARCH..."

    cmake "$SPDLOG_DIR" \
        -G "Unix Makefiles" \
        -DCMAKE_OSX_ARCHITECTURES=$ARCH \
        -DCMAKE_BUILD_TYPE=Release \
        -DSPDLOG_BUILD_SHARED=OFF \
        -DSPDLOG_BUILD_EXAMPLE=OFF \
        -DSPDLOG_BUILD_TESTS=OFF \
        -DCMAKE_INSTALL_PREFIX="$CUR_INSTALL"

    cmake --build . --parallel
    cmake --install .

    mkdir -p "$MACOS_OUTPUT_DIR/libs/$ARCH"
    cp "$CUR_INSTALL/lib/libspdlog.a" "$MACOS_OUTPUT_DIR/libs/$ARCH/"

    if [ ! -d "$MACOS_OUTPUT_DIR/include" ]; then
        cp -R "$CUR_INSTALL/include" "$MACOS_OUTPUT_DIR/"
    fi

    popd > /dev/null
done

echo "macOS build finished: $MACOS_OUTPUT_DIR"
echo "==================== ALL DONE ===================="
