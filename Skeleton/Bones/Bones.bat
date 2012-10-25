@echo off
"C:\Program Files\GoDevTool\GoAsm" Bones.asm
"C:\Program Files\GoDevTool\GoRC" /r Bones.rc
"C:\Program Files\GoDevTool\GoLink" Bones.obj Bones.res Kernel32.dll User32.dll Gdi32.dll ComDlg32.dll ComCtl32.dll AdvApi32.dll Shell32.dll hhctrl.ocx
pause