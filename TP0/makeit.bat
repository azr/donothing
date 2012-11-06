@echo off

if not exist rsrc.rc goto over1
\masm32\bin\rc /v rsrc.rc
\masm32\bin\cvtres /machine:ix86 rsrc.res
 :over1

if exist "donothing.obj" del "donothing.obj"
if exist "donothing.exe" del "donothing.exe"

\masm32\bin\ml /c /coff "donothing.asm"
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

\masm32\bin\Link /SUBSYSTEM:WINDOWS /OPT:NOREF "donothing.obj" rsrc.res
 if errorlevel 1 goto errlink

dir "donothing.*"
goto TheEnd

:nores
 \masm32\bin\Link /SUBSYSTEM:WINDOWS /OPT:NOREF "donothing.obj"
 if errorlevel 1 goto errlink
dir "donothing.*"
goto TheEnd

:errlink
 echo _
echo Link error
goto TheEnd

:errasm
 echo _
echo Assembly Error
goto TheEnd

:TheEnd
