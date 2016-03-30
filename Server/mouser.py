import sys
#import local pyautogui
sys.path.append("./pyautogui")

from twisted.internet.protocol import Protocol, Factory
from twisted.internet import reactor
import pyautogui
import time

class Mouser(Protocol):
    dragActive  = False
    dragStarted = False;
    
    def connectionMade(self):
        #self.transport.write("""connected""")
        self.factory.clients.append(self)
        print "clients are ", self.factory.clients
    
    def connectionLost(self, reason):
        self.factory.clients.remove(self)
    
    def dataReceived(self, data):
        #fetch commands from data
        cmds = data.split(';');
        
        #exec each command
        for cmd in cmds:
            
            # cmd = object : action < :param < :param < :param ... >>>
            # each cmd contains atleast 'object' & 'action'
            splitted = cmd.split(':');
            
            #invalid cmd?
            if (len(splitted)<2):
                continue
            
            #number of params
            params   = len(splitted)-2

            obj = splitted[0]
            act = splitted[1]
            
            if obj == "mouse":   
                
                if act == "click":
                    if params == 0:
                        pyautogui.click()
                    
                    #click provided a parameter: number of clicks!
                    elif params == 1:
                        clicks = int(float(splitted[2]))
                        pyautogui.click(clicks=clicks)
            
                elif act == "doubleclick":
                    pyautogui.doubleClick()

                elif act == "tripleclick":
                    pyautogui.tripleClick()
                                    
                elif act == "rightclick":
                    pyautogui.rightClick()
                
                elif act == "scroll":
                    if params == 2:
                        x = int(float(splitted[2]))
                        y = int(float(splitted[3]))
                        pyautogui.hscroll(x);
                        pyautogui.vscroll(y);
                                    
                elif act == "drag":
                    if params == 1:
                        # indicate that dragging is activated, but not yet started
                        if splitted[2] == "start":
                            self.dragActive = True
                        # indicate that dragging in disactivated
                        elif splitted[2] == "end":
                            self.dragActive = False
                            #stop dragging when active
                            if self.dragStarted:
                                self.dragStarted = False
                                pyautogui.mouseUp()
                        else:
                            print "Unknown value for 'drag':" + splitted[2]

                    elif params == 2:
                        #are we already dragging?
                        if not self.dragStarted:
                            self.dragStarted = True
                            pyautogui.mouseDown()
                        
                        #fetch x/y movement
                        x = int(float(splitted[2]))
                        y = int(float(splitted[3]))
                        pyautogui.dragRel(x,y, mouseDownUp=False)
 
                                    
                elif act == "move":
                    if params == 2:
                        #fetch x/y movement
                        x = int(float(splitted[2]))
                        y = int(float(splitted[3]))
                        
                        #are we dragging?
                        pyautogui.moveRel(x,y)
                            

            elif obj == "key":
                key = splitted[2]
                print("keypress:" + act + " key:" + key)
                if (act == "press"):
                    pyautogui.press(key)
                elif (act == "down"):
                    pyautogui.keyDown(key)
                elif (act == "up"):
                    pyautogui.keyUp(key)




factory = Factory()
factory.protocol = Mouser
factory.clients = []

pyautogui.PAUSE = 0.0
reactor.listenTCP(4376, factory)
print "Mouser server started"
reactor.run()

