# BBS-AHK

AutoHotkey v2 automation focused ONLY on Bleach Brave Souls **Story**.

## Scope

Included:
- Story navigation and quest flow
- ImageSearch-based UI detection
- Shared single-player quest state machine
- Debug logging
- Configurable timing and image-search tolerance

Excluded:
- Sub Story
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
- `F8` — test/diagnostic
- `F9` — stop/exit

## Assets

Only Story-related templates should be placed in `assets/icons/`. The exact final list will be documented after the Story flow is calibrated against the BBS client.

Templates must match the BBS client resolution/scaling used at runtime. Reference templates can be used when compatible; otherwise capture fresh crops from the user's own client.

## Reference

The implementation is inspired by and partially adapted from `xJohnnyrl/bbs-auto-farmer`, whose repository uses image/template detection and state-machine automation. The original MIT license/attribution is retained where applicable.

## Status

The project is now **Story-only**. Sub Story support has been removed to keep the first version focused and reliable. The next practical step is completing and calibrating the Story templates and transitions.
