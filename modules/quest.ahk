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

        ; The current Prepare for Quest template is from a different UI scale.
        ; Try ImageSearch first, then use the button's normalized position in
        ; the BBS window so 2K/window scaling does not break the first step.
        if ClickTemplate(Asset("prepare_for_quest"))
            continue
        if ClickPrepareForQuestFallback()
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
            nextQuestGraceDeadline := A_TickCount + 5000
            continue
        }
        if ClickTemplate(Asset("next_quest.png")) {
            Log("Quest flow: next quest")
            nextQuestGraceDeadline := 0
            continue
        }
        if (nextQuestGraceDeadline = 0 || A_TickCount >= nextQuestGraceDeadline) {
            if ClickTemplate(Asset("close")) {
                Log("Quest flow: closed")
                return true
            }
        }
        Sleep POLL_DELAY_MS
    }

    Log("Quest flow: timeout")
    return false
}

ClickPrepareForQuestFallback() {
    if !WinExist(BBS_WINDOW_TITLE)
        return false

    WinGetPos &wx, &wy, &ww, &wh, BBS_WINDOW_TITLE
    if (ww <= 0 || wh <= 0)
        return false

    ; On the Story quest-detail screen, Prepare for Quest is approximately
    ; centered at 53.2% of the window width and 75.1% of its height.
    ; Only use this fallback while the expected blue button area is present.
    px := wx + Round(ww * 0.532)
    py := wy + Round(wh * 0.751)

    try {
        PixelGetColor &color, px, py, "RGB"
        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF

        ; BBS Prepare for Quest button is blue; reject obvious non-button areas.
        if (b < 100 || b < r * 1.15 || b < g * 1.05)
            return false

        WinActivate BBS_WINDOW_TITLE
        Sleep ACTION_DELAY_MS
        Click px, py
        Sleep CLICK_COOLDOWN_MS
        Log("Quest flow: Prepare for Quest (scaled fallback)")
        return true
    } catch Error as err {
        Log("Prepare fallback error: " err.Message)
        return false
    }
}
