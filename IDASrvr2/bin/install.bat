@echo off
::full paths for postbuild in VS

set p1=C:\IDA7.5\plugins\idasrvr2.dll
set p2=C:\IDA7.5\plugins\\idasrvr2_64.dll

IF NOT EXIST C:\IDA7.5 GOTO NO75
echo Installing for 7.5
IF EXIST %p1% del %p1%
IF EXIST %p2% del %p2%
copy D:\_code\RE_Plugins\IDASrvr2\bin\idasrvr2.dll C:\IDA7.5\plugins\
copy D:\_code\RE_Plugins\IDASrvr2\bin\idasrvr2_64.dll C:\IDA7.5\plugins\
:NO75

pause