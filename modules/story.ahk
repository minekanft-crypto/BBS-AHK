#Requires AutoHotkey v2.0

; Story-only automation.
; Navigation is deliberately state-based so a missed animation/click can be
; retried instead of blindly replaying a fixed sequence of coordinates.

RunStory() {
    Log("Story: starting")

    ; First try to locate the Story entry/available quest marker.
    if !WaitForTemplate(Asset("new"), 10000) {
        Log("Story: no available Story quest detected")
        return false
    }

    if !ClickTemplate(Asset("new")) {
        Log("Story: failed to open quest")
        return false
    }

    Sleep 1000
    return RunQuestFlow()
}
