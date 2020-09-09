[Setup]
AppName=IDAJS
AppVerName=IDAJS v2 Beta (x64 IDA >= 7.0)
DefaultDirName=c:\IDAJS2
DefaultGroupName=IDAJS
UninstallDisplayIcon={app}\unins000.exe
OutputDir=./
OutputBaseFilename=IDAJS_2_Setup


[Dirs]
Name: {app}\COM
Name: {app}\scripts


[Files]
Source: Duk4VB.dll; DestDir: {app}; Flags: replacesameversion
Source: dukDbg.ocx; DestDir: {app}; Flags: regserver replacesameversion
Source: IDA_JScript.exe; DestDir: {app}; Flags: replacesameversion
Source: spSubclass.dll; DestDir: {app}; Flags: regserver
Source: SciLexer.dll; DestDir: {app}; Flags: replacesameversion
Source: scivb2.ocx; DestDir: {app}; Flags: regserver   replacesameversion
Source: UTypes.dll; DestDir: {app}; Flags: replacesameversion
Source: vbUtypes.dll; DestDir: {app}; Flags: regserver replacesameversion
Source: vbDevKit.dll; DestDir: {app}; Flags: regserver
Source: ..\COM\ida.js; DestDir: {app}\COM\
Source: ..\COM\x64.js; DestDir: {app}\COM\
Source: ..\COM\list.js; DestDir: {app}\COM\
Source: ..\COM\TextBox.js; DestDir: {app}\COM\
Source: ..\COM\remote.js; DestDir: {app}\COM\
Source: ..\COM\x64.js; DestDir: {app}\COM\
;Source: ..\scripts\funcCalls.idajs; DestDir: {app}\scripts\
Source: ..\api.txt; DestDir: {app}
Source: ..\beautify.js; DestDir: {app}
Source: ..\java.hilighter; DestDir: {app}
Source: ..\userlib.js; DestDir: {app}
Source: ..\..\IDASrvr2\bin\IDASrvr2.dll; DestDir: {app}
Source: ..\..\IDASrvr2\bin\IDASrvr2_64.dll; DestDir: {app}
;Source: MSCOMCTL.OCX; DestDir: {win}; Flags: regserver uninsneveruninstall
Source: richtx32.ocx; DestDir: {sys}; Flags: regserver uninsneveruninstall
Source: MSWINSCK.OCX; DestDir: {sys}; Flags: regserver uninsneveruninstall
Source: ..\readme.txt; DestDir: {app}
Source: ..\scripts\cur_func_bytes.idajs; DestDir: {app}\scripts\
Source: ..\scripts\emit_cur_func.idajs; DestDir: {app}\scripts\
Source: ..\scripts\emit_with_disasm.idajs; DestDir: {app}\scripts\
Source: ..\scripts\extractFuncNames.idajs; DestDir: {app}\scripts\
Source: ..\scripts\extractNamesRange.idajs; DestDir: {app}\scripts\
Source: ..\scripts\extractNamesRange2.idajs; DestDir: {app}\scripts\
Source: ..\scripts\funcCalls.idajs; DestDir: {app}\scripts\
Source: ..\scripts\prefix_small.idajs; DestDir: {app}\scripts\
Source: ..\scripts\user_funcs.idajs; DestDir: {app}\scripts\

[Icons]
Name: {group}\IDA_Jscript; Filename: {app}\IDA_JScript.exe
Name: {group}\Uninstall; Filename: {app}\unins000.exe
Name: {group}\Readme.txt; Filename: {app}\readme.txt
;Name: {userdesktop}\IDA_Jscript; Filename: {app}\IDA_Jscript.exe; IconIndex: 0


[Messages]
FinishedLabel=Remember to install the IDA plugins!.
[Run]
Filename: {app}\IDA_JScript.exe; Parameters: /install; StatusMsg: Installing plw and setting registry keys
