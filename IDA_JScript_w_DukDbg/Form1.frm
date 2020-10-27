VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCTL.OCX"
Object = "{047848A0-21DD-421D-951E-B4B1F3E1718D}#89.0#0"; "dukdbg.ocx"
Object = "{3B7C8863-D78F-101B-B9B5-04021C009402}#1.2#0"; "richtx32.ocx"
Object = "{248DD890-BB45-11CF-9ABC-0080C7E7B78D}#1.0#0"; "MSWINSCK.OCX"
Begin VB.Form Form1 
   Caption         =   "IDA JScript 2 - http://sandsprite.com"
   ClientHeight    =   7020
   ClientLeft      =   165
   ClientTop       =   450
   ClientWidth     =   10230
   BeginProperty Font 
      Name            =   "Courier New"
      Size            =   9.75
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   Icon            =   "Form1.frx":0000
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   ScaleHeight     =   7020
   ScaleWidth      =   10230
   StartUpPosition =   2  'CenterScreen
   Begin MSComctlLib.ProgressBar pb 
      Height          =   150
      Left            =   90
      TabIndex        =   9
      Top             =   0
      Width           =   9915
      _ExtentX        =   17489
      _ExtentY        =   265
      _Version        =   393216
      Appearance      =   0
   End
   Begin MSWinsockLib.Winsock Winsock1 
      Left            =   9045
      Top             =   0
      _ExtentX        =   741
      _ExtentY        =   741
      _Version        =   393216
   End
   Begin dukDbg.ucDukDbg txtjs 
      Height          =   3570
      Left            =   45
      TabIndex        =   7
      Top             =   225
      Width           =   9960
      _ExtentX        =   17568
      _ExtentY        =   6297
   End
   Begin VB.Frame Frame1 
      Caption         =   "Log Window and Output Pane"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   3195
      Left            =   90
      TabIndex        =   0
      Top             =   3870
      Width           =   9975
      Begin VB.Frame fraSaved 
         BorderStyle     =   0  'None
         Caption         =   "Saved Scripts"
         BeginProperty Font 
            Name            =   "MS Sans Serif"
            Size            =   8.25
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   495
         Left            =   5940
         TabIndex        =   4
         Top             =   2610
         Width           =   3765
         Begin MSComctlLib.ImageCombo cboSaved 
            Height          =   375
            Left            =   1035
            TabIndex        =   5
            TabStop         =   0   'False
            Top             =   0
            Width           =   2655
            _ExtentX        =   4683
            _ExtentY        =   661
            _Version        =   393216
            ForeColor       =   -2147483640
            BackColor       =   -2147483643
            BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
               Name            =   "Courier New"
               Size            =   9.75
               Charset         =   0
               Weight          =   400
               Underline       =   0   'False
               Italic          =   0   'False
               Strikethrough   =   0   'False
            EndProperty
            Indentation     =   1
            Text            =   "ImageCombo1"
         End
         Begin VB.Label Label1 
            Caption         =   "Saved Scripts"
            BeginProperty Font 
               Name            =   "MS Sans Serif"
               Size            =   8.25
               Charset         =   0
               Weight          =   400
               Underline       =   0   'False
               Italic          =   0   'False
               Strikethrough   =   0   'False
            EndProperty
            Height          =   315
            Left            =   0
            TabIndex        =   6
            Top             =   45
            Width           =   1155
         End
      End
      Begin VB.CheckBox Check1 
         Caption         =   "Show Debug Log"
         BeginProperty Font 
            Name            =   "MS Sans Serif"
            Size            =   8.25
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   255
         Left            =   150
         TabIndex        =   2
         TabStop         =   0   'False
         Top             =   2670
         Width           =   1935
      End
      Begin VB.ListBox List1 
         BeginProperty Font 
            Name            =   "Courier"
            Size            =   9.75
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   2010
         Left            =   1020
         TabIndex        =   1
         TabStop         =   0   'False
         Top             =   360
         Visible         =   0   'False
         Width           =   8865
      End
      Begin RichTextLib.RichTextBox Text1 
         Height          =   2220
         Left            =   135
         TabIndex        =   8
         Top             =   270
         Width           =   9780
         _ExtentX        =   17251
         _ExtentY        =   3916
         _Version        =   393217
         Enabled         =   -1  'True
         ScrollBars      =   3
         TextRTF         =   $"Form1.frx":0CCA
      End
      Begin VB.Label lblIDB 
         Caption         =   "Current IDB (null)"
         BeginProperty Font 
            Name            =   "Courier"
            Size            =   9.75
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   375
         Left            =   2160
         TabIndex        =   3
         Top             =   2670
         Width           =   6135
      End
   End
   Begin VB.Menu mnuTools 
      Caption         =   "Tools"
      Begin VB.Menu mnuNew 
         Caption         =   "New"
      End
      Begin VB.Menu mnuOpenScript 
         Caption         =   "Open File"
      End
      Begin VB.Menu mnuSave 
         Caption         =   "Save"
      End
      Begin VB.Menu mnuSaveAs 
         Caption         =   "Save As"
      End
      Begin VB.Menu mnuSpacer1 
         Caption         =   "-"
      End
      Begin VB.Menu mnuLoadLast 
         Caption         =   "Load LastScript"
      End
      Begin VB.Menu mnuFormatJS 
         Caption         =   "Format Javascript"
      End
      Begin VB.Menu mnuSpacer3 
         Caption         =   "-"
      End
      Begin VB.Menu mnuSetTimeout 
         Caption         =   "Set Timeout"
      End
      Begin VB.Menu mnuSpacer4 
         Caption         =   "-"
      End
      Begin VB.Menu mnuSelectIDAInstance 
         Caption         =   "Reconnect to IDA"
      End
   End
   Begin VB.Menu mnuExtras 
      Caption         =   "Extras"
      Begin VB.Menu mnuImportPatch 
         Caption         =   "Import Patch"
      End
      Begin VB.Menu mnuShowAddrList 
         Caption         =   "View Address List"
      End
      Begin VB.Menu mnuIDACompareExporter 
         Caption         =   "IDA Compare Exporter"
      End
      Begin VB.Menu mnuSpacer2 
         Caption         =   "-"
      End
      Begin VB.Menu mnuScintOpts 
         Caption         =   "Scintinella Version"
      End
      Begin VB.Menu mnuDisableUIPI 
         Caption         =   "Disable UIPI (dev)"
      End
      Begin VB.Menu mnuSHellExt 
         Caption         =   "Register .idajs Shell Extension"
      End
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Public ida As New CIDAScript
Public loadedFile As String
Public sci As sci2.SciSimple
Public remote As New CRemoteExportClient
Public x64 As New CX64
Public al As frmAddrList

Private Sub cboSaved_Click()
    On Error Resume Next
    Dim ci As ComboItem, f As String
    
    Set ci = cboSaved.SelectedItem
    f = ci.Tag
    
    If loadedFile <> f Then
    
        If sci.isDirty Then
            If MsgBox("Save changes?", vbYesNo) = vbYes Then
                If Len(loadedFile) = 0 Then
                    loadedFile = dlg.SaveDialog(AllFiles)
                    If Len(loadedFile) > 0 Then
                        fso.writeFile loadedFile, txtjs.Text
                    End If
                Else
                    fso.writeFile loadedFile, txtjs.Text
                End If
            End If
        End If
        
        loadedFile = f
        txtjs.LoadFile f
    End If
    
End Sub

Private Sub Check1_Click()
    List1.Visible = CBool(Check1.value)
End Sub

Private Sub mnuDisableUIPI_Click()
    Dim reg As New clsRegistry2
    Dim path As String, Name As String, v
    'If you don't want to disable UAC, you could try just disabling UIPI (User Interface Privilege Isolation).
    'Open regedit and go to: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    'Add a new DWORD (32-bit) Value called EnableUIPI and set it to 0.
    path = "SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    Name = "EnableUIPI"
    reg.hive = HKEY_LOCAL_MACHINE
    
    v = reg.ReadValue(path, Name)
    If v = 0 And Not IsEmpty(v) Then
        MsgBox "Already exists and set to 0 (disabled)", vbInformation
    Else
        If reg.SetValue(path, Name, 0, REG_DWORD) Then
            MsgBox "Value now 0 (disabled) reboot", vbInformation
        Else
            MsgBox "Failed to set run as admin", vbInformation
        End If
    End If
    
End Sub

Private Sub mnuIDACompareExporter_Click()
    If Not ida.isUp Then
        MsgBox "Connect to an IDA instance first.", vbInformation
        Exit Sub
    End If
    frmIDACompare.Show
End Sub

Private Sub mnuImportPatch_Click()
   frmImportBytes.Show
End Sub

Private Sub mnuNew_Click()
    Dim t As String
    t = fso.GetFreeFileName(Environ("temp"))
    fso.writeFile t, ""
    loadedFile = t
    txtjs.LoadFile t
    'sci.Text = Empty
End Sub

Private Sub mnuSetTimeout_Click()
    Dim L As Long, msg As String
    On Error Resume Next
    msg = Replace("Enter new ms timeout value\n  0 to disable\n\nIf you get a endless loop close IDA to break it", "\n", vbCrLf)
    L = CLng(InputBox(msg, , txtjs.timeout))
    If Err.Number <> 0 Then
        MsgBox "Invalid number set ignoring"
        Exit Sub
    End If
    txtjs.timeout = L
End Sub

Private Sub mnuShowAddrList_Click()
    al.showList
End Sub

Private Sub txtjs_StateChanged(state As dukDbg.dbgStates)
    
    On Error Resume Next
    Dim idb As String
    Dim hwnd As Long
    
    If state = dsStarted Then
    
        Text1.Text = Empty
        
        ida.writeFile App.path & "\lastScript.txt", txtjs.Text
        
        If Not ida.isUp Then
            hwnd = Form2.SelectIDAInstance(True, False)
            If hwnd <> 0 Then
                ida.ipc.RemoteHWND = hwnd
                idb = ida.loadedFile
                List1.AddItem "IDA Server Up hwnd=" & ida.ipc.RemoteHWND & " (0x" & Hex(ida.ipc.RemoteHWND) & ")"
                List1.AddItem "IDB: " & idb
                lblIDB = "Current IDB: " & fso.FileNameFromPath(idb)
            Else
                Text1.Text = "IDA Server instances not found"
                lblIDB.caption = "Current IDB: (null)"
                Exit Sub
            End If
        End If
        
        If ida.isUp Then ida.targetIs_x86 'sets public ida.is64BitMode used internally (cached)

    End If
    
    'If state = dsIdle And al.addrAdded Then al.showList
    
End Sub
 

Private Sub Form_Load()
    
    On Error Resume Next
    
    Dim hwnd As Long
    Dim idb As String
    Dim windows As Long
    
    'quick way for IDASrvr to be able to find us for launching..
    SaveSetting "IPC", "HANDLES", "IDAJSCRIPT", App.path & "\IDA_JScript.exe"
    
    If Command = "/install" Then
        Call installPLW(True, True)
        Call installPLW_2(True, True)
        Call register_idajsFileExt
        End
    End If
        
    FormPos Me, True
    Me.Visible = True
    frmAddrList.Visible = False
    Set al = frmAddrList
    mnuDisableUIPI.Visible = isIde()
    
    Set remote.ws = Winsock1
    Set sci = txtjs.sci
    If sci Is Nothing Then MsgBox "Failed to get DukDbg.sci version mismatch between scivb and dukdbg :("

    'to use with duk we MUST use correct case on these since the relay is through JS
    
    txtjs.AddIntellisense "x64", "toHex add subtract"
    
    txtjs.AddIntellisense "fso", "readFile writeFile appendFile fileExists deleteFile openFileDialog saveFileDialog"
    
    txtjs.AddIntellisense "ida", "isUp is32Bit message makeStr makeUnk loadedFile patchString patchByte getAsm instSize " & _
                                "xRefsTo xRefsFrom getName functionName hideBlock showBlock setname addComment getComment addCodeXRef addDataXRef " & _
                                "delCodeXRef delDataXRef funcVAByName renameFunc find decompile jump jumpRVA refresh undefine showEA hideEA " & _
                                "removeName makeCode funcIndexFromVA nextEA prevEA funcCount() numFuncs() functionStart functionEnd readByte " & _
                                "originalByte imageBase screenEA() quickCall clearDecompilerCache() isCode isData readLong readShort readQWord " & _
                                "dumpFunc dumpFuncBytes getopv add_enum get_enum add_enum_member importFile addSegment segExists delSeg getSegs"
                               
     txtjs.AddIntellisense "list", "AddItem Clear ListCount Enabled"
    
     txtjs.AddIntellisense "app", "intToHex t clearLog caption alert getClipboard setClipboard benchMark askValue exec enableIDADebugMessages timeout do_events() hexDump hexstr toBytes"
       
     txtjs.AddIntellisense "remote", "ip response ScanProcess ResolveExport"
     
     txtjs.AddIntellisense "al", "addAddr showList() hideList() clear() copyAll()"
     
     txtjs.AddIntellisense "pb", "max value clear() inc()"
     
    'divide up into these classes for intellise sense cleanliness?
    'ui -> jump refresh() hideea showea hideblock showblock getcomment addcomment loadedfile
    'refs -> getrefsto getrefsfrom addcodexref adddataxref delcodexref deldataxref
    'func -> numfuncs() functionstart functionend functionname getname removename setname funcindexfromva funcvabyname
    'code -> imagebase undefine makecode getasm instsize patchbyte orginalbyte readbyte nextea


    txtjs.LoadCallTips App.path & "\api.txt"
    
    If Not txtjs.AddLibFile(App.path & "\userlib.js") Then
        MsgBox "Failed to add userlib?"
    End If
    
    txtjs.userCOMDir = App.path & "\COM"
    If Not txtjs.AddObject(ida, "ida") Then
        MsgBox "Failed to add ida object?"
    End If
    
    If Not txtjs.AddObject(x64, "x64") Then
        MsgBox "Failed to add x64 object?"
    End If
    
    If Not txtjs.AddObject(List1, "list") Then
        MsgBox "Failed to add list object?"
    End If
    
    If Not txtjs.AddObject(remote, "remote") Then
        MsgBox "Failed to add remote client object?"
    End If
    
    If Not txtjs.AddObject(al, "al") Then
        MsgBox "Failed to add address list object?"
    End If
    
    If Not txtjs.AddObject(pb, "pb") Then
        MsgBox "Failed to add progress bar object?"
    End If
    
'    txtjs.DisplayCallTips = True
'    txtjs.WordWrap = True
'    txtjs.ShowIndentationGuide = True
'    txtjs.Folding = True
    
    List1.AddItem "Listening on hwnd: " & Me.hwnd & " (0x" & Hex(Me.hwnd) & ")"
    
    If fso.FolderExists(App.path & "\scripts") Then
        Dim tmp() As String, ci As ComboItem
        Dim f
        tmp = fso.GetFolderFiles(App.path & "\scripts")
        For Each f In tmp
            Set ci = cboSaved.ComboItems.add(, , fso.GetBaseName(CStr(f)))
            ci.Tag = f
        Next
        cboSaved.Text = Empty
    End If
    
    Dim c As String, a As Long, autoConnectHWND As Long, t As String
    
    c = Command
    
    a = InStr(c, "/hwnd=")
    If a > 0 Then
        t = Mid(c, a)
        c = Trim(Replace(c, t, Empty))
        t = Trim(Replace(t, "/hwnd=", Empty))
        autoConnectHWND = CLng(t)
        If IsWindow(autoConnectHWND) = 0 Then autoConnectHWND = 0
    End If
    
    If fso.FileExists(c) Then
        loadedFile = c
        txtjs.LoadFile c
    'ElseIf fso.FileExists(App.path & "\lastScript.txt") Then
        'LoadedFile = App.path & "\lastScript.txt"
        'txtJS.LoadFile LoadedFile
    End If
    
    If autoConnectHWND <> 0 Then
        ida.ipc.RemoteHWND = autoConnectHWND
        idb = ida.loadedFile
        List1.AddItem "IDA Server Up hwnd=" & ida.ipc.RemoteHWND & " (0x" & Hex(ida.ipc.RemoteHWND) & ")"
        List1.AddItem "IDB: " & idb
        lblIDB = "Current IDB: " & fso.FileNameFromPath(idb)
    Else
        windows = ida.ipc.FindActiveIDAWindows()
        If windows = 0 Then
            List1.AddItem "No open IDA Windows detected. Use Tools menu to connect latter."
        ElseIf windows = 1 Then
            ida.ipc.RemoteHWND = ida.ipc.Servers(1)
            idb = ida.loadedFile
            List1.AddItem "IDA Server Up hwnd=" & ida.ipc.RemoteHWND & " (0x" & Hex(ida.ipc.RemoteHWND) & ")"
            List1.AddItem "IDB: " & idb
            lblIDB = "Current IDB: " & fso.FileNameFromPath(idb)
        Else
            hwnd = Form2.SelectIDAInstance()
            If hwnd <> 0 Then
                ida.ipc.RemoteHWND = hwnd
                idb = ida.loadedFile
                List1.AddItem "IDA Server Up hwnd=" & ida.ipc.RemoteHWND & " (0x" & Hex(ida.ipc.RemoteHWND) & ")"
                List1.AddItem "IDB: " & idb
                lblIDB = "Current IDB: " & fso.FileNameFromPath(idb)
            End If
        End If
    End If
    
    List1.Move Text1.Left, Text1.Top, Text1.Width, Text1.Height
    
    x = " Built in classes: ida. fso. app. x64. remote. al. pb. [hitting the dot will display intellisense and open paran codetip intellisense] \n\n" & _
        "global functions: \n\t alert(x), \n\t h(x) [int to hex], \n" & _
        "\t t(x) [append this textbox with x] \n" & _
        "\t d(x) [add x to debug pane list]\n\n" & _
        "Note: you must use correct case for calls to built in objects intellisense will help you."
        
    Text1.Text = Replace(Replace(x, "\n", vbCrLf), "\t", vbTab)
    
End Sub


Private Sub Form_Resize()
    On Error Resume Next
    txtjs.Width = Me.Width - txtjs.Left - 140
    txtjs.Height = Me.Height - txtjs.Top - Frame1.Height - 550
    Frame1.Width = Me.Width - Frame1.Left - 140
    Frame1.Top = txtjs.Top + txtjs.Height - 200
    Text1.Width = Frame1.Width - Text1.Left - 140
    List1.Move Text1.Left, Text1.Top, Text1.Width, Text1.Height
    List1.Width = Text1.Width
    fraSaved.Left = Frame1.Width - 600 - fraSaved.Width
    pb.Width = txtjs.Width
End Sub

Private Sub Form_Unload(Cancel As Integer)
    On Error Resume Next
    Set al = Nothing
    frmAddrList.closing = True
    Unload frmAddrList
    FormPos Me, True, True
    If Len(txtjs.Text) > 2 And sci.isDirty Then
        If Len(loadedFile) > 0 Then
            If InStr(loadedFile, App.path & "\scripts") > 0 Then
                If MsgBox("A Saved script was modified, save changes?", vbYesNo) = vbYes Then
                    fso.writeFile loadedFile, txtjs.Text
                End If
            Else
                fso.writeFile loadedFile, txtjs.Text
            End If
        Else
            ida.writeFile App.path & "\lastScript.txt", txtjs.Text
        End If
    End If
End Sub

Private Sub mnuFormatJS_Click()

'    On Error Resume Next
'    Dim js As String
'
'    js = fso.ReadFile(App.path & "\beautify.js")
'
'    sc2.Reset
'    sc2.AddCode js
'    sc2.AddObject "txtJS", txtjs, True
'    sc2.AddCode "txtJS.text = js_beautify(txtJS.text, {indent_size: 1, indent_char: '\t'}).split('\n').join('\r\n');"
'
'    DoEvents

    On Error Resume Next
    Dim js As String
    Dim c As New Collection
    Dim rv
    Dim duk As CDukTape
    
    'txtjs.Text = "a=0;if(a){a++;}else{a++;}a=0;a=0"
    
    Set duk = New CDukTape
    tmrFormatting.enabled = True
    If Not duk.AddObject(txtjs, "textbox") Then
        Exit Sub
    End If
    
    If Not duk.AddFile(App.path & "\beautify.js") Then
        MsgBox "Could not add beautify.js Error: " & duk.LastError
        Exit Sub
    End If
    
    rv = duk.Eval("js_beautify(textbox.Text, {indent_size: 1, indent_char: '\t'}).split('\n').join('\r\n');")
    
    If duk.HadError Then
        MsgBox "Error running beautify: " & duk.LastError
    Else
        txtjs.Text = rv
    End If
    
End Sub

Private Sub mnuLoadLast_Click()
    On Error Resume Next
    txtjs.LoadFile App.path & "\lastscript.txt"
End Sub

Private Sub mnuOpenScript_Click()
    
    Dim fpath As String
    fpath = dlg.OpenDialog(AllFiles, , , Me.hwnd)
    If Len(fpath) = 0 Then Exit Sub
    
    loadedFile = fpath
    txtjs.LoadFile fpath 'only way to set the readonly modified property to false..
    
End Sub

Private Sub mnuSave_Click()
    
    If Len(loadedFile) > 0 Then
        sci.SaveFile loadedFile
    Else
        mnuSaveAs_Click
    End If
    
End Sub

Private Sub mnuSaveAs_Click()
    
    Dim fpath As String
    Dim ext As String
    ext = ".idajs"
    
    fpath = dlg.SaveDialog(AllFiles)
    If Len(fpath) = 0 Then Exit Sub
    If VBA.Right(fpath, Len(ext)) <> ext Then fpath = fpath & ext
    
    fso.writeFile fpath, txtjs.Text
    txtjs.LoadFile fpath
    
End Sub

Private Sub mnuScintOpts_Click()
    sci.ShowAbout
End Sub

Private Sub mnuSelectIDAInstance_Click()
    Dim hwnd As Long
    Dim idb As String
    
    On Error Resume Next
    hwnd = Form2.SelectIDAInstance()
    If hwnd = 0 Then Exit Sub
    
    ida.ipc.RemoteHWND = hwnd
    idb = ida.loadedFile()
    lblIDB = "Current IDB: " & fso.FileNameFromPath(idb)
    
End Sub

Private Sub mnuSHellExt_Click()
   MsgBox "Registered .idajs file extension: " & register_idajsFileExt()
End Sub



Function FileExists(path) As Boolean
  If Len(path) = 0 Then Exit Function
  If Dir(path, vbHidden Or vbNormal Or vbReadOnly Or vbSystem) <> "" Then FileExists = True _
  Else FileExists = False
End Function

'Private Sub sc_Error()
'
'    On Error Resume Next
'    Dim tmp() As String
'    Dim cCount As Long
'    Dim adjustedLine As Long
'    Dim curLine As Long
'
'    'if showing debug log, switch back to textbox view for error message
'    If Check1.Value Then Check1.Value = 0
'
'    adjustedLine = sc.Error.line - 1   '-1 is for the extra line we add silently for wrappers
'
'    Text1 = "Error on line: " & adjustedLine & vbCrLf & sc.Error.Description
'    sci.GotoLine sc.Error.line
'
'    tmp = Split(txtjs.Text, vbCrLf)
'    For i = 0 To adjustedLine - 1
'        If i = (adjustedLine - 1) Then
'            txtjs.SelStart = cCount
'            txtjs.SelLength = Len(tmp(i))
'            Exit For
'        Else
'            cCount = cCount + Len(tmp(i)) + 2 'for the crlf
'        End If
'    Next
'
'End Sub
 

Private Sub txtJS_FileLoaded(fpath As String)
    Me.caption = "IDAJScript - http://sandsprite.com        File: " & fso.FileNameFromPath(fpath)
End Sub

Private Sub txtjs_dbgOut(msg As String)
    
    If msg = "cls" Then
        Text1.Text = Empty
        Exit Sub
    End If
    
    List1.AddItem "dukDbg> " & msg
    
End Sub

Private Sub txtjs_dukErr(line As Long, msg As String)
    ida.t "dukErr> " & line & " " & msg
    'MsgBox msg
End Sub

Private Sub txtjs_printOut(msg As String)
    ida.t "duk.print> " & msg
End Sub


