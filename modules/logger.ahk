#Requires AutoHotkey v2.0

Log(message) {
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    line := "[" timestamp "] " message
    OutputDebug line
    if DEBUG_MODE
        ToolTip line
}
