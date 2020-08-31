[Setup]
AppName=IdaJSDBG
AppVerName=IdaJSDBG 0.0.1
DefaultDirName=c:\IdaJSDBG
DefaultGroupName=IdaJSDBG
UninstallDisplayIcon={app}\unins000.exe
OutputDir=./
OutputBaseFilename=IdaJSDBG_Setup


[Dirs]
Name: {app}\COM
Name: {app}\scripts
Name: {app}\scripts


[Files]
Source: dukDbg.ocx; DestDir: {app}; Flags: regserver replacesameversion
Source: IDA_JScript.exe; DestDir: {app}; Flags: replacesameversion
Source: spSubclass.dll; DestDir: {app}; Flags: regserver
Source: SciLexer.dll; DestDir: {app}; Flags: replacesameversion
Source: scivb2.ocx; DestDir: {app}; Flags: regserver   replacesameversion
Source: vbDevKit.dll; DestDir: {app}; Flags: regserver
Source: Duk4VB.dll; DestDir: {app}; Flags: replacesameversion
Source: ..\COM\ida.js; DestDir: {app}\COM\
Source: ..\COM\list.js; DestDir: {app}\COM\
Source: ..\COM\TextBox.js; DestDir: {app}\COM\
Source: ..\COM\remote.js; DestDir: {app}\COM\
;Source: ..\scripts\funcCalls.idajs; DestDir: {app}\scripts\
Source: ..\api.txt; DestDir: {app}
Source: ..\beautify.js; DestDir: {app}
Source: ..\java.hilighter; DestDir: {app}
Source: ..\userlib.js; DestDir: {app}
Source: ..\..\IDASrvr\bin\IDASrvr.plw; DestDir: {app}
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
FinishedLabel=Remember to install the plw into your IDA plugins directory.
[Run]
Filename: {app}\IDA_JScript.exe; Parameters: /install; StatusMsg: Installing plw and setting registry keys
