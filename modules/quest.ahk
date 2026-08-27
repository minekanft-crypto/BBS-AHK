#Requires AutoHotkey v2.0

; Story-only quest flow. Starts directly from the Story quest detail screen.

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

        ; Prepare for Quest is the primary entry point.
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
        if ClickTemplate(ASSET_DIR "\next_quest.png.png") {
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

    cx := wx + Round(ww * 0.688)
    cy := wy + Round(wh * 0.908)

    try {
        color := PixelGetColor(cx, cy, "RGB")
        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF

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
