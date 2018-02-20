namespace gleeGraph
{
    partial class Form1
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            this.lvNodes = new System.Windows.Forms.ListView();
            this.columnHeader1 = new System.Windows.Forms.ColumnHeader();
            this.gViewer = new Microsoft.Glee.GraphViewerGdi.GViewer();
            this.menuStrip1 = new System.Windows.Forms.MenuStrip();
            this.toolsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.loadGraphToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.zoomAllToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.originalWIngraphToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.setTopMostToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.mnuPopup = new System.Windows.Forms.ContextMenuStrip(this.components);
            this.removeNodesBelowToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.renameNodeToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.prefixAllFunctionsBelowToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.lst = new System.Windows.Forms.ListBox();
            this.dlg = new System.Windows.Forms.OpenFileDialog();
            this.hScroll = new System.Windows.Forms.HScrollBar();
            this.pb = new System.Windows.Forms.ProgressBar();
            this.mnuLVPopup = new System.Windows.Forms.ContextMenuStrip(this.components);
            this.searchToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.copyToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.zoomToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.prefixAllToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.menuStrip1.SuspendLayout();
            this.mnuPopup.SuspendLayout();
            this.mnuLVPopup.SuspendLayout();
            this.SuspendLayout();
            // 
            // lvNodes
            // 
            this.lvNodes.Columns.AddRange(new System.Windows.Forms.ColumnHeader[] {
            this.columnHeader1});
            this.lvNodes.Font = new System.Drawing.Font("Courier New", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lvNodes.HideSelection = false;
            this.lvNodes.Location = new System.Drawing.Point(0, 27);
            this.lvNodes.Name = "lvNodes";
            this.lvNodes.Size = new System.Drawing.Size(251, 428);
            this.lvNodes.TabIndex = 0;
            this.lvNodes.UseCompatibleStateImageBehavior = false;
            this.lvNodes.View = System.Windows.Forms.View.Details;
            this.lvNodes.ColumnClick += new System.Windows.Forms.ColumnClickEventHandler(this.lvNodes_ColumnClick);
            this.lvNodes.ItemSelectionChanged += new System.Windows.Forms.ListViewItemSelectionChangedEventHandler(this.lvNodes_ItemSelectionChanged);
            // 
            // columnHeader1
            // 
            this.columnHeader1.Text = "Nodes";
            this.columnHeader1.Width = 220;
            // 
            // gViewer
            // 
            this.gViewer.AsyncLayout = false;
            this.gViewer.AutoScroll = true;
            this.gViewer.BackColor = System.Drawing.Color.White;
            this.gViewer.BackwardEnabled = false;
            this.gViewer.Font = new System.Drawing.Font("Courier New", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.gViewer.ForwardEnabled = false;
            this.gViewer.Graph = null;
            this.gViewer.Location = new System.Drawing.Point(257, 27);
            this.gViewer.MouseHitDistance = 0.05;
            this.gViewer.Name = "gViewer";
            this.gViewer.NavigationVisible = true;
            this.gViewer.PanButtonPressed = false;
            this.gViewer.SaveButtonVisible = true;
            this.gViewer.Size = new System.Drawing.Size(753, 581);
            this.gViewer.TabIndex = 1;
            this.gViewer.ZoomF = 1;
            this.gViewer.ZoomFraction = 0.5;
            this.gViewer.ZoomWindowThreshold = 0.05;
            // 
            // menuStrip1
            // 
            this.menuStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.toolsToolStripMenuItem});
            this.menuStrip1.Location = new System.Drawing.Point(0, 0);
            this.menuStrip1.Name = "menuStrip1";
            this.menuStrip1.Size = new System.Drawing.Size(1011, 24);
            this.menuStrip1.TabIndex = 2;
            this.menuStrip1.Text = "menuStrip1";
            this.menuStrip1.ItemClicked += new System.Windows.Forms.ToolStripItemClickedEventHandler(this.menuStrip1_ItemClicked);
            // 
            // toolsToolStripMenuItem
            // 
            this.toolsToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.loadGraphToolStripMenuItem,
            this.zoomAllToolStripMenuItem,
            this.originalWIngraphToolStripMenuItem,
            this.setTopMostToolStripMenuItem});
            this.toolsToolStripMenuItem.Name = "toolsToolStripMenuItem";
            this.toolsToolStripMenuItem.Size = new System.Drawing.Size(44, 20);
            this.toolsToolStripMenuItem.Text = "Tools";
            // 
            // loadGraphToolStripMenuItem
            // 
            this.loadGraphToolStripMenuItem.Name = "loadGraphToolStripMenuItem";
            this.loadGraphToolStripMenuItem.Size = new System.Drawing.Size(170, 22);
            this.loadGraphToolStripMenuItem.Text = "Load Graph";
            this.loadGraphToolStripMenuItem.Click += new System.EventHandler(this.loadGraphToolStripMenuItem_Click);
            // 
            // zoomAllToolStripMenuItem
            // 
            this.zoomAllToolStripMenuItem.Name = "zoomAllToolStripMenuItem";
            this.zoomAllToolStripMenuItem.Size = new System.Drawing.Size(170, 22);
            this.zoomAllToolStripMenuItem.Text = "Zoom All";
            this.zoomAllToolStripMenuItem.Click += new System.EventHandler(this.zoomAllToolStripMenuItem_Click);
            // 
            // originalWIngraphToolStripMenuItem
            // 
            this.originalWIngraphToolStripMenuItem.Name = "originalWIngraphToolStripMenuItem";
            this.originalWIngraphToolStripMenuItem.Size = new System.Drawing.Size(170, 22);
            this.originalWIngraphToolStripMenuItem.Text = "Original Wingraph";
            this.originalWIngraphToolStripMenuItem.Click += new System.EventHandler(this.originalWIngraphToolStripMenuItem_Click);
            // 
            // setTopMostToolStripMenuItem
            // 
            this.setTopMostToolStripMenuItem.Name = "setTopMostToolStripMenuItem";
            this.setTopMostToolStripMenuItem.Size = new System.Drawing.Size(170, 22);
            this.setTopMostToolStripMenuItem.Text = "Set TopMost";
            this.setTopMostToolStripMenuItem.Click += new System.EventHandler(this.setTopMostToolStripMenuItem_Click);
            // 
            // mnuPopup
            // 
            this.mnuPopup.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.removeNodesBelowToolStripMenuItem,
            this.renameNodeToolStripMenuItem,
            this.prefixAllFunctionsBelowToolStripMenuItem});
            this.mnuPopup.Name = "mnuPopup";
            this.mnuPopup.Size = new System.Drawing.Size(252, 70);
            // 
            // removeNodesBelowToolStripMenuItem
            // 
            this.removeNodesBelowToolStripMenuItem.Name = "removeNodesBelowToolStripMenuItem";
            this.removeNodesBelowToolStripMenuItem.Size = new System.Drawing.Size(251, 22);
            this.removeNodesBelowToolStripMenuItem.Text = "Remove Nodes Below";
            this.removeNodesBelowToolStripMenuItem.Visible = false;
            this.removeNodesBelowToolStripMenuItem.Click += new System.EventHandler(this.removeNodesBelowToolStripMenuItem_Click);
            // 
            // renameNodeToolStripMenuItem
            // 
            this.renameNodeToolStripMenuItem.Name = "renameNodeToolStripMenuItem";
            this.renameNodeToolStripMenuItem.Size = new System.Drawing.Size(251, 22);
            this.renameNodeToolStripMenuItem.Text = "Rename Function";
            this.renameNodeToolStripMenuItem.Click += new System.EventHandler(this.renameNodeToolStripMenuItem_Click);
            // 
            // prefixAllFunctionsBelowToolStripMenuItem
            // 
            this.prefixAllFunctionsBelowToolStripMenuItem.Name = "prefixAllFunctionsBelowToolStripMenuItem";
            this.prefixAllFunctionsBelowToolStripMenuItem.Size = new System.Drawing.Size(251, 22);
            this.prefixAllFunctionsBelowToolStripMenuItem.Text = "Prefix all unnamed functions below";
            this.prefixAllFunctionsBelowToolStripMenuItem.Click += new System.EventHandler(this.prefixAllFunctionsBelowToolStripMenuItem_Click);
            // 
            // lst
            // 
            this.lst.Font = new System.Drawing.Font("Courier New", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lst.FormattingEnabled = true;
            this.lst.ItemHeight = 16;
            this.lst.Location = new System.Drawing.Point(0, 461);
            this.lst.Name = "lst";
            this.lst.Size = new System.Drawing.Size(239, 148);
            this.lst.TabIndex = 4;
            this.lst.DoubleClick += new System.EventHandler(this.lst_DoubleClick);
            // 
            // hScroll
            // 
            this.hScroll.Location = new System.Drawing.Point(439, 33);
            this.hScroll.Maximum = 30;
            this.hScroll.Name = "hScroll";
            this.hScroll.Size = new System.Drawing.Size(265, 12);
            this.hScroll.TabIndex = 5;
            this.hScroll.Scroll += new System.Windows.Forms.ScrollEventHandler(this.hScroll_Scroll);
            // 
            // pb
            // 
            this.pb.Location = new System.Drawing.Point(719, 34);
            this.pb.Name = "pb";
            this.pb.Size = new System.Drawing.Size(280, 10);
            this.pb.TabIndex = 6;
            // 
            // mnuLVPopup
            // 
            this.mnuLVPopup.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.searchToolStripMenuItem,
            this.copyToolStripMenuItem,
            this.zoomToolStripMenuItem,
            this.prefixAllToolStripMenuItem});
            this.mnuLVPopup.Name = "mnuLVPopup";
            this.mnuLVPopup.Size = new System.Drawing.Size(163, 92);
            // 
            // searchToolStripMenuItem
            // 
            this.searchToolStripMenuItem.Name = "searchToolStripMenuItem";
            this.searchToolStripMenuItem.Size = new System.Drawing.Size(162, 22);
            this.searchToolStripMenuItem.Text = "Search";
            this.searchToolStripMenuItem.Click += new System.EventHandler(this.searchToolStripMenuItem_Click);
            // 
            // copyToolStripMenuItem
            // 
            this.copyToolStripMenuItem.Name = "copyToolStripMenuItem";
            this.copyToolStripMenuItem.Size = new System.Drawing.Size(162, 22);
            this.copyToolStripMenuItem.Text = "Copy Nodes List";
            this.copyToolStripMenuItem.Click += new System.EventHandler(this.copyToolStripMenuItem_Click);
            // 
            // zoomToolStripMenuItem
            // 
            this.zoomToolStripMenuItem.Name = "zoomToolStripMenuItem";
            this.zoomToolStripMenuItem.Size = new System.Drawing.Size(162, 22);
            this.zoomToolStripMenuItem.Text = "Zoom to Node";
            this.zoomToolStripMenuItem.Click += new System.EventHandler(this.zoomToolStripMenuItem_Click);
            // 
            // prefixAllToolStripMenuItem
            // 
            this.prefixAllToolStripMenuItem.Name = "prefixAllToolStripMenuItem";
            this.prefixAllToolStripMenuItem.Size = new System.Drawing.Size(162, 22);
            this.prefixAllToolStripMenuItem.Text = "Prefix All";
            this.prefixAllToolStripMenuItem.Click += new System.EventHandler(this.prefixAllToolStripMenuItem_Click);
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1011, 610);
            this.Controls.Add(this.pb);
            this.Controls.Add(this.hScroll);
            this.Controls.Add(this.gViewer);
            this.Controls.Add(this.lvNodes);
            this.Controls.Add(this.lst);
            this.Controls.Add(this.menuStrip1);
            this.MainMenuStrip = this.menuStrip1;
            this.Name = "Form1";
            this.Text = "Wingraph32 replacement using M$ GLEE library - http://sandsprite.com";
            this.Load += new System.EventHandler(this.Form1_Load);
            this.Resize += new System.EventHandler(this.Form1_Resize);
            this.menuStrip1.ResumeLayout(false);
            this.menuStrip1.PerformLayout();
            this.mnuPopup.ResumeLayout(false);
            this.mnuLVPopup.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.ListView lvNodes;
        private System.Windows.Forms.ColumnHeader columnHeader1;
        private Microsoft.Glee.GraphViewerGdi.GViewer gViewer;
        private System.Windows.Forms.MenuStrip menuStrip1;
        private System.Windows.Forms.ToolStripMenuItem toolsToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem loadGraphToolStripMenuItem;
        private System.Windows.Forms.ContextMenuStrip mnuPopup;
        private System.Windows.Forms.ToolStripMenuItem removeNodesBelowToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem renameNodeToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem prefixAllFunctionsBelowToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem zoomAllToolStripMenuItem;
        private System.Windows.Forms.ListBox lst;
        private System.Windows.Forms.OpenFileDialog dlg;
        private System.Windows.Forms.HScrollBar hScroll;
        private System.Windows.Forms.ToolStripMenuItem originalWIngraphToolStripMenuItem;
        public System.Windows.Forms.ProgressBar pb;
        private System.Windows.Forms.ToolStripMenuItem setTopMostToolStripMenuItem;
        private System.Windows.Forms.ContextMenuStrip mnuLVPopup;
        private System.Windows.Forms.ToolStripMenuItem copyToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem searchToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem zoomToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem prefixAllToolStripMenuItem;
    }
}

