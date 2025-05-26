@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0"
set "Build_Root=%~dp0"

:Init
rem 7-zip version
rem https://www.7-zip.org/
set version=7z2409
set ztsd_dark_version=24.09-v1.5.7-R1-v0.5.0.0

rem VC-LTL version
rem https://github.com/Chuyu-Team/VC-LTL5
set "VC_LTL_Ver=5.2.1"

:VS_Version
if defined APPVEYOR_BUILD_WORKER_IMAGE (
  if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2022" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat"
  )
)
if "%VisualStudioVersion%" == "17.0" goto :VS2022

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
echo Visual Studio 2022 should be installed,
echo or try to run this script from "Developer Command Prompt".
echo 7z should be in PATH or current folder.
timeout /t 5 || pause
goto :End

:CheckReqSucc
:Download_7zip
call :Download https://github.com/ozone10/7zip-Dark7zip/archive/v%ztsd_dark_version%.zip %ztsd_dark_version%.zip
"%_7z%" x %ztsd_dark_version%.zip
if exist "7zip-Dark7zip-%ztsd_dark_version%" (
  "%_7z%" x bmp_ico.zip -y -o"%~dp07zip-Dark7zip-%ztsd_dark_version%"
  cd "7zip-Dark7zip-%ztsd_dark_version%"
) else (
  echo "source not found"
  exit /b 1
)
goto :Patch

:Patch
rem call :Download https://bitbucket.org/muldersoft/7zsd.sfx-mod/raw/c6069e36db85d9b13d0f7410c0355117e9f1eafb/patch/7zSD_Patch.lzma2408.v1.diff 7zSD_Patch.diff
call :Do_Shell_Exec 7-zip-patch.sh

:Init_VC_LTL
set "VC_LTL_File_Name=VC-LTL-Binary.7z"
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
call :Build_CPP_ZSTD /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64

pushd C\Util\7z
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
popd

pushd C\Util\7zipInstall
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
popd

pushd C\Util\7zipUninstall
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
popd

pushd C\Util\SfxSetup
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
nmake /S /F makefile_con MY_STATIC_LINK=1 NEW_COMPILER=1 CPU=AMD64 PLATFORM=x64
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
call :Build_CPP_ZSTD /S NEW_COMPILER=1 MY_STATIC_LINK=1

pushd C\Util\7z
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1
popd

pushd C\Util\7zipInstall
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1
popd

pushd C\Util\7zipUninstall
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1
popd

pushd C\Util\SfxSetup
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1
nmake /S /F makefile_con MY_STATIC_LINK=1 NEW_COMPILER=1
popd

:Package
REM C Utils
pushd C\
"%_7z%" a -mx9 -r ..\%version%.7z *.dll *.exe *.efi *.sfx *7zDark.ini
popd
REM 7-zip extra
pushd CPP\7zip
mkdir 7-zip-extra-x86
mkdir 7-zip-extra-x64
for /f "tokens=* eol=; delims=" %%i in (..\..\..\pack-7-zip-extra-x86.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-extra-x86\
for /f "tokens=* eol=; delims=" %%i in (..\..\..\pack-7-zip-extra-x64.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-extra-x64\
REM 7-zip
mkdir 7-zip-x86
mkdir 7-zip-x86\Lang
mkdir 7-zip-x86\Codecs
mkdir 7-zip-x86\Formats
mkdir 7-zip-x64
mkdir 7-zip-x64\Lang
mkdir 7-zip-x64\Codecs
mkdir 7-zip-x64\Formats
for /f "tokens=* eol=; delims=" %%i in (..\..\..\pack-7-zip-x86.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-x86\
for /f "tokens=* eol=; delims=" %%i in (..\..\..\pack-7-zip-x64.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-x64\
if exist 7-zip-x86\7-zip.dll copy 7-zip-x86\7-zip.dll 7-zip-x64\7-zip32.dll
mkdir installer
cd installer
call :Download https://www.7-zip.org/a/%version%-x64.exe %version%-x64.exe
"%_7z%" x %version%-x64.exe
xcopy /S /G /H /R /Y /Q .\Lang ..\7-zip-x86\Lang
xcopy /S /G /H /R /Y /Q .\Lang ..\7-zip-x64\Lang
xcopy /S /G /H /R /Y /Q "%Build_Root%\plugins\64" ..\7-zip-x64
xcopy /S /G /H /R /Y /Q "%Build_Root%\plugins\32" ..\7-zip-x86
xcopy /S /G /H /R /Y /Q ..\..\..\DarkMode\7zDark.ini  ..\7-zip-x64
xcopy /S /G /H /R /Y /Q ..\..\..\DarkMode\7zDark.ini  ..\7-zip-x86

for /f "tokens=* eol=; delims=" %%i in (..\..\..\..\pack-7-zip-common.txt) do if exist "%%~i" copy /Y "%%~i" ..\7-zip-x86\
for /f "tokens=* eol=; delims=" %%i in (..\..\..\..\pack-7-zip-common.txt) do if exist "%%~i" copy /Y "%%~i" ..\7-zip-x64\
cd ..
del /f /s /q installer\* >nul
rd /s /q installer
move /Y .\7-zip-x64\7zipUninstall.exe .\7-zip-x64\Uninstall.exe
move /Y .\7-zip-x86\7zipUninstall.exe .\7-zip-x86\Uninstall.exe
"%_7z%" a -mx9 -r ..\..\%version%.7z *.dll *.exe *.efi *.sfx  7-zip-x86\* 7-zip-x64\* 7-zip-extra-x86\* 7-zip-extra-x64\*
"%_7z%" a -m0=lzma -mx9 ..\..\%version%-x64.7z .\7-zip-x64\*
"%_7z%" a -m0=lzma -mx9 ..\..\%version%-x86.7z .\7-zip-x86\*
popd
copy /b .\C\Util\7zipInstall\x64\7zipInstall.exe /b + %version%-x64.7z /b %version%-x64.exe
if exist .\C\Util\7zipInstall\x86\7zipInstall.exe copy /b .\C\Util\7zipInstall\x86\7zipInstall.exe /b + %version%-x86.7z /b %version%-x86.exe
if exist .\C\Util\7zipInstall\O\7zipInstall.exe copy /b .\C\Util\7zipInstall\O\7zipInstall.exe /b + %version%-x86.7z /b %version%-x86.exe

:End
exit /b

:Download
REM call :Download URL FileName
powershell -noprofile -command "(New-Object Net.WebClient).DownloadFile('%~1', '%~2')"
exit /b %ERRORLEVEL%

:Do_Shell_Exec
busybox.exe 2>nul >nul || call :Download https://frippery.org/files/busybox/busybox.exe busybox.exe
busybox.exe sh "%Build_Root%\%1"
goto :Do_Shell_Exec_End

:Do_Shell_Exec_End
exit /b %ERRORLEVEL%

:Build_CPP_ZSTD
set "OPTS=%*"
pushd CPP\7zip\Bundles\Format7zExtract
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Format7z
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Format7zF
nmake %OPTS%
popd

pushd CPP\7zip\UI\FileManager
nmake %OPTS%
popd

pushd CPP\7zip\UI\GUI
nmake %OPTS%
popd

pushd CPP\7zip\UI\Explorer
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\SFXWin
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Codec_brotli
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Codec_lizard
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Codec_lz4
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Codec_lz5
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Codec_zstd
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Codec_flzma2
nmake %OPTS%
popd

pushd CPP\7zip\UI\Console
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\SFXCon
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Alone
nmake %OPTS%
popd

exit /b

