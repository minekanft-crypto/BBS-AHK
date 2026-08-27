import os
import time
import re
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
    """Find the yellow quest marker from non_clear.png and click the number below it.

    The template is only used to locate the correct quest block. Inside that block,
    yellow pixels identify the arrow/hexagon graphic. The compact yellow component
    (the hexagon) is used as the anchor; the click is deliberately below it, where
    the story number sits. No story number is hard-coded.
    """
    hit = match("non_clear.png", img, 0.72)
    if not hit:
        return False

    tx, ty, tw, th, confidence = hit
    crop = img[ty:ty + th, tx:tx + tw]
    if crop.size == 0:
        return False

    hsv = cv2.cvtColor(crop, cv2.COLOR_BGR2HSV)
    # Broad BBS yellow range; arrows and the yellow hexagon are both captured.
    mask = cv2.inRange(hsv, np.array([15, 80, 100], dtype=np.uint8), np.array([45, 255, 255], dtype=np.uint8))
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))

    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    candidates = []
    for contour in contours:
        x, y, w, h = cv2.boundingRect(contour)
        area = cv2.contourArea(contour)
        if area < 20 or w < 6 or h < 6:
            continue
        # Prefer compact, roughly polygon-sized yellow regions over long arrows.
        ratio = w / max(h, 1)
        compact = min(ratio, 1.0 / ratio) if ratio else 0
        if 0.55 <= ratio <= 1.8 and area >= 80 and compact >= 0.55:
            candidates.append((area, x, y, w, h))

    if not candidates:
        return False

    # The hexagon is normally the largest compact yellow component in the block.
    _, x, y, w, h = max(candidates, key=lambda item: item[0])
    hex_cx = x + w / 2
    hex_bottom = y + h

    # Number is directly underneath the hexagon. Keep the x aligned with the marker.
    click_x = tx + hex_cx
    click_y = ty + hex_bottom + max(4, int(h * 0.55))

    # Stay inside the matched block; this prevents clicking elsewhere if the asset
    # is unexpectedly cropped.
    if not (0 <= click_x <= img.shape[1] and 0 <= click_y <= img.shape[0]):
        return False
    return click_point(win, win.left + click_x, win.top + click_y, f"non_clear number ({confidence:.3f})")


def run():
    log("Continuous detection mode")
    log("Back check: every 40s; normal clicks reset it")
    log("Non-clear quest: yellow marker -> click number below hexagon")
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

            # Every normal asset is watched continuously; there is no fixed flow order.
            for name, threshold in WATCH:
                if now - last_click.get(name, 0) < 0.8:
                    continue
                hit = match(name, img, threshold)
                if hit and click_hit(win, hit, name):
                    last_click[name] = now
                    normal_clicked = True
                    time.sleep(0.1)

            # Non-clear is special: locate its yellow arrows/hexagon and click only
            # the story number underneath the yellow hexagon.
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
