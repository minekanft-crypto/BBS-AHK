#Requires AutoHotkey v2.0
#SingleInstance Force
#Include config.ahk
#Include modules\logger.ahk
#Include modules\image.ahk
#Include modules\quest.ahk
#Include modules\story.ahk
#Include modules\substory.ahk

Persistent

F8:: {
    Log("BBS-AHK ready")
    SetTimer(() => ToolTip(), -1500)
}

; F6 = Story
F6:: {
    Log("Mode: Story")
    RunStory()
}

; F7 = Sub Story
F7:: {
    Log("Mode: Sub Story")
    RunSubStory()
}

; F9 = stop/exit
F9::ExitApp
