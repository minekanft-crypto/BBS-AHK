#Requires AutoHotkey v2.0

; Story quest flow for a 1600x900 BBS client.
; Start from the Story quest screen where "Prepare for Quest" is visible.

RunQuestFlow() {
    Log("Quest flow: starting from Prepare for Quest")
    deadline := A_TickCount + QUEST_TIMEOUT_MS

    while A_TickCount < deadline {
        ; 1) Open the party/setup screen.
        if ClickTemplate(Asset("prepare_for_quest"), 60)
            continue
        if ClickPrepareForQuest1600()
            continue

        ; 2) Start the quest from the party screen.
        if ClickTemplate(Asset("start_quest"), 60)
            continue

        ; 3) Confirm the start dialog if present.
        if ClickTemplate(Asset("ok"), 60)
            continue

        ; 4) Skip dialogs/cutscenes when they appear.
        if ClickTemplate(Asset("skip"), 60)
            continue

        ; 5) Gameplay: wait until the quest finishes.
        if FindTemplate(Asset("pause"), &x, &y, 60) {
            Log("Quest flow: gameplay detected")
            Sleep 2000
            continue
        }

        ; 6) Quest result screen.
        if ClickTemplate(Asset("quest_clear"), 60) {
            Log("Quest flow: quest clear")
            Sleep 1000
            continue
        }

        ; 7) Next quest / close result screen.
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

    Log("Quest flow: timeout")
    return false
}

; At exactly 1600x900, use the known Prepare for Quest button position as a
; hard fallback. This avoids the template mismatch that was causing the bot
; to report that no Story quest was available.
ClickPrepareForQuest1600() {
    if !WinExist(BBS_WINDOW_TITLE)
        return false

    WinGetPos &wx, &wy, &ww, &wh, BBS_WINDOW_TITLE
    if (ww <= 0 || wh <= 0)
        return false

    ; Relative position used by the 1600x900 client layout.
    cx := wx + Round(ww * 0.688)
    cy := wy + Round(wh * 0.908)

    WinActivate BBS_WINDOW_TITLE
    Sleep ACTION_DELAY_MS
    Click cx, cy
    Sleep CLICK_COOLDOWN_MS
    Log("Quest flow: clicked Prepare for Quest fallback")
    return true
}
