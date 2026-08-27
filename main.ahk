#Requires AutoHotkey v2.0
#SingleInstance Force

; BBS-AHK - main entry point
; Initial scaffold. Game-specific automation will be added incrementally.

Persistent

F8:: {
    ToolTip("BBS-AHK: running")
    SetTimer(() => ToolTip(), -1500)
}

F9::ExitApp
