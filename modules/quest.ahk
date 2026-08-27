#Requires AutoHotkey v2.0

; Common single-player Story quest state machine.
; This module intentionally contains no other BBS game modes.

RunQuestFlow() {
    Log("Quest flow: starting")
    deadline := A_TickCount + QUEST_TIMEOUT_MS
    nextQuestGraceDeadline := 0

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
            ; Give the post-clear screen time to render its Next Quest button.
            nextQuestGraceDeadline := A_TickCount + 5000
            continue
        }
        ; Continue directly into the next Story quest when the button is present.
        ; The repository asset is named next_quest.png.png, so the extension is
        ; intentionally included here because Asset() appends .png.
        if ClickTemplate(Asset("next_quest.png")) {
            Log("Quest flow: next quest")
            nextQuestGraceDeadline := 0
            continue
        }
        ; Only close after the grace period. This prevents the close button from
        ; winning the race while the Next Quest button is still appearing.
        if ClickTemplate(Asset("close")) {
            if nextQuestGraceDeadline = 0 || A_TickCount >= nextQuestGraceDeadline {
                Log("Quest flow: closed")
                return true
            }
            continue
        }
        Sleep POLL_DELAY_MS
    }

    Log("Quest flow: timeout")
    return false
}
