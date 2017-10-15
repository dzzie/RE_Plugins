using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Security.Permissions;
using Microsoft.Win32;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;
[assembly: RegistryPermissionAttribute(SecurityAction.RequestMinimum, All = "HKEY_CURRENT_USER")]

namespace cs_client
{
    //this is just a quick demo of interacting with IDASrvr from C# 
    class ida_client
    {
        private const int WM_COPYDATA = 0x004A;
        private string ResponseBuffer="";
        public int IDA_HWND = 0;
        private int MY_HWND = 0;
        private uint IDASRVR_BROADCAST_MESSAGE = 0;
        public Dictionary<uint, uint> Servers = new Dictionary<uint, uint>();

        public ida_client(IntPtr listen_hwnd)
        {
            MY_HWND = (int)listen_hwnd;
            IDASRVR_BROADCAST_MESSAGE = RegisterWindowMessage("IDA_SERVER");
        }

        private struct CopyDataStruct : IDisposable
        {
            public IntPtr dwData;
            public int cbData;
            public IntPtr lpData;

            public void Dispose()
            {
                if (this.lpData != IntPtr.Zero)
                {
                    LocalFree(this.lpData);
                    this.lpData = IntPtr.Zero;
                }
            }
        }

        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        static extern uint RegisterWindowMessage(string lpString);
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        static extern bool IsWindow(IntPtr hWnd);
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern IntPtr SendMessageTimeout(uint hWnd, uint Msg, uint wParam, uint lParam, uint fuFlags, uint uTimeout, out uint lpdwResult);

        [DllImport("User32.dll")]
        private static extern Int32 SendMessage(int hWnd, int Msg, int wParam, [MarshalAs(UnmanagedType.LPStr)] string lParam);
        [DllImport("User32.dll")]
        private static extern Int32 SendMessage(int hWnd, int Msg, int wParam, int lParam);
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        private static extern int SendMessage(int hWnd, int msg, int wParam, IntPtr lParam);
        [DllImport("user32.dll")]
        private static extern int SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, ref CopyDataStruct lParam);
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr LocalFree(IntPtr p);
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr LocalAlloc(int flag, int size);
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool IsWindow(int hWnd);

        private bool SendCmd(string args)
        {
            ResponseBuffer = "";
            byte[] bytes;
            CopyDataStruct cds = new CopyDataStruct();

            bytes = System.Text.Encoding.ASCII.GetBytes(args + "\x00");

            try
            {
                cds.cbData = bytes.Length;
                cds.lpData = LocalAlloc(0x40, cds.cbData);
                Marshal.Copy(bytes, 0, cds.lpData, bytes.Length);
                cds.dwData = (IntPtr)3;
                SendMessage((IntPtr)IDA_HWND, WM_COPYDATA, IntPtr.Zero, ref cds);
            }
            finally
            {
                cds.Dispose();
            }

            return true;
        }

        public bool HandleWindowProc(ref Message m){

            if (m.Msg == IDASRVR_BROADCAST_MESSAGE)
            {
                if (IsWindow(m.LParam))
                {
                    if(!ServerExists((uint)m.LParam))
                    {
                        Servers.Add((uint)m.LParam, (uint)m.LParam);
                    }
                }
            }
            
            if(m.Msg != WM_COPYDATA) return false;
            CopyDataStruct st = (CopyDataStruct)Marshal.PtrToStructure(m.LParam, typeof(CopyDataStruct));
            if((int)st.dwData != 3) return false;
            string strData = Marshal.PtrToStringAnsi(st.lpData);
            if(st.cbData < strData.Length) strData = strData.Substring(0, st.cbData);
            ResponseBuffer = strData;
            return true;
        }

        public List<uint> FindServers()
        {
            List<uint> ret = new List<uint>();
            
            uint r = 0;
            uint HWND_BROADCAST = 0xFFFF;
            SendMessageTimeout( HWND_BROADCAST, IDASRVR_BROADCAST_MESSAGE, (uint)MY_HWND, 0, 0, 1000, out r);

            /*
             so a client starts up, it gets the message to use (system wide) and it broadcasts a message to all windows
             looking for IDASrvr instances that are active. It passes its command window hwnd as wParam
             IDASrvr windows will receive this, and respond to the HWND with the same IDASRVR message as a pingback
             sending thier command window hwnd as the lParam to register themselves with the clients.
             clients track these hwnds.
            */

            foreach (uint hwnd in Servers.Values)
            {
                if (IsWindow((int)hwnd))
                {
                    ret.Add(hwnd);
                }
                else
                {
                    Servers.Remove(hwnd);
                }
            }

            return ret;
        }

        private bool ServerExists(uint hwnd)
        {
            try
            {
                uint h = Servers[hwnd];
                return h != 0 ? true : false;
            }
            catch (Exception e) { return false; }
        }

        private string ReceiveText(string cmd)
        {
            SendCmd(cmd);
            return ResponseBuffer;
        }

        private int ReceiveInt(string cmd)
        {
            SendCmd(cmd);
            return Convert.ToInt32(ResponseBuffer);
        }

        public bool LastIDAHwndToOpen()
        {
            RegistryKey ida = Registry.CurrentUser.OpenSubKey("Software\\VB and VBA Program Settings\\IPC\\Handles");
            IDA_HWND = Convert.ToInt32(ida.GetValue("IDA_SERVER"));
            if(!IsWindow(IDA_HWND)) IDA_HWND = 0;
            return IDA_HWND != 0 ? true : false;
        }

        public string LoadedFileName(){
            return  ReceiveText("loadedfile:" + MY_HWND);
        }

        public int FuncCount()
        {
            return ReceiveInt("numfuncs:" + MY_HWND);
        }

        public int FuncStart(int index)
        {
            return ReceiveInt("funcstart:" + index + ":" + MY_HWND);
        }

        public int FuncEnd(int index)
        {
            return ReceiveInt("funcend:" + index + ":" + MY_HWND);
        }

        public string GetAsm(int va)
        {
            return ReceiveText("getasm:" + va + ":" + MY_HWND);
        }




    }

}
