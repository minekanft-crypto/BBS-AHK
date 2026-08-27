#Requires AutoHotkey v2.0

; Story-only automation.
; Navigation is deliberately state-based so a missed animation/click can be
; retried instead of blindly replaying a fixed sequence of coordinates.

RunStory() {
    Log("Story: starting")

    ; The NEW marker is the first Story state. Use tolerant image matching so
    ; Windows/client scaling or small visual differences do not cause a false
    ; "no quest" result.
    if !WaitForTemplateMultiScale(Asset("new"), 10000) {
        Log("Story: NEW marker not found with normal/tolerant matching")
        return false
    }

    Log("Story: NEW marker detected")
    if !ClickTemplate(Asset("new"), 60) {
        ; Retry using the exact default variation if the first click search
        ; happened to miss the marker after the UI moved.
        if !ClickTemplate(Asset("new"), IMAGE_VARIATION) {
            Log("Story: failed to open quest")
            return false
        }
    }

    Sleep 1000
    return RunQuestFlow()
}
