#Requires AutoHotkey v2.0

RunSubStory() {
    Log("Sub Story: looking for menu")

    ; The reference project enters a Sub Story from the NEW marker,
    ; then scans pages for additional NEW stories.
    if !WaitForTemplate(Asset("new"), 10000)
        return false

    if !ClickTemplate(Asset("new"))
        return false

    Sleep 1500

    Loop MAX_SUB_STORY_PAGES as page {
        Log("Sub Story: scanning page " page)

        ; Finish every NEW quest visible on the current page.
        Loop {
            if !FindTemplate(Asset("new"), &x, &y)
                break
            if !ClickTemplate(Asset("new"))
                break
            Sleep 1000
            RunQuestFlow()
            Sleep 750
        }

        nextName := "sub_" (page + 1)
        if (page >= MAX_SUB_STORY_PAGES || !FindTemplate(Asset(nextName), &x, &y))
            break

        if !ClickTemplate(Asset(nextName), 25)
            break
        Sleep 1000
    }

    ClickTemplate(Asset("back"))
    Log("Sub Story: returned to menu")
    return true
}
