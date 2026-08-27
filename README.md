# BBS-AHK

AutoHotkey v2 automation focused ONLY on Bleach Brave Souls **Story** and **Sub Story**.

## Current scope

Included:
- Story flow (menu/quest engine scaffold)
- Sub Story flow
- ImageSearch-based UI detection
- Shared single-player quest state machine
- Debug logging
- Configurable timing and image-search tolerance

Excluded:
- Brave Battles
- Co-Op
- Epic Raids
- Point Events
- Special Moves farming
- Ticket collection
- Other game modes

## Requirements

- Windows
- AutoHotkey v2.x
- BBS running in a visible window
- UI templates in `assets/icons/`

## Controls

- `F6` — run Story
- `F7` — run Sub Story
- `F8` — test/diagnostic
- `F9` — stop/exit

## Assets

The image engine expects these templates in `assets/icons/`:

`new.png`, `new_2.png`, `ok.png`, `skip.png`, `prepare_for_quest.png`, `start_quest.png`, `pause.png`, `quest_clear.png`, `close.png`, `back.png`, `sub_2.png`, `sub_3.png`, `sub_4.png`, `sub_5.png`, `sub_6.png`.

The templates must match the BBS client resolution/scaling used at runtime. Start with the supplied/reference templates when compatible; otherwise capture fresh crops from the user's own client.

## Reference

The implementation is inspired by and partially adapted from `xJohnnyrl/bbs-auto-farmer`, whose repository uses OpenCV template matching and a state-machine approach for Sub Stories. See `LICENSE-REFERENCE.txt` for attribution/license information.

## Status

The core AHK architecture is in place. The remaining practical step is supplying/calibrating the PNG templates and then testing the exact Story menu transitions on the user's BBS client.
