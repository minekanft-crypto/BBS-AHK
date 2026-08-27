#Requires AutoHotkey v2.0

; ImageSearch helpers. All templates are captured for the 1600x900 BBS client.
; Important: ImageSearch returns the TOP-LEFT of the match. Always click the
; CENTER of the matched image, otherwise a match near the bottom of the game
; can result in a click outside the actual button.

FindTemplate(templatePath, &x := 0, &y := 0, variation := IMAGE_VARIATION) {
    if !FileExist(templatePath)
        return false
    if !WinExist(BBS_WINDOW_TITLE)
        return false

    WinGetPos &wx, &wy, &ww, &wh, BBS_WINDOW_TITLE
    if (ww <= 0 || wh <= 0)
        return false

    CoordMode "Pixel", "Screen"
    try {
        if ImageSearch(&fx, &fy, wx, wy, wx + ww - 1, wy + wh - 1, "*" variation " " templatePath) {
            x := fx
            y := fy
            return true
        }
    } catch Error as err {
        Log("ImageSearch error: " err.Message)
    }
    return false
}

ClickTemplate(templatePath, variation := IMAGE_VARIATION, doubleClick := false) {
    x := 0, y := 0
    if !FindTemplate(templatePath, &x, &y, variation)
        return false

    ; ImageSearch gives the match's top-left corner. Calculate its center.
    try {
        ImageGetSize &iw, &ih, templatePath
    } catch {
        return false
    }
    if (iw <= 0 || ih <= 0)
        return false

    clickX := x + Round(iw / 2)
    clickY := y + Round(ih / 2)

    WinRestore BBS_WINDOW_TITLE
    WinActivate BBS_WINDOW_TITLE
    if !WinWaitActive(BBS_WINDOW_TITLE, , 1)
        return false

    Sleep ACTION_DELAY_MS
    Click clickX, clickY, doubleClick ? 2 : 1
    Sleep CLICK_COOLDOWN_MS
    return true
}

WaitForTemplate(templatePath, timeoutMs := 10000, variation := IMAGE_VARIATION) {
    deadline := A_TickCount + timeoutMs
    while A_TickCount < deadline {
        if FindTemplate(templatePath, &x, &y, variation)
            return true
        Sleep POLL_DELAY_MS
    }
    return false
}
