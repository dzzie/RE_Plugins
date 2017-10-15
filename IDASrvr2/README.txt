

this is a small plugin for IDA that will listen for messages through
a WM_COPYDATA mechanism to allow remote control and data retrieval through
it. 

There are two ways to find the IDASrvr to connect to. For simple cases
the following registry key will always hold the last IDASRVR to open

HKCU\Software\VB and VBA Program Settings\IPC\Handles\IDA_SERVER

A mechanism also exists to locate all open IDASrvr windows by sending
a broadcast message. See VB6 or C# clients for details.  

It handles the following messages

	   0 msg:message
	   1 jmp:lngAdr
	   2 jmp_name:function_name
	   3 name_va:fx_name:hwnd          (returns va for fxname)
	   4 rename:lngva:newname
	   5 loadedfile:Senders_ipc_HWND
	   6 getasm:lngva:HWND
	   7 jmp_rva:lng_rva
	   8 imgbase:Senders_ipc_HWND
	   9 patchbyte:lng_va:byte_newval
	   10 readbyte:lngva:IPCHWND
	   11 orgbyte:lngva:IPCHWND
	   12 refresh:
	   13 numfuncs:IPCHWND
	   14 funcstart:funcIndex:ipchwnd
	   15 funcend:funcIndex:ipchwnd
	   16 funcname:funcIndex:ipchwnd
	   17 setname:va:name
	   18 refsto:offset:hwnd
	   19 refsfrom:offset:hwnd
	   20 undefine:offset
	   21 getname:offset:hwnd
	   22 hide:offset
	   23 show:offset
	   24 remname:offset
           25 makecode:offset
	   26 addcomment:offset:comment (non repeatable)
	   27 getcomment:offset:hwnd    (non repeatable)
	   28 addcodexref:offset:tova
	   29 adddataxref:offset:tova
	   30 delcodexref:offset:tova
	   31 deldataxref:offset:tova
	   32 funcindex:va:hwnd
	   33 nextea:va:hwnd
	   34 prevea:va:hwnd
	   35 makestring:va:[ascii | unicode]
	   36 makeunk:va:size


compiles with vs2008 Express, make sure IDASDK envirnoment variable is set to your
root sdk directory or you will have to fix include and lib directories in project.

clients are provided for a variety of languages see sub directories.