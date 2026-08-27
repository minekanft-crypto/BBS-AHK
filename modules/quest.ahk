#Requires AutoHotkey v2.0

; Common single-player quest/story state machine.
; This intentionally contains only normal Story/Sub Story flow.

RunQuestFlow() {
    Log("Quest flow: starting")
    deadline := A_TickCount + QUEST_TIMEOUT_MS

    while A_TickCount < deadline {
        if ClickTemplate(Asset("new_2"))
            continue
        if ClickTemplate(Asset("ok"))
            continue
        if ClickTemplate(Asset("skip"))
            continue
        if ClickTemplate(Asset("prepare_for_quest"))
            continue
        if ClickTemplate(Asset("start_quest"))
            continue
        if FindTemplate(Asset("pause"), &x, &y) {
            Log("Quest flow: gameplay detected")
            Sleep 1500
            continue
        }
        if ClickTemplate(Asset("quest_clear")) {
            Log("Quest flow: quest clear")
            continue
        }
        if ClickTemplate(Asset("close")) {
            Log("Quest flow: closed")
            return true
        }
        Sleep POLL_DELAY_MS
    }

    Log("Quest flow: timeout")
    return false
}
