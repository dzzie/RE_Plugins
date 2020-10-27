VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCTL.OCX"
Begin VB.Form frmIDACompare 
   Caption         =   "IDA Compare"
   ClientHeight    =   5775
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   12270
   Icon            =   "frmIDACompare.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   5775
   ScaleWidth      =   12270
   StartUpPosition =   2  'CenterScreen
   Begin VB.CommandButton cmdAbort 
      Caption         =   "abort"
      Height          =   330
      Left            =   11295
      TabIndex        =   13
      Top             =   90
      Width           =   780
   End
   Begin Project1.ucFilterList lv 
      Height          =   4785
      Left            =   2115
      TabIndex        =   12
      Top             =   810
      Width           =   10005
      _ExtentX        =   17648
      _ExtentY        =   8440
   End
   Begin MSComctlLib.ProgressBar pb 
      Height          =   255
      Left            =   2115
      TabIndex        =   7
      Top             =   540
      Width           =   10035
      _ExtentX        =   17701
      _ExtentY        =   450
      _Version        =   393216
      Appearance      =   1
   End
   Begin VB.CommandButton Command2 
      Caption         =   "select"
      Height          =   345
      Left            =   10410
      TabIndex        =   5
      Top             =   45
      Width           =   735
   End
   Begin VB.CommandButton Command1 
      Caption         =   "new"
      Height          =   345
      Left            =   9495
      TabIndex        =   3
      Top             =   45
      Width           =   735
   End
   Begin VB.TextBox txtDB 
      Height          =   315
      Left            =   1125
      OLEDropMode     =   1  'Manual
      TabIndex        =   2
      Top             =   60
      Width           =   8205
   End
   Begin VB.Frame Frame1 
      Height          =   3450
      Left            =   0
      TabIndex        =   0
      Top             =   420
      Width           =   2055
      Begin VB.CommandButton cmdImportNames 
         Caption         =   "Import Match Names"
         Height          =   375
         Left            =   120
         TabIndex        =   11
         Top             =   2970
         Width           =   1815
      End
      Begin VB.CommandButton cmdCompare 
         Caption         =   "Launch Signature Scan"
         Height          =   375
         Index           =   1
         Left            =   135
         TabIndex        =   10
         Top             =   2340
         Width           =   1815
      End
      Begin VB.CommandButton cmdAddSignature 
         Caption         =   "Add Sel to Signatures"
         Height          =   375
         Left            =   120
         TabIndex        =   9
         Top             =   1845
         Width           =   1815
      End
      Begin VB.CommandButton cmdCompare 
         Caption         =   "Launch Compare UI"
         Height          =   375
         Index           =   0
         Left            =   120
         TabIndex        =   8
         Top             =   1170
         Width           =   1815
      End
      Begin VB.CommandButton cmdExport 
         Caption         =   "Save Compare Snap 2"
         Height          =   375
         Index           =   1
         Left            =   135
         TabIndex        =   6
         Top             =   675
         Width           =   1815
      End
      Begin VB.CommandButton cmdExport 
         Caption         =   "Save Compare Snap 1"
         Height          =   375
         Index           =   0
         Left            =   135
         TabIndex        =   4
         Top             =   180
         Width           =   1815
      End
      Begin VB.Line Line1 
         BorderColor     =   &H00404040&
         BorderStyle     =   6  'Inside Solid
         DrawMode        =   7  'Invert
         Index           =   1
         X1              =   180
         X2              =   1800
         Y1              =   2835
         Y2              =   2835
      End
      Begin VB.Line Line1 
         BorderColor     =   &H00404040&
         BorderStyle     =   6  'Inside Solid
         DrawMode        =   7  'Invert
         Index           =   0
         X1              =   180
         X2              =   1800
         Y1              =   1665
         Y2              =   1665
      End
   End
   Begin VB.Label Label1 
      Caption         =   "Current MDB"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   -1  'True
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FF0000&
      Height          =   255
      Left            =   120
      TabIndex        =   1
      Top             =   120
      Width           =   1215
   End
   Begin VB.Menu mnuPopup 
      Caption         =   "mnuPopup"
      Visible         =   0   'False
      Begin VB.Menu mnuCheckAll 
         Caption         =   "Select All"
         Index           =   0
      End
      Begin VB.Menu mnuCheckAll 
         Caption         =   "Select None"
         Index           =   1
      End
      Begin VB.Menu mnuCheckAll 
         Caption         =   "Invert Selection"
         Index           =   2
      End
      Begin VB.Menu mnuCheckAll 
         Caption         =   "Remove Selected"
         Index           =   3
      End
      Begin VB.Menu mnuCheckAll 
         Caption         =   "Remove UnSelected"
         Index           =   4
      End
   End
End
Attribute VB_Name = "frmIDACompare"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'Author: david@idefense.com <david@idefense.com, dzzie@yahoo.com>
'
'License: Copyright (C) 2005 iDefense.com, A Verisign Company
'
'         This program is free software; you can redistribute it and/or modify it
'         under the terms of the GNU General Public License as published by the Free
'         Software Foundation; either version 2 of the License, or (at your option)
'         any later version.
'
'         This program is distributed in the hope that it will be useful, but WITHOUT
'         ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
'         FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
'         more details.
'
'         You should have received a copy of the GNU General Public License along with
'         this program; if not, write to the Free Software Foundation, Inc., 59 Temple
'         Place, Suite 330, Boston, MA 02111-1307 USA

'added support 64 bit disassemblies (still requires 32 bit IDA) 3.6.14 -dzzie

Public cn As New Connection
Public dlg As New clsCmnDlg
Dim x64Mode As Boolean
Public abort As Boolean

Private exportedA As Boolean
Private exportedB As Boolean

Enum ExportModes
    compare1 = 0
    Compare2 = 1
    SignatureMode = 2
    TmpMode = 3
End Enum
'
'
'Private Sub cmdAddSignature_Click()
'    DoExport SignatureMode
'End Sub
'
'Private Sub cmdCompare_Click(index As Integer)
'    On Error GoTo hell
'    Dim pth As String
'    Dim exe As String
'    Dim r As Long, rr As Long
'
'    If index = 0 Then
'        pth = txtDB
'    Else
'        pth = DllPath & "signatures.mdb"
'        If Not FileExists(pth) Then
'            MsgBox "Could not find signature database?: " & vbCrLf & vbCrLf & pth, vbInformation
'            Exit Sub
'        End If
'        If OpenDB(cn, pth) Then
'            r = cn.Execute("Select count(autoid) as cnt from signatures")!cnt
'            If r < 1 Then
'                MsgBox "You have not yet added any signatures to scan for", vbInformation
'                cn.Close
'                Exit Sub
'            End If
'            cn.Execute "Delete from tmp" 'clear out any old tmp data
'            cn.Close
'        End If
'    End If
'
'    If Not FileExists(pth) Then
'        MsgBox "Could not locate DB, """ & pth & """", vbInformation
'        Exit Sub
'    End If
'
'    If index = 1 Then     'save current db functions to tmp table for compare
'        DoExport TmpMode  'to make sure saved and in same db as signatures so cheat
'    End If
'
'    exe = DllPath & "ida_compare.exe"
'
'    If Not FileExists(exe) Then
'        MsgBox "Could not locate ida_compare?" & vbCrLf & vbCrLf & exe, vbInformation
'        Exit Sub
'    End If
'
'    exe = exe & " """ & pth & """" & IIf(index = 0, "", " /sigscan")
'
'    Shell exe, vbNormalFocus
'    Me.WindowState = vbMinimized
'    'minimize ida
'
'Exit Sub
'hell: MsgBox "Line: " & Erl & " Desc:" & Err.Description
'
'End Sub
'
'Private Sub cmdExport_Click(index As Integer)
'    Dim mode As ExportModes
'
'    mode = index
'
'    If mode = Compare2 And exportedA Then
'        If MsgBox("You already saved this idb to table A do " & vbCrLf & _
'                  "you really want to save the same idb to " & vbCrLf & _
'                  "table b as well to compare it with?", vbYesNo) = vbNo Then
'            Exit Sub
'        End If
'    End If
'
'    If mode = compare1 And exportedB Then
'         If MsgBox("You already saved this idb to table B do " & vbCrLf & _
'                   "you really want to save the same idb to " & vbCrLf & _
'                   " table A as well to compare it with?", vbYesNo) = vbNo Then
'            Exit Sub
'        End If
'    End If
'
'    DoExport mode
'End Sub
'
'Private Sub cmdImportNames_Click()
'    On Error Resume Next
'
'    Dim idba, idbb, curidb
'    Dim isTableA As Boolean
'    Dim sigMode, activeTable
'    Dim warned As Boolean
'    Dim ignoreIt As Boolean
'
'    curidb = LCase(FileNameFromPath(loadedFile))
'
'    If Len(cn.ConnectionString) = 0 Then  'hasnt been opened yet
'        If Not FileExists(txtDB) Then
'            MsgBox "There is no database currently active", vbInformation
'            Exit Sub
'        Else
'            If Not OpenDB(cn, txtDB) Then Exit Sub
'        End If
'    Else
'        OpenDB cn, Empty 'use existing connection string
'    End If
'
'    sigMode = IIf(InStr(1, cn.ConnectionString, "signatures.mdb", vbTextCompare) > 0, True, False)
'
'    If Not sigMode Then
'        idba = FileNameFromPath(LCase(cn.Execute("Select top 1 idb from a")!idb))
'        idbb = FileNameFromPath(LCase(cn.Execute("Select top 1 idb from b")!idb))
'
'        If idba = curidb And LCase(idba) = LCase(idbb) Then
'            Dim x As VbMsgBoxResult
'
'            x = MsgBox("Both disassemblies in this database have the same filename." & _
'                        vbCrLf & vbCrLf & "Would you like to import the names from Snapshot 1?", vbYesNoCancel)
'
'            If x = vbCancel Then Exit Sub
'            activeTable = IIf(x = vbYes, "a", "b")
'
'        ElseIf idba = curidb Then
'            activeTable = "a"
'        ElseIf idbb <> curidb Then
'            MsgBox "Could not find an entry for the current idb in this database!" & vbCrLf & vbCrLf & _
'                   "CurDB: " & curidb & vbCrLf & _
'                   "IDB_A: " & idba & vbCrLf & _
'                   "IDB_B: " & idbb
'            Exit Sub
'        Else
'            activeTable = "b"
'        End If
'    Else
'        idba = LCase(cn.Execute("Select top 1 idb from tmp")!idb)
'        activeTable = "tmp"
'        If idba <> curidb Then
'            MsgBox "Could not find an entry for the current idb in this database!"
'            Exit Sub
'        End If
'    End If
'
'    Dim rs As Recordset
'    Dim errors()
'
'    Set rs = cn.Execute("Select * from " & activeTable & " where len(newName)>0")
'
'    If rs Is Nothing Then
'        MsgBox "No records had newNames to import"
'        Exit Sub
'    End If
'
'    Dim startEa As String, orgName As String, fname As String
'    Dim count As Long, ret As Long
'
'    While Not rs.EOF
'        startEa = rs!startEa
'        orgName = LCase(Trim(rs!fname))
'        fname = Trim(LCase(GetFName(startEa)))
'        count = count + 1
'
'        'MsgBox "Org " & orgName & "(" & Len(orgName) & ") Cur " & fname & "(" & Len(fname) & ")"
'        'MsgBox Len(fname)
'
'        If fname <> orgName Then
'            If Not warned Then
'                warned = True
'                If MsgBox("Did not find expected function name at offset " & Hex(startEa) & vbCrLf & vbCrLf & _
'                            "Expecting function name: " & orgName & " Found: " & fname & vbCrLf & vbCrLf & _
'                            "Do you want to process it? This answer will be used for any future checks", vbYesNo) = vbYes Then
'                    ignoreIt = True
'                End If
'            End If
'
'            If ignoreIt Then
'                ret = setname(startEa, CStr(rs!newName))
'                If ret <> 1 Then
'                    push errors, "Couldnt rename offset " & Hex(startEa) & " to " & rs!newName & " - SetName returned " & ret
'                Else
'                    cn.Execute "Update " & activeTable & " set fname='" & CStr(rs!newName) & "' , newName='' where startEa='" & startEa & "'"
'                End If
'            Else
'                push errors, "Couldnt rename offset " & Hex(startEa) & " - name didnt match expected"
'            End If
'
'        Else
'            ret = setname(startEa, CStr(rs!newName))
'            If ret <> 1 Then
'                push errors, "Couldnt rename offset " & Hex(startEa) & " to " & rs!newName & " - SetName returned " & ret
'            Else
'                cn.Execute "Update " & activeTable & " set fname='" & CStr(rs!newName) & "' , newName='' where startEa='" & startEa & "'"
'            End If
'        End If
'        rs.MoveNext
'    Wend
'
'    Dim tmp
'    tmp = Join(errors, vbCrLf)
'    If Len(tmp) > 2 Then
'        MsgBox count & " Imports done with " & UBound(errors) & " Errors: " & vbCrLf & vbCrLf & tmp, vbInformation
'    Else
'        MsgBox count & " Import Done!"
'    End If
'
'    refresh
'
'
'End Sub
'
'Private Sub Command1_Click()
'    Dim pth As String
'    Dim base As String
'
'    On Error GoTo hell
'
'    'base = DllPath & "blank.mdb"
'    base = App.path & "\blank.mdb"
'
'    If Not FileExists(base) Then
'        MsgBox "Could not find blank database to use:" & vbCrLf & vbCrLf & _
'               base, vbInformation

Private Sub cmdAbort_Click()
    abort = True
End Sub

'        Exit Sub
'    End If
'
'    pth = dlg.SaveDialog(CustomFilter, , "Save new DB as..", , Me.hwnd)
'    If Len(pth) = 0 Then Exit Sub
'    If LCase(VBA.Right(pth, 4)) <> ".mdb" Then pth = pth & ".mdb"
'
'    FileCopy base, pth
'    txtDB = pth
'    SaveSetting "IdaCompare", "settings", "txtdb", txtDB.Text
'
'    exportedA = False
'    exportedB = False
'
'    Exit Sub
'hell:
'    MsgBox Err.Description
'End Sub
'
'Private Sub Command2_Click()
'    Dim pth As String
'    pth = dlg.OpenDialog(CustomFilter, , "Select existing db to export to", Me.hwnd)
'    If Len(pth) = 0 Then Exit Sub
'    exportedA = False
'    exportedB = False
'    txtDB = pth
'    SaveSetting "IdaCompare", "settings", "txtdb", txtDB.Text
'End Sub
'
'
'
Private Sub Form_Load()
    On Error Resume Next
    
    Dim li As ListItem
    Dim cnt As Long, i As Long
    Dim startPos As String, endPos As String, j As Long
    Dim path As String, tmp, X() As String, count As Long
    
    Me.Icon = Form1.Icon
    lv.SetColumnHeaders "n,Start,End,Size,Name*,Refs", "600,1605,1650,1020,2790,1440"

    x64Mode = Form1.ida.is64BitMode

    txtDB = GetSetting("IdaCompare", "settings", "txtdb")
    If Not fso.FileExists(txtDB) Then txtDB = Empty

    dlg.SetCustomFilter "Access Database (*.mdb)", "*.mdb"
    
    Me.Visible = True
    Me.caption = "Getting function map..."
    Me.refresh
    
    StartBenchMark
    path = Form1.ida.funcMap(count)
    If Len(path) = 0 Then
        MsgBox "Dumping function map failed from: " & Form1.ida.loadedFile, vbInformation
        Unload Me
        Exit Sub
    End If
    
    lv.Clear
    lv.LockUpdate = True
    pb.Max = count
    pb.value = 0
    Me.caption = "Loading stats for " & count & " functions..."
    abort = False
    
    i = FreeFile
    Open path For Input As i
    Do
         Line Input #i, tmp
         If Len(tmp) > 0 Then
            X = Split(tmp, ",") '    'i, name.c_str(), ua1, ua2, (fu->end_ea - fu->start_ea), fu->referers);
            If CLng(X(4)) > 60 Then
                lv.AddItem X(0), X(2), X(3), X(4), X(1), X(5) '9 sec for 550 func
'                Set li = lv2.ListItems.add(, , x(0)) 'still took 9 seconds w/direct access confirmed with second lv
            Else
                j = j + 1
            End If
         End If
         pb.value = pb.value + 1
         DoEvents
         If abort Then Exit Do
    Loop While Not EOF(i)
    Close i
    
    '8.75 sec but could suck on giant idbs
'    Dim dat() As String
'    dat = Split(fso.readFile(path), vbCrLf)
'    For Each tmp In dat
'        If Len(tmp) > 0 Then
'            x = Split(tmp, ",") '    'i, name.c_str(), ua1, ua2, (fu->end_ea - fu->start_ea), fu->referers);
'            If CLng("&h" & Mid(x(4), 3)) > 60 Then
'                lv.AddItem x(0), x(2), x(3), x(4), x(1), x(5) '9 sec for 550 func
''                Set li = lv2.ListItems.add(, , x(0)) 'still took 9 seconds w/direct access
'            Else
'                j = j + 1
'            End If
'         End If
'         pb.value = pb.value + 1
'         DoEvents
'    Next
    
    lv.LockUpdate = False
    pb.value = 0
    Me.caption = Me.caption & IIf(x64Mode, " (64 bit)", " (32 Bit)") & " - ignored " & j & " func < 60 bytes - " & EndBenchMark
    
End Sub

'
'
'
'Sub DoExport(mode As ExportModes)
'    On Error GoTo hell
'
'    Dim leng As Long, start As String
'    Dim buf() As Byte
'    Dim pth As String
'    Dim bytes As String
'    Dim asm As String
'    Dim tbl As String
'    Dim cnt As Long
'    Dim idb As String
'    Dim li As ListItem
'    Dim selLv As ListView
'
'    If lvFiltered.Visible Then
'        Set selLv = lvFiltered
'    Else
'         Set selLv = lv
'    End If
'
'    If mode >= SignatureMode Then
'        pth = DllPath & "signatures.mdb"
'        'MsgBox "Signature mode db=" & pth & " Exists?: " & FileExists(pth)
'    Else
'        pth = txtDB
'        exportedA = IIf(mode = compare1, True, exportedA)
'        exportedB = IIf(mode = compare1, exportedB, True)
'    End If
'
'    If Not FileExists(pth) Then
'        MsgBox "File not found, select mdb: " & pth, vbInformation
'        Exit Sub
'    End If
'
'    OpenDB cn, pth
'
'    Select Case mode
'        Case compare1:      tbl = "a"
'        Case Compare2:      tbl = "b"
'        Case SignatureMode: tbl = "signatures"
'        Case TmpMode:       tbl = "tmp"
'    End Select
'
'    If mode < SignatureMode Then
'        cnt = cn.Execute("Select count(autoid) as cnt from " & tbl)!cnt
'        If cnt > 0 Then
'            idb = cn.Execute("Select top 1 idb from " & tbl)!idb
'            If MsgBox("Table " & tbl & " is already full of data overwrite?" & vbCrLf & vbCrLf & idb, vbYesNo) = vbNo Then
'                Exit Sub
'            Else
'                cn.Execute "Delete from " & tbl
'            End If
'        End If
'    ElseIf mode = TmpMode Then
'        cn.Execute "Delete from " & tbl
'    End If
'
'    pb.value = 0
'    pb.Max = selLv.ListItems.count
'
'    'idb = FileNameFromPath(loadedFile)
'    idb = loadedFile()
'    If Len(idb) > 254 Then idb = Right(idb, 254) 'in case its a binary of the same name but different paths...
'    If Len(idb) = 0 Then idb = "sample" 'maybe they loaded a lib file?
'
'    For Each li In selLv.ListItems
'
'        If mode = SignatureMode And Not li.selected Then GoTo nextOne
'
'1        leng = li.subItems(3)
'2        start = li.subItems(1)
'3        bytes = HexDumpBytes(start, leng) 'debug me
'4        asm = GetAsmRange(start, leng)  'debug me
'5        Insert cn, tbl, "idb,bytes,disasm,index,leng,fname,startEA", idb, bytes, asm, li.Text, leng, li.subItems(4), start
'
'nextOne:
'6        pb.value = pb.value + 1
'    Next
'
'    pb.value = 0
'    If mode <> TmpMode Then MsgBox "Functions saved to mdb", vbInformation
'
'Exit Sub
'hell: MsgBox "Error in DoExport: Line: " & Erl() & " Description: " & Err.Description
'End Sub
'
'Private Sub Form_Unload(Cancel As Integer)
'    On Error Resume Next
'    cn.Close
'    Set dlg = Nothing
'End Sub
'
'Private Sub Label1_Click()
'
'    On Error Resume Next
'    Dim idba, idbb, curidb, sigMode
'
'    curidb = loadedFile
'
'    If Len(cn.ConnectionString) = 0 Then  'hasnt been opened yet
'        If Not FileExists(txtDB) Then
'            MsgBox "There is no database currently active", vbInformation
'            Exit Sub
'        Else
'            If Not OpenDB(cn, txtDB) Then Exit Sub
'        End If
'    Else
'        OpenDB cn, Empty 'use existing connection string
'    End If
'
'    sigMode = IIf(InStr(1, cn.ConnectionString, "signatures.mdb", vbTextCompare) > 0, True, False)
'
'    If Not sigMode Then
'        idba = cn.Execute("Select top 1 idb from a")!idb
'        idbb = cn.Execute("Select top 1 idb from b")!idb
'
'        MsgBox "Cur_Idb: " & curidb & vbCrLf & _
'               "Table 1: " & idba & vbCrLf & _
'               "Table 2: " & idbb, vbInformation
'
'    Else
'        MsgBox "Cur_Idb: " & curidb & vbCrLf & "Signature scan mode", vbInformation
'    End If
'
'
'End Sub
'
'Private Sub lv_MouseUp(Button As Integer, Shift As Integer, x As Single, Y As Single)
'    If Button = 2 Then PopupMenu mnuPopup
'End Sub
'
'Private Sub mnuCheckAll_Click(index As Integer)
'
'    Dim li As ListItem
'
'top:
'    For Each li In lv.ListItems
'        Select Case index
'            Case 0: li.selected = True
'            Case 1: li.selected = False
'            Case 2: li.selected = Not li.selected
'            Case 3: If li.selected Then lv.ListItems.Remove li.index: GoTo top
'            Case 4: If Not li.selected Then lv.ListItems.Remove li.index: GoTo top
'        End Select
'    Next
'
'End Sub
'
'Private Sub txtDB_OLEDragDrop(Data As DataObject, Effect As Long, Button As Integer, Shift As Integer, x As Single, Y As Single)
'    On Error Resume Next
'    txtDB = Data.Files(1)
'End Sub
'
'Private Sub txtFilter_Change()
'
'    On Error Resume Next
'    Dim isNegatedSearch As Boolean
'    Dim filtText As String
'
'    If Len(txtFilter) = 0 Then
'        lvFiltered.Visible = False
'        Exit Sub
'    End If
'
'    lvFiltered.ListItems.Clear
'    lvFiltered.Visible = True
'
'    pb.value = 0
'    pb.Max = lv.ListItems.count
'
'    If VBA.Left(txtFilter, 1) = "-" Then
'        If Len(txtFilter) = 1 Then Exit Sub
'        isNegatedSearch = True
'        filtText = Mid(txtFilter, 2)
'    Else
'        filtText = txtFilter
'    End If
'
'    Dim li As ListItem
'    For Each li In lv.ListItems
'
'        If isNegatedSearch Then
'            If InStr(1, li.subItems(4), filtText, vbTextCompare) < 1 Then
'                copyLiToFiltered li
'            End If
'        Else
'            If InStr(1, li.subItems(4), txtFilter, vbTextCompare) > 0 Then
'                copyLiToFiltered li
'            End If
'        End If
'
'        If pb.Max > 500 And pb.value Mod 10 = 0 Then
'            'only useful for large sample sets.. otherwise just slows us down..
'            pb.value = pb.value + 1
'        End If
'    Next
'
'    pb.value = 0
'
'End Sub
'
'
'Sub copyLiToFiltered(li As ListItem)
'    Dim lif As ListItem
'    Dim i As Long
'    On Error Resume Next
'
'    Set lif = lvFiltered.ListItems.add(, , li.Text)
'
'    For i = 1 To lv.ColumnHeaders.count
'        lif.subItems(i) = li.subItems(i)
'    Next
'
'End Sub
'
