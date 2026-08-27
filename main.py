import os
import sys
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
    if not wins:
        return None
    # Prefer the largest visible matching window.
    return max(wins, key=lambda w: w.width * w.height)


def screenshot(win):
    if win is None or win.width <= 0 or win.height <= 0:
        return None
    with mss() as sct:
        shot = sct.grab({
            "left": int(win.left),
            "top": int(win.top),
            "width": int(win.width),
            "height": int(win.height),
        })
    return cv2.cvtColor(np.array(shot), cv2.COLOR_BGRA2BGR)


def match(name, img, threshold=THRESHOLD):
    path = os.path.join(ASSET_DIR, name)
    if not os.path.exists(path) or img is None:
        return None
    template = cv2.imread(path, cv2.IMREAD_COLOR)
    if template is None:
        return None
    h, w = template.shape[:2]
    if img.shape[0] < h or img.shape[1] < w:
        return None
    result = cv2.matchTemplate(img, template, cv2.TM_CCOEFF_NORMED)
    _, value, _, loc = cv2.minMaxLoc(result)
    if value < threshold:
        return None
    return loc[0], loc[1], w, h, value


def click_image(name, img=None, threshold=THRESHOLD):
    win = get_window()
    if win is None:
        log("BBS window not found")
        return False
    if img is None:
        img = screenshot(win)
    hit = match(name, img, threshold)
    if hit is None:
        return False

    x, y, w, h, confidence = hit
    # Johnny's method: template coordinates are relative to the captured BBS
    # window, then translated once to absolute screen coordinates.
    cx = int(win.left + x + w / 2)
    cy = int(win.top + y + h / 2)

    # Never allow a click outside the actual BBS window.
    if not (win.left <= cx < win.left + win.width and win.top <= cy < win.top + win.height):
        log(f"Blocked unsafe click for {name}: {cx},{cy}")
        return False

    try:
        if not win.isActive:
            win.activate()
            time.sleep(0.15)
    except Exception:
        pass

    pyautogui.click(cx, cy)
    log(f"Clicked {name} ({confidence:.3f})")
    return True


def wait_and_click(name, timeout=15, threshold=THRESHOLD):
    end = time.time() + timeout
    while time.time() < end and not STOP.is_set():
        win = get_window()
        img = screenshot(win) if win else None
        if click_image(name, img, threshold):
            return True
        time.sleep(POLL)
    return False


def run_story():
    log("Story farmer started")
    log("Expected starting screen: Prepare for Quest")

    while not STOP.is_set():
        # 1. Story screen -> Prepare for Quest
        if wait_and_click("prepare_for_quest.png", timeout=20):
            time.sleep(1)
        else:
            log("Prepare for Quest not found - waiting")
            time.sleep(1)
            continue

        # 2. Party screen -> Start Quest
        if not wait_and_click("start_quest.png", timeout=20):
            log("Start Quest not found")
            continue
        time.sleep(1)

        # 3. Confirmation / ticket dialog
        click_image("ok.png")
        time.sleep(1)
        click_image("skip.png")

        # 4. Wait for gameplay, then wait for the clear/end screen.
        gameplay_seen = False
        end_deadline = time.time() + 240
        while time.time() < end_deadline and not STOP.is_set():
            win = get_window()
            img = screenshot(win) if win else None
            if match("pause.png", img, 0.85):
                gameplay_seen = True
                time.sleep(3)
                continue
            if gameplay_seen:
                if click_image("quest_clear.png", img, 0.80):
                    log("Quest cleared")
                    time.sleep(1)
                    break
                if click_image("next_quest.png.png", img, 0.80):
                    log("Next quest")
                    time.sleep(1)
                    break
                if click_image("close.png", img, 0.80):
                    time.sleep(1)
                    break
            time.sleep(POLL)

        time.sleep(2)


def main():
    log("Python BBS-AHK farmer")
    log("F6 = start Story | F9 = stop")
    keyboard.add_hotkey("f9", STOP.set)

    started = threading.Event()

    def start():
        if started.is_set():
            return
        started.set()
        try:
            run_story()
        finally:
            STOP.set()

    keyboard.add_hotkey("f6", start)
    keyboard.wait("f9")
    STOP.set()
    log("Stopped")


if __name__ == "__main__":
    main()
