import os
import time
import cv2
import numpy as np
import pyautogui
import pygetwindow as gw
import keyboard
from mss import mss

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ASSET_DIR = os.path.join(BASE_DIR, "assets", "icons")
WINDOW_TITLE = "Bleach: Brave Souls"
POLL = 0.35
BACK_INTERVAL = 40.0
STOP = False

WATCH = [
    ("prepare_for_quest.png", 0.85),
    ("start_quest.png", 0.85),
    ("ok.png", 0.80),
    ("skip.png", 0.80),
    ("tap_screen.png", 0.80),
    ("cancel.png", 0.80),
    ("skin.png", 0.80),
    ("clear.png", 0.80),
    ("next_quest.png", 0.65),
    ("close.png", 0.80),
]


def log(msg):
    print(f"[BBS] {msg}", flush=True)


def get_window():
    wins = [w for w in gw.getWindowsWithTitle(WINDOW_TITLE) if w.width > 0 and w.height > 0]
    return max(wins, key=lambda w: w.width * w.height) if wins else None


def screenshot(win, sct):
    try:
        shot = sct.grab({"left": int(win.left), "top": int(win.top), "width": int(win.width), "height": int(win.height)})
        return cv2.cvtColor(np.array(shot), cv2.COLOR_BGRA2BGR)
    except Exception:
        return None


def match(name, img, threshold):
    path = os.path.join(ASSET_DIR, name)
    if img is None or not os.path.exists(path):
        return None
    template = cv2.imread(path, cv2.IMREAD_COLOR)
    if template is None or img.shape[0] < template.shape[0] or img.shape[1] < template.shape[1]:
        return None
    result = cv2.matchTemplate(img, template, cv2.TM_CCOEFF_NORMED)
    _, value, _, loc = cv2.minMaxLoc(result)
    if value < threshold:
        return None
    h, w = template.shape[:2]
    return loc[0], loc[1], w, h, value


def click_point(win, cx, cy, name):
    if not (win.left <= cx < win.left + win.width and win.top <= cy < win.top + win.height):
        log(f"Blocked unsafe click: {name}")
        return False
    try:
        if not win.isActive:
            win.activate()
            time.sleep(0.1)
    except Exception:
        pass
    pyautogui.click(int(cx), int(cy))
    log(f"Clicked {name} at ({int(cx)}, {int(cy)})")
    return True


def click_hit(win, hit, name):
    x, y, w, h, confidence = hit
    return click_point(win, win.left + x + w / 2, win.top + y + h / 2, name)


def find_non_clear_number_click(win, img):
    """Locate the complete 246x168 non-clear quest block and click its number.

    The supplied non_clear.png is a visual anchor for the entire quest block.
    We use its yellow graphic only to locate the hexagon, then click the fixed
    number position below that hexagon. This avoids guessing from unrelated
    yellow shapes elsewhere on the screen.
    """
    hit = match("non_clear.png", img, 0.82)
    if not hit:
        return False

    tx, ty, tw, th, confidence = hit
    # The user's asset is 246x168. The number is directly below the hexagon
    # in the captured block, so use the block-relative point rather than a
    # contour-derived offset that can jump to an arrow.
    # Center of the number area: lower-middle portion of the supplied block.
    click_x = tx + tw * 0.50
    click_y = ty + th * 0.82

    return click_point(win, win.left + click_x, win.top + click_y,
                       f"non_clear number ({confidence:.3f})")


def run():
    log("Continuous detection mode")
    log("Back check: every 40s; normal clicks reset it")
    log("Non-clear quest: detected block -> click number")
    last_click = {}
    last_back_check = 0.0
    non_clear_cooldown = 0.0

    with mss() as sct:
        while not STOP:
            win = get_window()
            if not win:
                time.sleep(POLL)
                continue
            img = screenshot(win, sct)
            if img is None:
                time.sleep(POLL)
                continue

            now = time.time()
            normal_clicked = False

            for name, threshold in WATCH:
                if now - last_click.get(name, 0) < 0.8:
                    continue
                hit = match(name, img, threshold)
                if hit and click_hit(win, hit, name):
                    last_click[name] = now
                    normal_clicked = True
                    time.sleep(0.1)

            if now >= non_clear_cooldown:
                if find_non_clear_number_click(win, img):
                    non_clear_cooldown = now + 3.0
                    normal_clicked = True

            if normal_clicked:
                last_back_check = now
            elif now - last_back_check >= BACK_INTERVAL:
                last_back_check = now
                hit = match("back.png", img, 0.80)
                if hit:
                    click_hit(win, hit, "back.png")

            time.sleep(POLL)


def stop():
    global STOP
    STOP = True
    log("Stopped")


def main():
    log("F6 = start | F9 = stop")
    keyboard.add_hotkey("f9", stop)
    keyboard.wait("f6")
    run()


if __name__ == "__main__":
    main()
