using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Windows.Forms;
//using Microsoft.Glee;
using Microsoft.Glee.GraphViewerGdi;
using Microsoft.Glee.Drawing;
using System.Diagnostics;

namespace gleeGraph
{
    class CGraph
    {
        ListView fxLv;
        GViewer gViewer;
        Graph graph;
        Form1 parent;
        Dictionary<string, Node> nodes = new Dictionary<string,Node>();
        Dictionary<string, uint> Colors = new Dictionary<string,uint>();

        private StringComparison ic = StringComparison.CurrentCultureIgnoreCase;

        public CGraph(GViewer gg, ListView lv, Form1 f)
        {
            fxLv = lv;
            gViewer = gg;
            parent = f;
        }

        //no checking for circular references but no dups at least.
        public List<Node> NodesBelow(Node parent, string opt_nodeMatchText)
        {
            List<Node> nodes = new List<Node>();
            List<Node> touched = new List<Node>();
            try
            {
                Debug.WriteLine("Starting: " + parent.Attr.Label);
                AddSubNodes(ref nodes, ref touched, parent, opt_nodeMatchText);
            }
            catch (Exception e) { /*I will deal with you latter*/ };
            return nodes;
        }

        //can trigger an out of stack space error on large graphs.. 
        private void AddSubNodes(ref List<Node> nodes, ref List<Node> touched, Node parent, string opt_nodeMatchText)
        {
            foreach(Edge e in parent.OutEdges)
            {
                if (!NodeExistsInList(ref touched, e.TargetNode))
                {
                    touched.Add(e.TargetNode);
                    if (opt_nodeMatchText == null || opt_nodeMatchText.Length == 0) //no optional match criteria specified, just add it
                    {
                        Debug.WriteLine("Adding: " + e.TargetNode.Attr.Label);
                        nodes.Add(e.TargetNode);
                    }
                    else //only add if our match string is found in the label ex. sub_ prefix...
                    {
                        if (e.TargetNode.Attr.Label.IndexOf(opt_nodeMatchText) >= 0)
                        {
                            Debug.WriteLine("Adding: " + e.TargetNode.Attr.Label);
                            nodes.Add(e.TargetNode);
                        }
                    }
                }
                if (e.TargetNode.OutEdges.Count() > 0)
                {
                        Debug.WriteLine("Following: " + e.TargetNode.Attr.Label);
                        AddSubNodes(ref nodes, ref touched, e.TargetNode, opt_nodeMatchText);
                }
            }
        } 


        private bool NodeExistsInList(ref List<Node> nodes, Node test)
        {
            foreach (Node n in nodes) if (n.Id == test.Id) 
                    return true;
            return false;
        }

        public void LoadFile(string pth){
    
            if(!File.Exists(pth)) return;

            fxLv.Items.Clear();
            graph = new Graph("graph");
            graph.GraphAttr.NodeAttr.Padding = 3;
            Colors = new Dictionary<string,uint>();
            nodes = new Dictionary<string, Node>();

            ListViewItem li;
            string dat = File.ReadAllText(pth);
            dat = dat.Replace('\r', '\n').Replace("\n\n","\n");

            string[] tmp = dat.Split('\n');
            
            string nodeMarker = "node:";
            string edgeMarker = "edge:";
            string colorentry = "colorentry";
            int linkCount =0;

            string orgTitle = parent.Text;

            parent.Text = "Parsing graph definition..";
            parent.pb.Value = 0;
            parent.pb.Maximum = tmp.Length;

            foreach(string x in tmp){
                
                parent.pb.Value++;

                if (x.Length > nodeMarker.Length && x.Substring(0, nodeMarker.Length) == nodeMarker)
                {
                    //add a node  title: "0" label: "sub_4122CC" color: 76 textcolor: black
                    string t = GetParam(x, "title");
                    string l = GetParam(x, "label");
                    string c = Get_NQ_Param(x, "color");
                    string tc = Get_NQ_Param(x, "textcolor");

                    if (t.Length > 0 && l.Length > 0)
                    {
                        Node n = graph.AddNode(t);
                        //n.Attr.Shape = Microsoft.Glee.Drawing.Shape.Box;
                        n.Attr.Label = "   " + l + "   ";

                        li = fxLv.Items.Add(l);
                        li.Tag = n;
                        n.UserData = li;

                        //n.Attr.Fontcolor = getColorFromId(tc);
                        //if( c != Color.White) n.Attr.Fillcolor = getColorFromId(c);
                        //if( n.Attr.Fontcolor == n.Attr.Fillcolor) n.Attr.Fontcolor = Color.White;
                        nodes.Add("node:" + t, n);
                        if (nodes.Count % 20 == 0) { parent.Refresh(); Application.DoEvents(); }                         
                    }
                }
                else if (x.Length > edgeMarker.Length && x.Substring(0, edgeMarker.Length) == edgeMarker)
                {
                    //add a link
                    Node sNode = null, tNode = null;
                    string s = GetParam(x, "sourcename");
                    string t = GetParam(x, "targetname");
                    if(s.Length > 0) sNode = GetNodeID(s);
                    if(s.Length > 0) tNode = GetNodeID(t);
                    if(sNode != null && tNode != null){
                        graph.AddEdge(sNode.Id, tNode.Id);
                        linkCount++;
                    }
                }
                else if (x.Length > colorentry.Length && x.Substring(0, colorentry.Length) == colorentry)
                {
                    //colorentry 32: 0 0 0
                    string cset = "";
                    string cnum = x.Substring(colorentry.Length + 2,2);
                    int a = x.IndexOf(':');
                    if(a > 0){
                        cset = x.Substring(a+1);
                        AddColor(cnum, cset);
                    }
                }
            }

            parent.Text = "Rendering graph..";

            try
            {
                gViewer.Graph = graph; //the rendering takes quite a while.. the parsing/adding nodes above is almost instant..
            }
            catch (Exception e)
            {
                MessageBox.Show("Error setting graph #Nodes=" + nodes.Count + " Links: " + linkCount);
            }

            parent.Text = orgTitle;
            parent.pb.Value = 0;

            return;

        }

        void AddColor(string cnum, string cset)
        {     
            string ret="";
            try{

                string[] t = cset.Split(' ');
                for(int i = 0 ; i < t.Length; i++){
                    int number = int.Parse(t[i]);
                    string hex = number.ToString("x2");
                    ret += hex;
                }

                Colors.Add("cid:" + cnum, Convert.ToUInt32(ret,16));
               
            }catch(Exception e){};

        }

        
        uint getColorFromId(string id){
            
            uint ret = 0;

            try{
                ret = this.Colors["cid:" + id];
            
            
                //If getColorFromId = vbYellow Then getColorFromId = vbBlue 'fuckyou
            }
            catch(Exception e){
                /*If Err.Number <> 0 Then
                    getColorFromId = id
                End If*/
            }

            return ret;
        }
        
         
        Node GetNodeID(string id){
            try{
                return nodes["node:" + id];
            }catch(Exception e){
                return null;
            }
        }         

        string Get_NQ_Param(string src, string param){
            //only works on NON-quoted values works for our needs
            //node: { title: "0" label: "sub_4122CC" color: 76 textcolor: 73 borderwidth: 10 bordercolor: 82  }
            //edge: { sourcename: "1" targetname: "0" }
            
            int a = src.IndexOf(param, ic);
            if( a < 1) return ""; //parameter not found
            
            a += 2;
            int b = src.IndexOf(' ',a)+1;
            if( b < 1) return ""; //parameter not found
            
            int c = src.IndexOf(' ',b)+1;
            if( c < 1) return "";
            if( c < b) return "";
            
            return src.Substring( b, c - b);
            
            //If Get_NQ_Param = "white" Then Get_NQ_Param = vbWhite
            //If Get_NQ_Param = "black" Then Get_NQ_Param = vbBlack
            
        }


        string GetParam(string src, string param){
            //only works on quoted values works for our needs
            //node: { title: "0" label: "sub_4122CC" color: 76 textcolor: 73 borderwidth: 10 bordercolor: 82  }
            //edge: { sourcename: "1" targetname: "0" }
            
            int a = src.IndexOf(param, ic);
            if( a < 1) return ""; //parameter not found
            
            int b = src.IndexOf('"',a)+1;
            if( b < 1) return ""; //parameter not found
            
            int c = src.IndexOf('"',b);
            if( c < 1) return "";
            if( c < b) return "";
            
           return src.Substring( b, c - b);
            
        }

    }
}
