import os
import time
import cv2
import numpy as np
import pyautogui
import pygetwindow as gw
import keyboard
from mss import mss
BASE_DIR=os.path.dirname(os.path.abspath(__file__))
ASSET_DIR=os.path.join(BASE_DIR,"assets","icons")
WINDOW_TITLE="Bleach: Brave Souls"
POLL=.35
BACK_INTERVAL=40.0
STOP=False
WATCH=[("prepare_for_quest.png",.85),("start_quest.png",.85),("ok.png",.80),("skip.png",.80),("tap_screen.png",.80),("cancel.png",.80),("skin.png",.80),("next_quest.png",.65),("close.png",.80)]
def log(msg): print(f"[BBS] {msg}",flush=True)
def get_window():
    wins=[w for w in gw.getWindowsWithTitle(WINDOW_TITLE) if w.width>0 and w.height>0]; return max(wins,key=lambda w:w.width*w.height) if wins else None
def screenshot(win,sct):
    try:
        shot=sct.grab({"left":int(win.left),"top":int(win.top),"width":int(win.width),"height":int(win.height)}); return cv2.cvtColor(np.array(shot),cv2.COLOR_BGRA2BGR)
    except Exception:return None
def match(name,img,threshold):
    path=os.path.join(ASSET_DIR,name)
    if img is None or not os.path.exists(path):return None
    template=cv2.imread(path,cv2.IMREAD_COLOR)
    if template is None or img.shape[0]<template.shape[0] or img.shape[1]<template.shape[1]:return None
    result=cv2.matchTemplate(img,template,cv2.TM_CCOEFF_NORMED); _,value,_,loc=cv2.minMaxLoc(result)
    if value<threshold:return None
    h,w=template.shape[:2]; return loc[0],loc[1],w,h,value
def click_point(win,cx,cy,name):
    if not(win.left<=cx<win.left+win.width and win.top<=cy<win.top+win.height):return False
    try:
        if not win.isActive:win.activate();time.sleep(.1)
    except Exception:pass
    pyautogui.click(int(cx),int(cy));log(f"Clicked {name} at ({int(cx)}, {int(cy)})");return True
def click_hit(win,hit,name):
    x,y,w,h,_=hit; return click_point(win,win.left+x+w/2,win.top+y+h/2,name)
def find_non_clear_number_click(win,img):
    hit=match("non_clear.png",img,.82)
    if not hit:return False
    tx,ty,tw,th,confidence=hit; return click_point(win,win.left+tx+tw*.50,win.top+ty+th*.61,f"non_clear target ({confidence:.3f})")
def run():
    log("Continuous detection mode")
    last_click={}; last_back_check=time.time(); non_clear_cooldown=0.; quest_clear_cooldown=0.; story_cooldown=0.
    with mss() as sct:
        while not STOP:
            win=get_window()
            if not win:time.sleep(POLL);continue
            img=screenshot(win,sct)
            if img is None:time.sleep(POLL);continue
            now=time.time();normal_clicked=False
            if now>=quest_clear_cooldown:
                hit=match("quest_clear.png",img,.80)
                if hit and click_point(win,win.left+win.width*.50,win.top+win.height*.50,"quest_clear trigger"):
                    quest_clear_cooldown=now+1.;normal_clicked=True
            # Story button is independent from normal.png. Use its full template as the click target.
            if now>=story_cooldown:
                hit=match("normal_story.png",img,.65)
                if hit:
                    x,y,w,h,_=hit
                    # The supplied normal_story template includes NORMAL and 0%; click in its lower portion.
                    if click_point(win,win.left+x+w*.50,win.top+y+h*.78,"normal_story 0%"):
                        story_cooldown=now+1.;normal_clicked=True;time.sleep(.1)
            # normal.png is only a guard for next_quest.
            normal_hit=match("normal.png",img,.80)
            for name,threshold in WATCH:
                if now-last_click.get(name,0)<.8:continue
                if name=="next_quest.png" and normal_hit:continue
                hit=match(name,img,threshold)
                if hit and click_hit(win,hit,name):last_click[name]=now;normal_clicked=True;time.sleep(.1)
            if now>=non_clear_cooldown and find_non_clear_number_click(win,img):
                non_clear_cooldown=now+.8;normal_clicked=True
            if normal_clicked:last_back_check=now
            elif now-last_back_check>=BACK_INTERVAL:
                last_back_check=now;hit=match("back.png",img,.80)
                if hit:click_hit(win,hit,"back.png")
            time.sleep(POLL)
def stop():
    global STOP;STOP=True;log("Stopped")
def main():
    log("F6 = start | F9 = stop");keyboard.add_hotkey("f9",stop);keyboard.wait("f6");run()
if __name__=="__main__":main()
