#Requires AutoHotkey v2.0

; Story quest flow for the 1600x900 BBS client.
; The user starts on the Story screen with "Prepare for Quest" visible.
; Do NOT click coordinates blindly: that can hit the Windows taskbar if the
; game is not positioned exactly as expected. We only use image matching.

RunQuestFlow() {
    Log("Quest flow: waiting for Start Quest")
    deadline := A_TickCount + QUEST_TIMEOUT_MS

    while A_TickCount < deadline {
        ; The user is already on Prepare for Quest, so the next reliable state
        ; is the party screen's Start Quest button. No NEW/Prepare coordinate
        ; click is needed here.
        if ClickTemplate(Asset("start_quest"), 60) {
            Sleep 1000
            continue
        }

        if ClickTemplate(Asset("ok"), 60) {
            Sleep 1000
            continue
        }

        if ClickTemplate(Asset("skip"), 60)
            continue

        if FindTemplate(Asset("pause"), &x, &y, 60) {
            Log("Quest flow: gameplay detected")
            Sleep 3000
            continue
        }

        if ClickTemplate(Asset("quest_clear"), 60) {
            Log("Quest flow: quest clear")
            Sleep 1000
            continue
        }

        if ClickTemplate(ASSET_DIR "\next_quest.png.png", 60) {
            Log("Quest flow: next quest")
            continue
        }

        if ClickTemplate(Asset("close"), 60) {
            Log("Quest flow: closed")
            return true
        }

        Sleep POLL_DELAY_MS
    }

    Log("Quest flow: timeout waiting for Story quest")
    return false
}
