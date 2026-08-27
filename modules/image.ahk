#Requires AutoHotkey v2.0

; ImageSearch helpers for the 1600x900 BBS client.
; ImageSearch returns the TOP-LEFT of the match. We calculate the real
; template size with GDI/GetObject and click its CENTER.

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

GetImageSize(path, &width := 0, &height := 0) {
    width := 0
    height := 0
    hBitmap := 0
    try {
        hBitmap := LoadPicture(path, "GDI", , )
        if !hBitmap
            return false

        ; BITMAP structure: bmType(0), bmWidth(4), bmHeight(8), ...
        bm := Buffer(32, 0)
        if DllCall("GetObject", "Ptr", hBitmap, "Int", bm.Size, "Ptr", bm.Ptr) = 0
            return false

        width := NumGet(bm, 4, "Int")
        height := NumGet(bm, 8, "Int")
        return width > 0 && height > 0
    } catch Error as err {
        Log("GetImageSize error: " err.Message)
        return false
    } finally {
        if hBitmap
            DllCall("DeleteObject", "Ptr", hBitmap)
    }
}

ClickTemplate(templatePath, variation := IMAGE_VARIATION, doubleClick := false) {
    x := 0, y := 0
    if !FindTemplate(templatePath, &x, &y, variation)
        return false

    iw := 0
    ih := 0
    if !GetImageSize(templatePath, &iw, &ih)
        return false

    ; ImageSearch gives the TOP-LEFT; click the CENTER of the actual template.
    clickX := x + Floor(iw / 2)
    clickY := y + Floor(ih / 2)

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
