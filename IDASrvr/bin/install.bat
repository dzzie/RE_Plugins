@echo off

set pth=C:\IDA6.5\plugins\idasrvr.plw

IF NOT EXIST C:\IDA6.5 GOTO NO65
echo Installing for 6.5
IF EXIST %pth% del %pth%
copy D:\_code\RE_Plugins\IDASrvr\bin\idasrvr.plw C:\IDA6.5\plugins\

:NO65

set pth=C:\IDA6.6\plugins\idasrvr.plw

IF NOT EXIST C:\IDA6.6 GOTO NO66
echo Installing for 6.6
IF EXIST %pth% del %pth%
copy D:\_code\RE_Plugins\IDASrvr\bin\idasrvr.plw C:\IDA6.6\plugins\

:NO66

set pth=D:\IDA6.7\plugins\idasrvr.plw

IF NOT EXIST D:\IDA6.7 GOTO NO67
echo Installing for 6.7
IF EXIST %pth% del %pth%
copy D:\_code\RE_Plugins\IDASrvr\bin\idasrvr.plw D:\IDA6.7\plugins\

:NO67

set pth=C:\IDA\plugins\idasrvr.plw

IF NOT EXIST C:\IDA GOTO NO5
echo Installing for c:\IDA
IF EXIST %pth% del %pth%
copy D:\_code\RE_Plugins\IDASrvr\bin\idasrvr.plw C:\IDA\plugins\

:NO5

if not exist D:\_code\iDef\IDACompare goto NO
echo Installing for IDAcompare
copy D:\_code\RE_Plugins\IDASrvr\bin\idasrvr.plw D:\_code\iDef\IDACompare\

:NO

pause