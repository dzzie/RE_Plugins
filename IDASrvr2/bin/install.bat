@echo off
::full paths for postbuild in VS

set pth=C:\IDA7.5\plugins\idasrvr2.dll

IF NOT EXIST C:\IDA7.5 GOTO NO75
echo Installing for 7.5
IF EXIST %pth% del %pth%
copy D:\IDASrvr3\bin\idasrvr2.dll C:\IDA7.5\plugins\
copy D:\IDASrvr3\bin\idasrvr2_64.dll C:\IDA7.5\plugins\
:NO75

pause