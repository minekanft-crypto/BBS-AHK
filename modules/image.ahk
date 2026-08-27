#Requires AutoHotkey v2.0

; BBS runs at 1600x900 inside a 2560x1440 desktop.
; Search and click in the GAME WINDOW coordinate space, never screen space.

FindTemplate(templatePath, &x := 0, &y := 0, variation := IMAGE_VARIATION) {
    if !FileExist(templatePath) || !WinExist(BBS_WINDOW_TITLE)
        return false

    WinGetPos &wx, &wy, &ww, &wh, BBS_WINDOW_TITLE
    if (ww != 1600 || wh != 900)
        return false

    CoordMode "Pixel", "Screen"
    try {
        if ImageSearch(&fx, &fy, wx, wy, wx + ww - 1, wy + wh - 1, "*" variation " " templatePath) {
            ; Convert screen coordinates returned by ImageSearch to game-local
            ; coordinates. This prevents the desktop/taskbar from being used
            ; as the click target when the game is not at (0,0).
            x := fx - wx
            y := fy - wy
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
    ; All clicks are reconstructed from the BBS window origin + the matched
    ; point, so they can never spill onto the Windows taskbar.
    clickX := wx + x + 10
    clickY := wy + y + 10

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
