import win32con, win32api, win32gui, ctypes, ctypes.wintypes, sys, struct
from array import array
import _winreg as wreg

try:
    from idautils import *
    from idaapi import *
    from idc import *
    print "PIDASrvr is running in ida..."
except:
    print "ok not running in ida but can still experiment with eval/exec/reply/shutdown commands..."

# pip install pypiwin32

WM_DISPLAY_TEXT = 3
lastHWND = 0
debugLevel = 1
    
class COPYDATASTRUCT(ctypes.Structure):
    _fields_ = [
        ('dwData', ctypes.wintypes.LPARAM),
        ('cbData', ctypes.wintypes.DWORD),
        ('lpData', ctypes.c_void_p)
    ]
PCOPYDATASTRUCT = ctypes.POINTER(COPYDATASTRUCT)

def registerServer(h):
    key = wreg.CreateKey(wreg.HKEY_CURRENT_USER, "Software\\VB and VBA Program Settings\\IPC\\Handles")
    wreg.SetValueEx(key, 'PIDA_SERVER', 0, wreg.REG_SZ, str(h))
    key.Close()     
    
def chunkString(s,sz=1000):
    o = []
    while s:
        o.append(s[:sz])
        s = s[sz:]
    return o

def __sendData(w,message):
    CopyDataStruct = "IIP"
    char_buffer = array('c', str(message))
    char_buffer_address = char_buffer.buffer_info()[0]
    char_buffer_size = char_buffer.buffer_info()[1]
    cds = struct.pack(CopyDataStruct, WM_DISPLAY_TEXT, char_buffer_size, char_buffer_address)
    v = win32gui.SendMessage(int(w), win32con.WM_COPYDATA, 0, cds)    

def sendCommand(w, message):
    print "sending msg '%s' to %s" % (message, w)
    isWindow = win32gui.IsWindow(int(w))
    
    if isWindow != 1:
        print "not a valid hwnd"
        return
    
    if len(message) > 1000:
        chunks = chunkString(message)
        __sendData(w,"=CHUNKED=")
        for c in chunks:
            __sendData(w,c)
        __sendData(w,"=CHUNKED_COMPLETE=")
    else:
        __sendData(w,message)

    #print "done retval = %d" % v
    
#for use in exec scripts to return a value...    
def reply(msg):
    global lastHWND
    #print "reply arg type = " + type(msg)
    sendCommand(lastHWND, str(msg))
    
def recvCommand(msg):
    global lastHWND
    if debugLevel > 1: print "in recvCommand: %s" % msg
    handled = 0
    
    ary = msg.split(":") #expected format is command_id:hwnd:arguments
    if len(ary) == 3: 
        lastHWND = int(ary[1])
        if ary[0] == "EVAL": 
            try:
                ret = str(eval(ary[2]))
                sendCommand(lastHWND,ret)
            except:
                sendCommand(lastHWND,"ERROR:"+str(sys.exc_info()))            
            handled = 1
        if ary[0] == "EXEC":  
            try:
                exec ary[2] 
                sendCommand(lastHWND,"OK")
            except:
                sendCommand(lastHWND,"ERROR:"+str(sys.exc_info()))
            handled = 1  
            
    if handled == 0:
        print "unknown command"
    
class Listener:
    # https://stackoverflow.com/questions/5249903/receiving-wm-copydata-in-python   
    def __init__(self):
   
        self.PYIDA_QUICKCALL_MESSAGE     = win32gui.RegisterWindowMessage("PYIDA_QUICKCALL")
        self.PYIDASRVR_BROADCAST_MESSAGE = win32gui.RegisterWindowMessage("PYIDA_SERVER")
        if debugLevel > 1: print "QuickCall: %x BroadCast: %x" % (self.PYIDA_QUICKCALL_MESSAGE, self.PYIDASRVR_BROADCAST_MESSAGE)
        
        message_map = {
            self.PYIDA_QUICKCALL_MESSAGE:      self.OnQuickCall,
            self.PYIDASRVR_BROADCAST_MESSAGE:  self.OnBroadcast,
            win32con.WM_COPYDATA:              self.OnCopyData,
        }
        
        wc = win32gui.WNDCLASS()
        wc.lpfnWndProc = message_map
        wc.lpszClassName = 'MyWindowClass'
        hinst = wc.hInstance = win32api.GetModuleHandle(None)
        self.classAtom = win32gui.RegisterClass(wc)
        
        self.hwnd = win32gui.CreateWindow (
            self.classAtom,
            "win32gui test",
            0,
            0, 
            0,
            win32con.CW_USEDEFAULT, 
            win32con.CW_USEDEFAULT,
            0, 
            0,
            hinst, 
            None
        )
        
        registerServer(self.hwnd)
        print "Python listening for WM_COPYDATA on hwnd = %d" % self.hwnd
        
    def OnCopyData(self, hwnd, msg, wparam, lparam):
        if debugLevel > 1: print "Copy data msg received! hwnd=%d msg=0x%x wparam=0x%x lparam=0x%x" % (hwnd,msg,wparam,lparam)
        pCDS = ctypes.cast(lparam, PCOPYDATASTRUCT)
        if pCDS.contents.dwData != WM_DISPLAY_TEXT:
            print "Not WM_DISPLAY_TEXT dwData=%d cbData=0x%x lpData=0x%x" % (pCDS.contents.dwData,pCDS.contents.cbData,pCDS.contents.lpData)
            return
        
        if debugLevel > 1: print "WM_DISPLAY_TEXT received cbData=0x%x lpData=0x%x" % (pCDS.contents.cbData,pCDS.contents.lpData)
        msg = ctypes.string_at(pCDS.contents.lpData)
        if msg=="SHUTDOWN": 
            self.Shutdown()
            return 1       
        recvCommand(msg)
        return 1

    # so our controller can broadcast a message and have each PyIda instance identify itself
    def OnBroadcast(self, hwnd, msg, wparam, lparam):
        print "PyIDA Broadcast Message received"
        win32gui.SendMessage(wparam, self.PYIDASRVR_BROADCAST_MESSAGE, 0, self.hwnd);
        
    # 3x performance bump - limits: wparam = function id, lparam = optional 32bit arg, optional 32bit ret val
    def OnQuickCall(self, hwnd, msg, wparam, lparam):
        print "QuickCall received funcID: %d, arg0: %d" % (wparam,lparam)
        # todo: handle wparam functionID we just return a static value for testing
        return 0xDEADBEEF
        
    def Shutdown(self):
        print "shutting down message pump window.."
        #win32gui.SendMessage(self.hwnd, win32con.WM_QUIT, 0, 0)  
        ctypes.windll.user32.PostQuitMessage(0)
        win32gui.DestroyWindow(self.hwnd)
        win32gui.UnregisterClass(self.classAtom,None)

l = Listener()
win32gui.PumpMessages()        
print "PIDAServer stopped..." 

