#Requires AutoHotkey v2.0

; BBS is rendered at 1600x900 while the desktop is 2560x1440.
; ImageSearch works in SCREEN coordinates. We therefore search only inside
; the actual BBS window and click the matched image relative to that window.

FindTemplate(templatePath, &x := 0, &y := 0, variation := IMAGE_VARIATION) {
    if !FileExist(templatePath) || !WinExist(BBS_WINDOW_TITLE)
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

    WinGetPos &wx, &wy, &ww, &wh, BBS_WINDOW_TITLE

    ; ImageSearch already returned SCREEN coordinates. Do NOT add the window
    ; origin a second time. Click slightly inside the matched image.
    clickX := x + 10
    clickY := y + 10

    ; Hard safety boundary: never click outside the BBS client window.
    if (clickX < wx || clickX >= wx + ww || clickY < wy || clickY >= wy + wh)
        return false

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
