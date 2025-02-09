#!/bin/bash
# remove -OPT:NOWIN98 flag in Build.mak
# http://www.ski-epic.com/2012_compiling_7zip_on_windows_with_visual_studio_10/index.html
sed -i '/LFLAGS = $(LFLAGS) -OPT:NOWIN98/ c\LFLAGS = $(LFLAGS)\' CPP/Build.mak

# patch NsisIn.h to enable NSIS script decompiling
# https://sourceforge.net/p/sevenzip/discussion/45797/thread/5d10a376/
# uncomment the NSIS_SCRIPT define using sed since the line number changed in 23.01
sed -i 's|// #define NSIS_SCRIPT|#define NSIS_SCRIPT|g' CPP/7zip/Archive/Nsis/NsisIn.h

# drop -WX option in Build.mak
# workaround error C2220: warning treated as error
# since warning C4456: declaration of '&1' hides previous local declaration
# introduced by NSIS_SCRIPT
sed -i 's/ -WX//g'  CPP/Build.mak
# drop /WX option for zstd
sed -i 's/ \/WX//g'  CPP/Build.mak

# MSIL .netmodule or module compiled with /GL found; restarting link with /LTCG;
# add /LTCG to the link command line to improve linker performance
sed -i '1 a LFLAGS = $(LFLAGS) /LTCG'  CPP/Build.mak

# Silent warning C4566
# character represented by universal-character-name 'char'
# cannot be represented in the current code page (page).
# introduced by VC-LTL at ucrt/*/stdlib.h
# making console output terrible without this.
# define _DISABLE_DEPRECATE_LTL_MESSAGE
# supresses note message provided by VC-LTL.
sed -i '1 a CFLAGS = $(CFLAGS) /wd4566 /D_DISABLE_DEPRECATE_LTL_MESSAGE'  CPP/Build.mak

# patch -p1 < 7zSD_Patch.diff