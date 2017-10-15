
Status: late beta
Link:   http://sandsprite.com/tools.php?id=25

what is this? 
----------------------------------------

This is a standalone interface to interact and script commands sent to IDA
through the IDASrvr plugin using Javascript.

The installer will:
   register all dependancies
   register the idajs file extension 
   install the IDA plw plugin

This build uses the duktape javascript engine, built for use with vb6, and housed
in an ocx control that provides full debugger support with single stepping,
breakpoints, mouse over variable tool tips etc.

The interface uses the scintinella control which provides syntax highlighting,
intellisense, and tool tip prototypes for the IDA api which it provides. It has
been deisgned as an out of process UI for ease of development and so more 
complex features could be added.

Should support most of the commonly used api. If you need to get fancy its easy
to add more features using the template.

When IDA_jscript first starts, it will enumerate active IDASrvr instances. If
its only one active it will automatically connect to it, else it will prompt you
to select which one to interact with.

For the ida function list see file api.api it has all the prototypes.
The main class to access these functions is "ida." 

There are a couple wrapped functions available by default without a class
prefix. 

h(x) convert x to hex //no error handling in this yet..also high numbers can overflow error (dll addr)
alert(x) supports arrays and other types
t(x) appends x to the output textbox on main form.


Dependancies and Source Links:
-------------------------------------------------------------

IDAJS is all open source

duk4vb:       https://github.com/dzzie/duk4vb
scivb:        https://github.com/dzzie/scivb2
idasrvr:      https://github.com/dzzie/RE_Plugins/tree/master/IDASrvr
idajs:        https://github.com/dzzie/RE_Plugins/tree/master/IDA_JScript_w_DukDbg
spSubclass:   https://github.com/dzzie/libs/tree/master/Subclass
vbdevKit:     https://github.com/dzzie/libs/tree/master/vbDevKit

dependancies:
   dukDbg.ocx     - Activex
   spSubclass.dll - ActiveX 
   SCIVB2.ocx     - ActiveX 
   vbDevKit.dll   - ActiveX
   Duk4VB.dll     - C dll must be in same dir as dukDbg.ocx
   SciLexer.dll   - C dll must be in same dir as SCIVBX.ocx
   IDASrvr.plw    - IDA plugin installed by installer
   MSWINSCK.OCX   - from MS included in installer
   richtx32.ocx   - from MS included in installer
   vb6 runtimes   - from MS assumed already installed
   mscomctl.ocx   - from MS assumed already installed
   
An installer can be found in the binary_snapshot directory to register
all dependancies.



Credits:
--------------------------------------------

* Duktape   
     http://duktape.org

* Scintilla by Neil Hodgson [neilh@scintilla.org] 
     http://www.scintilla.org/

* ScintillaVB by Stu Collier 
     http://www.ceditmx.com/software/scintilla-vb/

* CSubclass by Paul Canton [Paul_Caton@hotmail.com]

* Interface by David Zimmer 
    http://sandsprite.com




