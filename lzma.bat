@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0"
set "Build_Root=%~dp0"

:Init
rem 7-zip version
rem https://www.7-zip.org/
set version=7z2409
set dark_version=24.09-v0.4.4.0
set lzma=lzma2408

rem VC-LTL version
rem https://github.com/Chuyu-Team/VC-LTL5
set "VC_LTL_Ver=5.1.1"

:VS_Version
if defined APPVEYOR_BUILD_WORKER_IMAGE (
  if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2022" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat"
  )
)
if "%VisualStudioVersion%" == "17.0" goto :VS2022
if exist "%VSAPPIDDIR%\..\..\VC\Auxiliary\Build\vcvarsall.bat" == "15.0" goto :VS2017

:VS2022
set "VS=VS2022"
if exist "%VSINSTALLDIR%" if exist "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat" (
  set "vcvarsall_bat=%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat"
  goto :CheckReq
)
if not exist "%VS170COMNTOOLS%" (
  if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools" (
    set "VS170COMNTOOLS=C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\"
  )
  if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools" (
    set "VS170COMNTOOLS=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\"
  )
)
set "vcvarsall_bat=%VS170COMNTOOLS%..\..\VC\Auxiliary\Build\vcvarsall.bat"
if exist "%vcvarsall_bat%" goto :CheckReq

:CheckReq
for /f "tokens=* delims=" %%i in ('where 7z') do set "_7z=%%i"
if not defined _7z set _7z=7z
"%_7z%" i 2>nul >nul || goto :CheckReqFail
if not exist "%vcvarsall_bat%" goto :CheckReqFail
goto :CheckReqSucc

:CheckReqFail
echo Prerequisites Check Failed.
echo Visual Studio 2022 or 2019 or 2017 or 2015 should be installed,
echo or try to run this script from "Developer Command Prompt".
echo 7z should be in PATH or current folder.
timeout /t 5 || pause
goto :End

:CheckReqSucc

:Download_7zip
call :Download https://7-zip.org/a/lzma2408.7z lzma2409.7z
"%_7z%" x lzma2408.7z -o"%~dp0lzma2408"
if exist "lzma2408" (
  cd "lzma2408"
) else (
  echo "source not found"
  exit /b 1
)
goto :Patch

:Patch
call :Do_Shell_Exec NSIS.sh

:Init_VC_LTL
set "VC_LTL_File_Name=VC-LTL-%VC_LTL_Ver%-Binary.7z"
set "VC_LTL_URL=https://github.com/Chuyu-Team/VC-LTL5/releases/download/v%VC_LTL_Ver%/%VC_LTL_File_Name%"
set "VC_LTL_Dir=VC-LTL"
mkdir "%VC_LTL_Dir%"
cd "%VC_LTL_Dir%"
call :Download "%VC_LTL_URL%" VC_LTL.7z
"%_7z%" x VC_LTL.7z
cd ..
set "VC_LTL_PATH=%CD%\%VC_LTL_Dir%"
set DisableAdvancedSupport=true
set LTL_Mode=Light

:Env_x64
set WindowsTargetPlatformMinVersion=6.0.6000.0
set CleanImport=true
set INCLUDE=
set LIB=
set VC_LTL_Helper_Load=
set Platform=
call "%vcvarsall_bat%" amd64
call "%VC_LTL_PATH%\VC-LTL helper for nmake.cmd"
@echo off

echo ----------------
echo PATH=
echo %PATH%
echo ----------------
echo INCLUDE=
echo %INCLUDE%
echo ----------------
echo LIB=
echo %LIB%
echo ----------------

:Build_x64
pushd CPP\7zip
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
popd

pushd C\Util\7z
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
popd

pushd C\Util\SfxSetup
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
nmake /S /F makefile_con MY_STATIC_LINK=1 NEW_COMPILER=1 CPU=AMD64 PLATFORM=x64
popd

pushd CPP\7zip\Bundles\SFXCon
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
popd

pushd CPP\7zip\Bundles\SFXSetup
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
popd

pushd CPP\7zip\Bundles\SFXWin
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
popd

:Env_x86
set WindowsTargetPlatformMinVersion=6.0.6000.0
set CleanImport=true
set INCLUDE=
set LIB=
set VC_LTL_Helper_Load=
set Platform=
set SupportWinXP=false
call "%vcvarsall_bat%" x86
call "%VC_LTL_PATH%\VC-LTL helper for nmake.cmd"
@echo off

echo ----------------
echo PATH=
echo %PATH%
echo ----------------
echo INCLUDE=
echo %INCLUDE%
echo ----------------
echo LIB=
echo %LIB%
echo ----------------

:Build_x86
pushd CPP\7zip
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1
popd

pushd C\Util\7z
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1
popd

pushd C\Util\SfxSetup
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1
nmake /S /F makefile_con MY_STATIC_LINK=1 NEW_COMPILER=1
popd

pushd CPP\7zip\Bundles\SFXCon
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1
popd

pushd CPP\7zip\Bundles\SFXSetup
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1
popd

pushd CPP\7zip\Bundles\SFXWin
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1
popd

:End
exit /b

:Download
REM call :Download URL FileName
powershell -noprofile -command "(New-Object Net.WebClient).DownloadFile('%~1', '%~2')"
exit /b %ERRORLEVEL%

:Do_Shell_Exec
busybox.exe 2>nul >nul || call :Download https://frippery.org/files/busybox/busybox.exe busybox.exe
busybox.exe sh "%Build_Root%\%1"
busybox.exe patch -p1 < "%Build_Root%\lzma2408.diff"
goto :Do_Shell_Exec_End

:Do_Shell_Exec_End
exit /b %ERRORLEVEL%


