#Requires AutoHotkey v2.0

; BBS-AHK configuration - Story only

global BBS_WINDOW_TITLE := "Bleach: Brave Souls"
global DEBUG_MODE := true

global ACTION_DELAY_MS := 250
global POLL_DELAY_MS := 500
global IMAGE_VARIATION := 30
global CLICK_COOLDOWN_MS := 700
global QUEST_TIMEOUT_MS := 180000

global ASSET_DIR := A_ScriptDir "\assets\icons"

Asset(name) {
    return ASSET_DIR "\" name ".png"
}
