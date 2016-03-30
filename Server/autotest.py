import sys
#import local pyautogui
sys.path.append("./pyautogui")

import pyautogui
import time

pyautogui.PAUSE = 0

def test():
    time.sleep(1)
    pyautogui.moveRel(1,1)
    #time.sleep(1)
    #pyautogui.click()
    #time.sleep(1)
    #pyautogui.mouseDown()
    time.sleep(1)
    
    '''
    button = 'left'
    mouseDownUp = False
    
    
    if ~mouseDownUp:
        pyautogui.mouseDown(button=button, _pause=False)
    
    for i in range(0,50):
        if (i > 25):
            pyautogui.dragRel(-1 * (i-25),0, button=button, mouseDownUp=mouseDownUp)
        else:
            pyautogui.dragRel( 1 * i,0, button=button, mouseDownUp=mouseDownUp)

    if ~mouseDownUp:
        pyautogui.mouseUp(button=button, _pause=False)
    '''

print "double"
pyautogui.doubleClick();
time.sleep(1)
print "triple"
pyautogui.tripleClick();
