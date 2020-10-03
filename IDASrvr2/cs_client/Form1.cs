using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace cs_client
{
    public partial class Form1 : Form
    {
        private ida_client ida = null;

        public Form1()
        {
            InitializeComponent();
        }

        protected override void WndProc(ref Message m)
        {
            if (ida == null)
            {
                base.WndProc(ref m);
            }
            else
            {
                if (!ida.HandleWindowProc(ref m)) base.WndProc(ref m);
            }
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            listBox1.Items.Add("Listener hwnd: " + this.Handle);
            ida = new ida_client(this.Handle);

            List<uint> servers = ida.FindServers();
            listBox1.Items.Add("Found " + servers.Count + " IDA server windows");

            foreach (uint hwnd in servers)
            {
                ida.IDA_HWND = (int)hwnd; //set which remote client to use..
                listBox1.Items.Add("hwnd: " + hwnd + " idb: " + ida.LoadedFileName());
            }

            if (!ida.LastIDAHwndToOpen()) //automatically sets active IDA_HWND
            {
                listBox1.Items.Add("IDA Server window not found...");
                return;
            }

            listBox1.Items.Add("");
            listBox1.Items.Add("Last IDA Hwnd To Open: " + ida.IDA_HWND);
            listBox1.Items.Add("File: " + ida.LoadedFileName() ) ;
            listBox1.Items.Add("#Funcs: " + ida.FuncCount());

            int fStart = ida.FuncStart(1);
            listBox1.Items.Add("Func[1] start: " + fStart.ToString("X") );
            listBox1.Items.Add("Func[1] end: " + ida.FuncEnd(1).ToString("X") );
            listBox1.Items.Add("Disasm @ 0x" + fStart.ToString("X") + ": " + ida.GetAsm(fStart));
          
        }

        private void Form1_Resize(object sender, EventArgs e)
        {
            try
            {
                listBox1.Width = this.Width - listBox1.Left - 20;
            }
            catch (Exception ex) { }
        }
    }
}