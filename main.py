import os
import time
import threading

import cv2
import numpy as np
import pyautogui
import pygetwindow as gw
import keyboard
from mss import mss

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ASSET_DIR = os.path.join(BASE_DIR, "assets", "icons")
WINDOW_TITLE = "Bleach: Brave Souls"
THRESHOLD = 0.85
POLL = 0.5
STOP = threading.Event()


def log(msg):
    print(f"[BBS] {msg}", flush=True)


def get_window():
    wins = [w for w in gw.getWindowsWithTitle(WINDOW_TITLE) if w.width > 0 and w.height > 0]
    return max(wins, key=lambda w: w.width * w.height) if wins else None


def screenshot(win):
    if not win or win.width <= 0 or win.height <= 0:
        return None
    with mss() as sct:
        shot = sct.grab({"left": int(win.left), "top": int(win.top), "width": int(win.width), "height": int(win.height)})
    return cv2.cvtColor(np.array(shot), cv2.COLOR_BGRA2BGR)


def match(name, img, threshold=THRESHOLD):
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


def click_image(name, img=None, threshold=THRESHOLD):
    win = get_window()
    if not win:
        return False
    if img is None:
        img = screenshot(win)
    hit = match(name, img, threshold)
    if not hit:
        return False

    x, y, w, h, confidence = hit
    cx = int(win.left + x + w / 2)
    cy = int(win.top + y + h / 2)

    # Refuse any click outside the BBS window.
    if not (win.left <= cx < win.left + win.width and win.top <= cy < win.top + win.height):
        log(f"Blocked unsafe click: {name}")
        return False

    try:
        if not win.isActive:
            win.activate()
            time.sleep(0.2)
    except Exception:
        pass

    pyautogui.click(cx, cy)
    log(f"Clicked {name} ({confidence:.3f})")
    return True


def wait_and_click(name, timeout=20, threshold=THRESHOLD):
    deadline = time.time() + timeout
    while time.time() < deadline and not STOP.is_set():
        win = get_window()
        img = screenshot(win) if win else None
        if click_image(name, img, threshold):
            return True
        time.sleep(POLL)
    return False


def run_story():
    log("Story farmer started")
    while not STOP.is_set():
        # Story quest screen -> party screen
        if not wait_and_click("prepare_for_quest.png", 20):
            log("Prepare for Quest not found - waiting")
            continue
        time.sleep(1)

        # Party screen -> start quest
        if not wait_and_click("start_quest.png", 20):
            log("Start Quest not found - retrying")
            continue
        time.sleep(1)

        # Confirmation/ticket screen
        wait_and_click("ok.png", 3, 0.80)
        wait_and_click("skip.png", 2, 0.80)

        gameplay_seen = False
        deadline = time.time() + 240
        while time.time() < deadline and not STOP.is_set():
            win = get_window()
            img = screenshot(win) if win else None
            if match("pause.png", img, 0.85):
                gameplay_seen = True
                time.sleep(3)
                continue
            if gameplay_seen:
                if click_image("tap_screen.png", img, 0.80):
                    time.sleep(0.5)
                    continue
                if click_image("quest_clear.png", img, 0.80):
                    log("Quest cleared")
                    time.sleep(1)
                    break
                if click_image("cancel.png", img, 0.80):
                    time.sleep(1)
                    break
                if click_image("next_quest.png.png", img, 0.80):
                    time.sleep(1)
                    break
                if click_image("close.png", img, 0.80):
                    time.sleep(1)
                    break
            time.sleep(POLL)
        time.sleep(2)


def main():
    log("Python Story farmer")
    log("F6 = start | F9 = stop")
    keyboard.add_hotkey("f9", STOP.set)

    def start():
        if not STOP.is_set():
            run_story()

    keyboard.add_hotkey("f6", start)
    keyboard.wait("f9")


if __name__ == "__main__":
    main()
