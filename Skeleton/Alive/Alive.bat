@echo off
"C:\Program Files\GoDevTool\GoAsm" Alive.asm
"C:\Program Files\GoDevTool\GoRC" /r Alive.rc
"C:\Program Files\GoDevTool\GoLink" Alive.obj Alive.res Kernel32.dll User32.dll Gdi32.dll ComDlg32.dll ComCtl32.dll AdvApi32.dll Shell32.dll hhctrl.ocx
pause