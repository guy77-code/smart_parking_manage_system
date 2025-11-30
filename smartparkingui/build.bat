@echo off
REM SmartParkingUI Build Script for Windows

echo === SmartParkingUI Build Script ===

REM Check if CMake is available
where cmake >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: CMake not found. Please install CMake first.
    exit /b 1
)

REM Create build directory
if exist build (
    echo Cleaning build directory...
    rmdir /s /q build
)
mkdir build
cd build

REM Configure with CMake
echo Configuring project with CMake...
cmake .. -G "Visual Studio 16 2019" -A x64 -DCMAKE_BUILD_TYPE=Release

REM Build
echo Building project...
cmake --build . --config Release

echo.
echo === Build Complete ===
echo Executable: build\Release\SmartParkingUI.exe
echo.
echo To run: build\Release\SmartParkingUI.exe

pause

