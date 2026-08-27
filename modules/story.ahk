#Requires AutoHotkey v2.0

RunStory() {
    Log("Story: starting")

    ; Story navigation varies by client/window state, so the shared quest
    ; state machine is kept separate from menu navigation.
    ; Once the Story menu templates are supplied, add their exact transitions here.

    if ClickTemplate(Asset("new")) {
        Sleep 1000
        return RunQuestFlow()
    }

    Log("Story: no recognized entry template")
    return false
}
