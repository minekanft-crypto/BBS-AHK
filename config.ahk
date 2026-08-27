#Requires AutoHotkey v2.0

; BBS-AHK configuration
; Designed for a visible BBS window. Default coordinates/assets will be calibrated locally.

global BBS_WINDOW_TITLE := "Bleach: Brave Souls"
global DEBUG_MODE := true

global MODES := Map(
    "story", true,
    "sub_story", true
)

; Safety: automation stops with F9 or when the script is paused.
global ACTION_DELAY_MS := 250
