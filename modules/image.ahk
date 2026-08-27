#Requires AutoHotkey v2.0

; ImageSearch helpers for the 1600x900 BBS client.
; ImageSearch returns the TOP-LEFT of a match, so use a known-safe offset
; inside the matched button instead of ImageGetSize (not an AHK v2 function).

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

    ; Templates are button crops. The click is deliberately offset from the
    ; top-left match so it cannot land on the Windows taskbar.
    ; For the BBS templates used here, the center is safely inside the button.
    clickX := x + 10
    clickY := y + 10

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
