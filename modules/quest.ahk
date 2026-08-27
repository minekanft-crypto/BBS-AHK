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

        ; Try the normal template first, then the scaled fallback for the
        ; 2K desktop/window layout shown by the user.
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

    ; Based on the supplied full-screen screenshot, the center of the
    ; Prepare for Quest button is about 68.8% across and 90.8% down the
    ; complete BBS window. Use a small search area around that point so
    ; normal window movement does not matter.
    cx := wx + Round(ww * 0.688)
    cy := wy + Round(wh * 0.908)

    ; PixelGetColor in AutoHotkey v2 returns the color; it does not take an
    ; output variable. Keep the RGB mode explicit for the color test.
    try {
        color := PixelGetColor(cx, cy, "RGB")
        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF

        ; Reject obvious non-blue areas. The actual click remains at the
        ; known button center from the screenshot.
        if (b < 100 || b < r * 1.15 || b < g * 1.05)
            return false

        WinActivate BBS_WINDOW_TITLE
        Sleep ACTION_DELAY_MS
        Click cx, cy
        Sleep CLICK_COOLDOWN_MS
        Log("Quest flow: Prepare for Quest (scaled fallback)")
        return true
    } catch Error as err {
        Log("Prepare fallback error: " err.Message)
        return false
    }
}
