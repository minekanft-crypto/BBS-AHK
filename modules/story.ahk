#Requires AutoHotkey v2.0

; Story-only automation.
; Start directly from the Story quest detail screen. The NEW marker is not
; required because it is unreliable across client layouts/scaling.

RunStory() {
    Log("Story: starting directly from Prepare for Quest")
    return RunQuestFlow()
}
