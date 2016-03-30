# Mouser
iOS device as mouse/touchpad

## Setup

- Download and install `Twisted`, `pyobjc-core` and `pyobjc` 
``` 
$ wget http://twistedmatrix.com/trac/wiki/Downloads 
$ wget https://pypi.python.org/packages/source/p/pyobjc-core/pyobjc-core-3.0.4.tar.gz
$ wget https://pypi.python.org/packages/source/p/pyobjc/pyobjc-3.0.4.tar.gz
...
$ cd <dir>
$ sudo python setup.py install
```
- Clone this repository
```
$ git clone https://github.com/HesselM/Mouser.git
```
- Inside the server directory, clone the patched `pyautogui` repo
```
$ cd Mouser/Server
$ git clone https://github.com/HesselM/pyautogui.git
```
- Start server handler (in `Server` folder)
```
python mouser.py
```
- Upload app to iOS device, set appropiate ip-address and off you go!
