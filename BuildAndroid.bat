@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

:: ==================================================
:: 1. NDK 路径（只改这里）
:: ==================================================
set "ANDROID_NDK=G:\AndroidTest\AndroidSDK\ndk\28.1.13356709"

:: 当前脚本所在目录（无结尾反斜杠）
for %%i in ("%~dp0.") do set "SPDLOG_DIR=%%~fi"

set "BUILD_DIR=%SPDLOG_DIR%\android_build"
set "OUTPUT_DIR=%SPDLOG_DIR%\android_output"

:: ==================================================
:: 2. 工具检查
:: ==================================================
set "TOOLCHAIN=%ANDROID_NDK%\build\cmake\android.toolchain.cmake"
set "NINJA_EXE=G:\AndroidTest\AndroidSDK\cmake\3.22.1\bin\ninja.exe"

if not exist "%TOOLCHAIN%" (
    echo [FATAL] android.toolchain.cmake not found
    echo %TOOLCHAIN%
    pause
    exit /b 1
)

if not exist "%NINJA_EXE%" (
    echo [FATAL] ninja.exe not found
    echo %NINJA_EXE%
    pause
    exit /b 1
)

if not exist "%SPDLOG_DIR%\CMakeLists.txt" (
    echo [FATAL] CMakeLists.txt not found
    echo %SPDLOG_DIR%
    pause
    exit /b 1
)

:: ==================================================
:: 3. 清理输出目录
:: ==================================================
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
if exist "%OUTPUT_DIR%" rmdir /s /q "%OUTPUT_DIR%"
mkdir "%OUTPUT_DIR%"

:: ==================================================
:: 4. ABI 配置
:: ==================================================
set "ABIS=arm64-v8a x86_64"

for %%A in (%ABIS%) do (
    echo.
    echo --------------------------------------------------
    echo  Building ABI: %%A
    echo --------------------------------------------------

    set "CUR_BUILD=%BUILD_DIR%\%%A"
    set "CUR_INSTALL=!CUR_BUILD!\install"

    :: 创建 build 目录并进入
    mkdir "!CUR_BUILD!"
    pushd "!CUR_BUILD!"

    :: CMake 配置选项
    set "OPTS="
    set "OPTS=!OPTS! -DCMAKE_TOOLCHAIN_FILE=%TOOLCHAIN%"
    set "OPTS=!OPTS! -DANDROID_ABI=%%A"
    set "OPTS=!OPTS! -DANDROID_PLATFORM=android-21"
    set "OPTS=!OPTS! -DCMAKE_BUILD_TYPE=Release"
    set "OPTS=!OPTS! -DSPDLOG_BUILD_SHARED=OFF"
    set "OPTS=!OPTS! -DSPDLOG_BUILD_EXAMPLE=OFF"
    set "OPTS=!OPTS! -DSPDLOG_BUILD_TESTS=OFF"
    set "OPTS=!OPTS! -DCMAKE_INSTALL_PREFIX=!CUR_INSTALL!"
    set "OPTS=!OPTS! -G Ninja"
    set "OPTS=!OPTS! -DCMAKE_MAKE_PROGRAM=%NINJA_EXE%"

    echo.
    echo [CMAKE CONFIG]
    echo cmake "%SPDLOG_DIR%" !OPTS!
    echo.

    :: 配置
    cmake "%SPDLOG_DIR%" !OPTS!
    if errorlevel 1 goto :fail

    :: 编译
    cmake --build . --parallel
    if errorlevel 1 goto :fail

    :: 安装
    cmake --install .
    if errorlevel 1 goto :fail

    :: 拷贝静态库
    if not exist "%OUTPUT_DIR%\libs\%%A" mkdir "%OUTPUT_DIR%\libs\%%A"
    copy /y "!CUR_INSTALL!\lib\*.a" "%OUTPUT_DIR%\libs\%%A\" >nul

    :: 拷贝头文件（只拷贝一次）
    if not exist "%OUTPUT_DIR%\include" (
        xcopy /s /e /i /y /q "!CUR_INSTALL!\include" "%OUTPUT_DIR%\include" >nul
    )

    echo [SUCCESS] %%A
    popd
)

echo.
echo ==================================================
echo  Build finished successfully
echo  Output: %OUTPUT_DIR%
echo ==================================================
pause
exit /b 0

:fail
echo.
echo [ERROR] Build failed
popd
pause
exit /b 1
