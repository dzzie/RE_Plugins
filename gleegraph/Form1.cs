using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using Microsoft.Glee.Drawing;
using System.Threading;
using System.IO;
using System.Diagnostics;
using System.Collections;
using ListViewSorter;

namespace gleeGraph
{
    public partial class Form1 : Form
    {
        CGraph graph;
        Node selNode;
        Node mouseOverNode;
        ida_client ida = null;
        ListViewColumnSorter lvSorter;

        public void debugLog(string msg){
            lst.Items.Add(msg);
            lst.SelectedIndex = lst.Items.Count-1;
        }

        public Form1()
        {
            InitializeComponent();
            gViewer.ZoomFraction = .02; //zoom increment smaller for smooth scrolling..
            mnuPopup.MouseLeave += new EventHandler(mnuPopup_MouseLeave);
            graph = new CGraph(gViewer, lvNodes, this);
            lst.Width = lvNodes.Width;
            lvNodes.ContextMenuStrip = mnuLVPopup;
            lvNodes.Columns[0].Width = lvNodes.Width - 5;
            lvSorter = new ListViewColumnSorter();
            ListViewColumnSorter.SortTypes[] columns = { 
                    ListViewColumnSorter.SortTypes.stText,              
            };
            lvSorter.columnSortType = columns;
            this.lvNodes.ListViewItemSorter = lvSorter;
        }

        private void lvNodes_ColumnClick(object sender, ColumnClickEventArgs e)
        {
            if (e.Column == lvSorter.SortColumn)
            {
                if (lvSorter.Order == SortOrder.Ascending) { lvSorter.Order = SortOrder.Descending; }
                else { lvSorter.Order = SortOrder.Ascending; }
            }
            else
            {
                lvSorter.SortColumn = e.Column;
                lvSorter.Order = SortOrder.Descending;
            }
            this.lvNodes.Sort();
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
            
            gViewer.SelectionChanged += new EventHandler(gViewer_SelectionChanged);
            gViewer.MouseUp += new MouseEventHandler(gViewer_MouseUp);
            gViewer.MouseWheel += new MouseEventHandler(gViewer_MouseWheel);
            
            ida = new ida_client(this.Handle);

            List<uint> Servers = ida.FindServers(); //remember IDASRVR does nto exist for x64 disasm yet...

            if (Servers.Count == 0)
            {
                debugLog("IDA not found...");
            }
            else if (Servers.Count == 1)
            {
                ida.IDA_HWND = (int)Servers[0];
                debugLog("IDA hwnd: " + ida.IDA_HWND);
                debugLog("IDA File: " + Path.GetFileName(ida.LoadedFileName()));
            }
            else
            { 
               debugLog(Servers.Count + " IDA windows open, will scan..");
            }

            string[] tmp = Environment.GetCommandLineArgs();
            string last = Path.GetTempPath() + "lastGraph.txt";
            string f = "";

            this.Visible = true;

            if (false && System.Diagnostics.Debugger.IsAttached)
            {
                string testFile = Application.StartupPath + "\\test.txt";
                if (!File.Exists(testFile)) testFile = testFile.Replace("\\bin\\Debug", "");
                if (File.Exists(testFile)) graph.LoadFile(testFile);
            }
            else //load from command line or lastgraph if not..
            {
                for (int i = tmp.Length - 1; i > 0; i--)
                {
                    //MessageBox.Show(i + " " + tmp[i]);
                    if (File.Exists(tmp[i])) { f = tmp[i]; break; }
                }

                if (File.Exists(f))
                {
                    try
                    {
                        try
                        {
                            if (File.Exists(last)) File.Delete(last);
                            File.Copy(f, last);
                        }
                        catch (Exception ex) { /*fu win7*/ }
                        debugLog("Loading " + f);
                        graph.LoadFile(f);
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show("Error loading: " + f + "\n\n" + ex.StackTrace);
                    }
                }
                else if (File.Exists(last))
                {
                    debugLog("Loading last graph");
                    graph.LoadFile(last);
                }
            }

            if (Servers.Count > 1)  //multiple IDA servers active, lets try to find the right one..
            { 
                uint target = FindServerForGraph(Servers);
                if (target == 0)
                {
                    debugLog("No IDA match not found.");
                }
                else
                {
                    ida.IDA_HWND = (int)target;
                    debugLog("IDA hwnd: " + ida.IDA_HWND);
                    debugLog("IDA File: " + Path.GetFileName(ida.LoadedFileName()));
                }
            }

            if(gViewer.Graph != null) lvNodes.Columns[0].Text = gViewer.Graph.NodeMap.Count + " Nodes";

        }

        uint FindServerForGraph(List<uint> windows)
        {
            Dictionary<uint, int> Results = new Dictionary<uint, int>();
            Hashtable Nodes = gViewer.Graph.NodeMap;
            foreach (uint hwnd in windows) //cycle through each server found..
            {
                ida.IDA_HWND = (int)hwnd; //set active hwnd to send data to..
                int matches = 0, misses = 0;
                foreach (Node n in Nodes.Values) 
                {
                    int va = ida.FuncVA(n.Attr.Label.Trim());
                    if (va != 0) matches++; else misses++;
                    if (misses == 2) break; //not all nodes in a graph are necessarily functions we can lookup such as .textxxx dd offset sub_xxx
                    if (matches == 4)
                    {
                        debugLog("4 funcs found: " + hwnd);
                        return hwnd;      //this is enough to say its a match..
                    }
                }
                Results.Add(hwnd, matches);
            }

            //but if there were less than 4 functions in the graph now, or > 2 misses we will select best possibility..
            int max = 0;
            uint top_hwnd = 0;
            foreach (KeyValuePair<uint,int> entry in Results)
            {
                if (entry.Value > max){
                    max = entry.Value;
                    top_hwnd = entry.Key;
                }
            }

            debugLog(max + " funcs found: " + top_hwnd);
            return max == 0 ? 0 : top_hwnd;

        }

        void mnuPopup_MouseLeave(object sender, EventArgs e)
        {
            mnuPopup.Hide();
        }

        void gViewer_MouseWheel(object sender, MouseEventArgs e)
        {
            if (e.Delta > 0) gViewer.ZoomInPressed(); else gViewer.ZoomOutPressed();
        }

        void gViewer_ZoomChanged(object sender, EventArgs e)
        {
            try { hScroll.Value = (int)gViewer.ZoomF; }
            catch (Exception ex) { }
        }

        void gViewer_SelectionChanged(object sender, EventArgs e)
        {
            gViewer_ZoomChanged(null, null);

            if(gViewer.SelectedObject == null)
            {
                if (mouseOverNode != null && mouseOverNode != selNode)
                {
                    mouseOverNode.Attr.LineWidth = 1;
                    mouseOverNode = null;     
                }
            }
            else if(gViewer.SelectedObject is Node)
            {
                if (mouseOverNode != null && mouseOverNode != selNode)
                {
                    //you could rig multiselect here by testing ctrl key and latter using linewidth as criteria..
                    mouseOverNode.Attr.LineWidth = 1;
                }
                mouseOverNode = (Node)gViewer.SelectedObject;
                mouseOverNode.Attr.LineWidth = 2;
                gViewer.Refresh();
                //debugLog("Selected node is " + selNode.Attr.Label.Trim());
            }

            gViewer.Refresh();
        }

        void gViewer_MouseUp(object sender, MouseEventArgs e)
        {
            //have to hot track with selectionChanged event or else select wont process in time for MouseUp...
            //a right click can even beat the selectionChanged event, so mouse over watch highlight, then rightclick :-\
            //must be a thread.invoke queing delay causing the problem in the glee control. 

            if (mouseOverNode != null)
            {
                if (selNode != null)
                {
                    //you could rig multiselect here by testing ctrl key and latter using linewidth as criteria..
                    selNode.Attr.LineWidth = 1;
                    selNode.Attr.Fontcolor = Microsoft.Glee.Drawing.Color.Black;
                    gViewer.Refresh();
                }
                selNode = mouseOverNode;
                selNode.Attr.Fontcolor = Microsoft.Glee.Drawing.Color.Blue;
                selNode.Attr.LineWidth = 3;
                gViewer.Refresh();
            }

            if (e.Button == System.Windows.Forms.MouseButtons.Right)
            {
                if (selNode != null) mnuPopup.Show(Cursor.Position);
            }
            else
            {
                if (selNode != null) ida.jmpName(selNode.Attr.Label);
            }
        }

        private void Form1_Resize(object sender, EventArgs e)
        {
            try
            {
                gViewer.Width = this.Width - gViewer.Left - 20;
                gViewer.Height = this.Height - gViewer.Top - 40;
                lst.Top = this.Height - lst.Height - 30;
                lvNodes.Height = lst.Top - 30;
            }
            catch (Exception ex) { }
        }

        private void zoomAllToolStripMenuItem_Click(object sender, EventArgs e)
        {
            gViewer.ShowBBox(gViewer.Graph.BBox);
        }

        private void lvNodes_ItemSelectionChanged(object sender, ListViewItemSelectionChangedEventArgs e)
        {

            if (selNode != null)
            {
                selNode.Attr.LineWidth = 1;
                selNode.Attr.Fontcolor = Microsoft.Glee.Drawing.Color.Black;
            }
            selNode = (Node)e.Item.Tag;
            selNode.Attr.LineWidth = 3;
            selNode.Attr.Fontcolor = Microsoft.Glee.Drawing.Color.Blue;
            ida.jmpName(selNode.Attr.Label);
            //gViewer.ShowBBox(selNode.BBox); //zoom to node..
            gViewer.Invalidate();
        }

        private void loadGraphToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if(dlg.ShowDialog() != DialogResult.OK) return;
            debugLog("Loading " + Path.GetFileName(dlg.FileName));
            graph.LoadFile(dlg.FileName);
        }

        private void lst_DoubleClick(object sender, EventArgs e)
        {
            if (lst.SelectedIndex > 0)
            {
                MessageBox.Show(lst.SelectedItem.ToString());
            }
        }

        private void renameNodeToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if(selNode == null) return;
            string oldName = selNode.Attr.Label.Trim();
            string newName = Program.InputBox("Enter new name", oldName);
            if (newName.Length == 0) return;
            if (ida.Rename(oldName, newName))
            {
                lst.Items.Add("Rename( " + oldName + ", " + newName + ")");
                selNode.Attr.Label = "   " + newName + "   ";
                ListViewItem li = (ListViewItem)selNode.UserData;
                li.Text = newName;
            }
            else
            {
                debugLog("Fail rename " + oldName);
            }
        }

        private void removeNodesBelowToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (selNode == null) return;
            List<Node> nodes = graph.NodesBelow(selNode,null);
            foreach (Node n in nodes)
            {
                n.Attr.AddStyle(Style.Invis); //doesnt look like there is any way to hide nodes..
            }
            gViewer.Invalidate();
        }

        private void prefixAllFunctionsBelowToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (selNode == null) return;

            string prefix = Program.InputBox("Enter prefix to use");
            if (prefix.Length == 0) return;
            
            List<Node> nodes = graph.NodesBelow(selNode, "sub_");

            if (MessageBox.Show("I am about to prefix " + nodes.Count + " nodes?", "Prefix Warning", MessageBoxButtons.OKCancel) == DialogResult.Cancel)
                return;

            foreach (Node n in nodes)
            {
                string newName = prefix + n.Attr.Label.Trim();
                if (ida.Rename(n.Attr.Label, newName ))
                {
                    n.Attr.Label = "   " + newName + "   ";
                    ListViewItem li = (ListViewItem)n.UserData;
                    li.Text = newName;
                }
                else
                {
                    debugLog("Fail rename " + n.Attr.Label.Trim() );
                }
            }
            gViewer.Invalidate();
            lvNodes.Refresh();
        }

        private void hScroll_Scroll(object sender, ScrollEventArgs e)
        {
            try
            {
                gViewer.ZoomF = hScroll.Value;
            }
            catch (Exception ex) { }

        }

        private void originalWIngraphToolStripMenuItem_Click(object sender, EventArgs e)
        {
            string basePath = AppDomain.CurrentDomain.BaseDirectory;
            string exeName = System.AppDomain.CurrentDomain.FriendlyName;

            string orgExe = basePath + "\\_" + exeName;
            string lastGraph = "c:\\lastgraph.txt";

            if (!File.Exists(orgExe))
            {
                MessageBox.Show("Could not locate original executable did you prefix it with underscore?\n\n" + orgExe);
                return;
            }

            if (!File.Exists(lastGraph))
            {
                MessageBox.Show("Could not locate lastGraph?\n\n" + lastGraph);
                return;
            }

            Process.Start(orgExe, lastGraph);

        }

        private void setTopMostToolStripMenuItem_Click(object sender, EventArgs e)
        {
            setTopMostToolStripMenuItem.Checked = !setTopMostToolStripMenuItem.Checked;
            Program.SetTopMost(this.Handle, setTopMostToolStripMenuItem.Checked);

        }

        private void copyToolStripMenuItem_Click(object sender, EventArgs e)
        {
            string tmp="";
            foreach (ListViewItem li in lvNodes.Items)
            {
                tmp += li.Text + ",";
            }
            if (tmp.Length > 0) tmp = tmp.Substring(0, tmp.Length - 1);
            Clipboard.Clear();
            Clipboard.SetText(tmp);
        }

        private void searchToolStripMenuItem_Click(object sender, EventArgs e)
        {
            string tmp = "";
            int found = 0;
            string find = Program.InputBox("Enter text to osearch for");

            if (find.Length == 0) return;
           
            foreach (ListViewItem li in lvNodes.Items)
            {
                li.Selected = false; //deselect all others
                if (li.Text.IndexOf(find, 0, li.Text.Length, StringComparison.CurrentCultureIgnoreCase) >= 0)
                {
                    found++;
                    if (tmp.Length == 0) li.Selected = true;
                    tmp += li.Text + ", ";
                    if (found % 5 == 0) tmp += "\r\n";
                }

            }

            if (found == 0)
            {
                MessageBox.Show("No results found");
            }
            else
            {
                if (tmp.Length > 0) tmp = tmp.Substring(0, tmp.Length - 2);
                if (found > 1)
                {
                    MessageBox.Show( found + " results found. The first one has been selected.\n\n" + tmp);
                }                
            }
        }

        private void zoomToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (selNode != null) gViewer.ShowBBox(selNode.BBox); //zoom to node..
        }

        private void prefixAllToolStripMenuItem_Click(object sender, EventArgs e)
        {
            string prefix = Program.InputBox("Enter prefix to use for unnamed subs");
            if (prefix.Length == 0) return;

            foreach (ListViewItem li in lvNodes.Items)
            {
                if (li.Text.IndexOf("sub_") == 0)
                {
                    string newName = prefix + li.Text;
                    if (ida.Rename(li.Text, newName))
                    {
                        li.Text = newName;
                    }
                    else
                    {
                        debugLog("Fail rename " + li.Text);
                    }
                }
                else
                {
                    debugLog("skipping rename " + li.Text);
                }
            }
            gViewer.Invalidate();
            lvNodes.Refresh();
        }

        private void menuStrip1_ItemClicked(object sender, ToolStripItemClickedEventArgs e)
        {

        }

    }
}
