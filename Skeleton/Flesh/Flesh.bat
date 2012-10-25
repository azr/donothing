@echo off
"C:\Program Files\GoDevTool\GoAsm" Flesh.asm
"C:\Program Files\GoDevTool\GoRC" /r Flesh.rc
"C:\Program Files\GoDevTool\GoLink" Flesh.obj Flesh.res Kernel32.dll User32.dll Gdi32.dll ComDlg32.dll ComCtl32.dll AdvApi32.dll Shell32.dll hhctrl.ocx
pause