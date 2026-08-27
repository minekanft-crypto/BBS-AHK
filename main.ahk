#Requires AutoHotkey v2.0
#SingleInstance Force
#Include config.ahk
#Include modules\logger.ahk
#Include modules\image.ahk
#Include modules\quest.ahk
#Include modules\story.ahk

Persistent

F8:: {
    Log("BBS-AHK ready - Story only")
    SetTimer(() => ToolTip(), -1500)
}

; F6 = Story
F6:: {
    Log("Mode: Story")
    RunStory()
}

; F9 = stop/exit
F9::ExitApp
