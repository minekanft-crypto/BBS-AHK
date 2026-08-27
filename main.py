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
BACK_RESET_AFTER_CLICK = 20.0
STOP = False

WATCH = [
    ("prepare_for_quest.png", 0.85),
    ("start_quest.png", 0.85),
    ("ok.png", 0.80),
    ("skip.png", 0.80),
    ("tap_screen.png", 0.80),
    ("cancel.png", 0.80),
    ("skin.png", 0.80),
    ("quest_clear.png", 0.80),
    ("next_quest.png.png", 0.65),
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


def click_hit(win, hit, name):
    x, y, w, h, confidence = hit
    cx = int(win.left + x + w / 2)
    cy = int(win.top + y + h / 2)
    if not (win.left <= cx < win.left + win.width and win.top <= cy < win.top + win.height):
        log(f"Blocked unsafe click: {name}")
        return False
    try:
        if not win.isActive:
            win.activate()
            time.sleep(0.1)
    except Exception:
        pass
    pyautogui.click(cx, cy)
    log(f"Clicked {name} ({confidence:.3f})")
    return True


def run():
    log("Continuous detection mode")
    log("Back check: every 40s, reset by any normal button click within 20s")
    last_click = {}
    last_back_check = 0.0
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
                    last_click[name] = time.time()
                    normal_clicked = True
                    time.sleep(0.1)

            # Any normal button click means the UI is still progressing, so
            # postpone the low-frequency Back safety check for another 40s.
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
