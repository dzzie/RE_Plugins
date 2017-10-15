@echo off

set pth=C:\IDA6.5\plugins\idasrvr2.plw

IF NOT EXIST C:\IDA6.5 GOTO NO65
echo Installing for 6.5
IF EXIST %pth% del %pth%
copy D:\_code\RE_Plugins\IDASrvr2\bin\idasrvr2.plw C:\IDA6.5\plugins\
copy D:\_code\RE_Plugins\IDASrvr2\bin\idasrvr2.p64 C:\IDA6.5\plugins\
:NO65

set pth=C:\IDA6.6\plugins\idasrvr2.plw

IF NOT EXIST C:\IDA6.6 GOTO NO66
echo Installing for 6.6
IF EXIST %pth% del %pth%
copy D:\_code\RE_Plugins\IDASrvr2\bin\idasrvr2.plw C:\IDA6.6\plugins\
copy D:\_code\RE_Plugins\IDASrvr2\bin\idasrvr2.p64 C:\IDA6.6\plugins\

:NO66

set pth=D:\IDA6.7\plugins\idasrvr2.plw

IF NOT EXIST D:\IDA6.7 GOTO NO67
echo Installing for 6.7
IF EXIST %pth% del %pth%
copy D:\_code\RE_Plugins\IDASrvr2\bin\idasrvr2.plw D:\IDA6.7\plugins\
copy D:\_code\RE_Plugins\IDASrvr2\bin\idasrvr2.p64 D:\IDA6.7\plugins\

:NO67

set pth=C:\IDA\plugins\idasrvr2.plw

IF NOT EXIST C:\IDA GOTO NO5
echo Installing for c:\IDA
IF EXIST %pth% del %pth%
copy D:\_code\RE_Plugins\IDASrvr2\bin\idasrvr2.plw C:\IDA\plugins\
copy D:\_code\RE_Plugins\IDASrvr2\bin\idasrvr2.p64 C:\IDA\plugins\

:NO5
GOTO NO

if not exist D:\_code\iDef\IDACompare goto NO
echo Installing for IDAcompare
copy D:\_code\RE_Plugins\IDASrvr2\bin\idasrvr2.plw D:\_code\iDef\IDACompare\
copy D:\_code\RE_Plugins\IDASrvr2\bin\idasrvr2.p64 D:\_code\iDef\IDACompare\

:NO

pause