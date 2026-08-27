# Required image templates

Put the BBS UI screenshots/templates in THIS folder.

Minimum templates currently expected by the engine:
- new.png
- new_2.png
- ok.png
- skip.png
- prepare_for_quest.png
- start_quest.png
- pause.png
- quest_clear.png
- close.png
- back.png
- sub_2.png
- sub_3.png
- sub_4.png
- sub_5.png
- sub_6.png

These should be cropped tightly around the relevant UI element and captured at the same game resolution/scaling used while running the script.

The reference project uses image templates for these UI transitions. BBS-AHK intentionally keeps the templates separate from the AHK logic so they can be replaced/calibrated without changing code.
