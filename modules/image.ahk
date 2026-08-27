#Requires AutoHotkey v2.0

; Lightweight image/template helpers will live here.
; We intentionally keep recognition isolated from game-mode logic.

FindTemplate(templatePath, &x := 0, &y := 0, variation := 30) {
    ; TODO: implement once calibrated screenshots/templates are added.
    return false
}

ClickTemplate(templatePath, variation := 30) {
    x := 0, y := 0
    if !FindTemplate(templatePath, &x, &y, variation)
        return false
    Click x, y
    return true
}
