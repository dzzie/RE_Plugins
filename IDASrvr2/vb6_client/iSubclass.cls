VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "iSubclass"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'*************************************************************************************************
'* iSubclass - cSubclass' implementation interface class + enumerations
'*
'* Paul_Caton@hotmail.com
'* Copyright free, use and abuse as you see fit.
'*
'* v1.0 The original..................................................................... 20060322
'*************************************************************************************************

Option Explicit

Sub WndProc(ByVal bBefore As Boolean, ByRef bHandled As Boolean, ByRef lReturn As Long, ByVal lng_hWnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long)
'*************************************************************************************************
'* bBefore  - Indicates whether the callback is before or after the original WndProc. Usually you
'*            will know unless the callback for the uMsg value is specified as MSG_BEFORE_AFTER
'*            (both before and after the original WndProc).
'* bHandled - In a before original WndProc callback, setting bHandled to True will prevent the
'*            message being passed to the original WndProc and (if set to do so) the after
'*            original WndProc callback.
'* lReturn  - WndProc return value. Set as per the MSDN documentation for the message value,
'*            and/or, in an after the original WndProc callback, act on the return value as set
'*            by the original WndProc.
'* hWnd     - Window handle.
'* uMsg     - Message value.
'* wParam   - Message related data.
'* lParam   - Message related data.
'*************************************************************************************************
End Sub

