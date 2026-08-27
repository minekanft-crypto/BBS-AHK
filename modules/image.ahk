#Requires AutoHotkey v2.0

; ImageSearch helpers. Assets are templates captured from the BBS client.

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

    WinActivate BBS_WINDOW_TITLE
    Sleep ACTION_DELAY_MS
    Click x, y, doubleClick ? 2 : 1
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
