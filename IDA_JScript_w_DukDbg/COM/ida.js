/*
	Property get isUp As Boolean
	Property get timeout As Long
	Property let timeout As Long
	Sub Caption(msg)
	sub do_events()
	Function alert(msg)
	Function Message(msg As String)
	Function MakeStr(va,  ascii As Boolean = True)
	Function MakeUnk(va, size)
	Property get LoadedFile As String
	Sub t(data As String)
	Sub ClearLog()
	Function PatchString(va, str,  isUnicode = False)
	Function PatchByte(va, newVal)
	Function intToHex(x)
	Function GetAsm(va)
	Function InstSize(offset) As Long
	Function XRefsTo(offset)
	Function XRefsFrom(offset)
	Function GetName(offset)
	Function FunctionName(functionIndex)
	Function HideBlock(offset, leng)
	Function ShowBlock(offset, leng)
	Sub Setname(offset, name)
	Sub AddComment(offset, comment)
	Function GetComment(offset)
	Sub AddCodeXRef(offset, tova)
	Sub AddDataXRef(offset, tova)
	Sub DelCodeXRef(offset, tova)
	Sub DelDataXRef(offset, tova)
	Function FuncVAByName(name)
	Function RenameFunc(oldname, newName) As Boolean
	Function Find(startea, endea, hexstr) 
	Function Decompile(va) As String
	Function Jump(va As Long)
	Function JumpRVA(rva As Long)
	Function refresh()
	Function Undefine(offset)
	Function ShowEA(offset)
	Function HideEA(offset)
	Sub RemoveName(offset)
	Sub MakeCode(offset)
	Function FuncIndexFromVA(va)
	Function NextEA(va)
	Function PrevEA(va)
	Function funcCount() As Long
	Function NumFuncs() As Long
	Function FunctionStart(functionIndex)
	Function FunctionEnd(functionIndex)
	Function ReadByte(va)
	Function OriginalByte(va)
	Function ImageBase() As Long
	Function ScreenEA() As Long
	Function EnableIDADebugMessages( enabled)
	Function quickCall(msg, arg1) As Long
#	'Sub AddProgramComment(cmt)
#	' Function ScreenEA()
#	'Function GetAsmBlock(start, leng)
#	'Function GetBytes(start, leng)
#	'Sub AnalyzeArea(startat, endat)
	Function AskValue( prompt,  defVal) As String
	Sub Exec(cmd)
	Function ReadFile(filename) As Variant
	Sub WriteFile(path As String, it As Variant)
	Sub AppendFile(path, it)
	Function FileExists(path As String) As Boolean
	Function DeleteFile(fpath As String) As Boolean
	Function getClipboard()
	Function setClipboard(x)
	Function OpenFileDialog() As String
	Function SaveFileDialog() As String
	Function BenchMark() As Long
	Function isCode(va) as Long
	Function isData(va) as Long
	Function ReadLong(va) As Long
    Function ReadShort(va) As Long
    Function hexDump(x) As String
	Function hexstr(x) As String
	Function toBytes(hexstr) As String
	Sub clearDecompilerCache()
#	'Function refListToArray(x) As Long() 
#	'Function InstSize(offset)
*/

function idaClass(){

	this.hInst = 0

	this.caption = function(msg){
		return resolver('ida.Caption', arguments.length,0, msg);
	}

	this.do_events = function(){
		return resolver('ida.do_events', arguments.length,0);
	}
	
	this.alert = function(msg){
		return resolver('ida.alert', arguments.length,0, msg);
	}

	this.message = function(msg){
		return resolver('ida.Message', arguments.length,0, msg);
	}

	this.makeStr = function(va, ascii){
		return resolver('ida.MakeStr', arguments.length,0, va, ascii);
	}

	this.makeUnk = function(va, size){
		return resolver('ida.MakeUnk', arguments.length,0, va, size);
	}

	this.t = function(data){
		return resolver('ida.t', arguments.length,0, data);
	}

	this.clearLog = function(){
		return resolver('ida.ClearLog', arguments.length,0);
	}

	this.patchString = function(va, str, isUnicode){
		return resolver('ida.PatchString', arguments.length,0, va, str, isUnicode);
	}

	this.patchByte = function(va, newVal){
		return resolver('ida.PatchByte', arguments.length,0, va, newVal);
	}

	this.intToHex = function(x){
		return resolver('ida.intToHex', arguments.length,0, x);
	}

	this.getAsm = function(va){
		return resolver('ida.GetAsm', arguments.length,0, va);
	}

	this.instSize = function(offset){
		return resolver('ida.InstSize', arguments.length,0, offset);
	}

	this.isCode = function(offset){
		return resolver('ida.isCode', arguments.length,0, offset);
	}
	
	this.isData = function(offset){
		return resolver('ida.isData', arguments.length,0, offset);
	}
	
	this.xRefsTo = function(offset){
		return resolver('ida.XRefsTo', arguments.length,0, offset);
	}

	this.xRefsFrom = function(offset){
		return resolver('ida.XRefsFrom', arguments.length,0, offset);
	}

	this.getName = function(offset){
		return resolver('ida.GetName', arguments.length,0, offset);
	}

	this.functionName = function(functionIndex){
		return resolver('ida.FunctionName', arguments.length,0, functionIndex);
	}

	this.hideBlock = function(offset, leng){
		return resolver('ida.HideBlock', arguments.length,0, offset, leng);
	}

	this.showBlock = function(offset, leng){
		return resolver('ida.ShowBlock', arguments.length,0, offset, leng);
	}

	this.setname = function(offset, name){
		return resolver('ida.Setname', arguments.length,0, offset, name);
	}

	this.addComment = function(offset, comment){
		return resolver('ida.AddComment', arguments.length,0, offset, comment);
	}

	this.getComment = function(offset){
		return resolver('ida.GetComment', arguments.length,0, offset);
	}

	this.addCodeXRef = function(offset, tova){
		return resolver('ida.AddCodeXRef', arguments.length,0, offset, tova);
	}

	this.addDataXRef = function(offset, tova){
		return resolver('ida.AddDataXRef', arguments.length,0, offset, tova);
	}

	this.delCodeXRef = function(offset, tova){
		return resolver('ida.DelCodeXRef', arguments.length,0, offset, tova);
	}

	this.delDataXRef = function(offset, tova){
		return resolver('ida.DelDataXRef', arguments.length,0, offset, tova);
	}

	this.funcVAByName = function(name){
		return resolver('ida.FuncVAByName', arguments.length,0, name);
	}

	this.renameFunc = function(oldname, newName){
		return resolver('ida.RenameFunc', arguments.length,0, oldname, newName);
	}

	this.find = function(startea, endea, hexstr){
		return resolver('ida.Find', arguments.length,0, startea, endea, hexstr);
	}

	this.decompile = function(va){
		return resolver('ida.Decompile', arguments.length,0, va);
	}

	this.jump = function(va){
		return resolver('ida.Jump', arguments.length,0, va);
	}

	this.jumpRVA = function(rva){
		return resolver('ida.JumpRVA', arguments.length,0, rva);
	}

	this.refresh = function(){
		return resolver('ida.refresh', arguments.length,0);
	}

	this.undefine = function(offset){
		return resolver('ida.Undefine', arguments.length,0, offset);
	}

	this.showEA = function(offset){
		return resolver('ida.ShowEA', arguments.length,0, offset);
	}

	this.hideEA = function(offset){
		return resolver('ida.HideEA', arguments.length,0, offset);
	}

	this.removeName = function(offset){
		return resolver('ida.RemoveName', arguments.length,0, offset);
	}

	this.makeCode = function(offset){
		return resolver('ida.MakeCode', arguments.length,0, offset);
	}

	this.funcIndexFromVA = function(va){
		return resolver('ida.FuncIndexFromVA', arguments.length,0, va);
	}

	this.nextEA = function(va){
		return resolver('ida.NextEA', arguments.length,0, va);
	}

	this.prevEA = function(va){
		return resolver('ida.PrevEA', arguments.length,0, va);
	}

	this.funcCount = function(){
		return resolver('ida.funcCount', arguments.length,0);
	}

	this.numFuncs = function(){
		return resolver('ida.NumFuncs', arguments.length,0);
	}

	this.functionStart = function(functionIndex){
		return resolver('ida.FunctionStart', arguments.length,0, functionIndex);
	}

	this.functionEnd = function(functionIndex){
		return resolver('ida.FunctionEnd', arguments.length,0, functionIndex);
	}

	this.readByte = function(va){
		return resolver('ida.ReadByte', arguments.length,0, va);
	}

	this.readLong = function(va){
		return resolver('ida.ReadLong', arguments.length,0, va);
	}
	
	this.readShort = function(va){
		return resolver('ida.ReadShort', arguments.length,0, va);
	}
	
	this.originalByte = function(va){
		return resolver('ida.OriginalByte', arguments.length,0, va);
	}

	this.imageBase = function(){
		return resolver('ida.ImageBase', arguments.length,0);
	}

	this.screenEA = function(){
		return resolver('ida.ScreenEA', arguments.length,0);
	}

	this.enableIDADebugMessages = function(enabled){
		return resolver('ida.EnableIDADebugMessages', arguments.length,0, enabled);
	}

	this.quickCall = function(msg, arg1){
		//alert('in quickcall')
		return resolver('ida.quickCall', arguments.length,0, msg, arg1);
	}

	this.askValue = function(prompt, defVal){
		return resolver('ida.AskValue', arguments.length,0, prompt, defVal);
	}

	this.exec = function(cmd){
		return resolver('ida.Exec', arguments.length,0, cmd);
	}

	this.readFile = function(filename){
		return resolver('ida.ReadFile', arguments.length,0, filename);
	}

	this.writeFile = function(path, it){
		return resolver('ida.WriteFile', arguments.length,0, path, it);
	}

	this.appendFile = function(path, it){
		return resolver('ida.AppendFile', arguments.length,0, path, it);
	}

	this.fileExists = function(path){
		return resolver('ida.FileExists', arguments.length,0, path);
	}

	this.deleteFile = function(fpath){
		return resolver('ida.DeleteFile', arguments.length,0, fpath);
	}

	this.getClipboard = function(){
		return resolver('ida.getClipboard', arguments.length,0);
	}

	this.setClipboard = function(x){
		return resolver('ida.setClipboard', arguments.length,0, x);
	}

	this.openFileDialog = function(){
		return resolver('ida.OpenFileDialog', arguments.length,0);
	}

	this.saveFileDialog = function(){
		return resolver('ida.SaveFileDialog', arguments.length,0);
	}

	this.benchMark = function(){
		return resolver('ida.BenchMark', arguments.length,0);
	}
	
	this.clearDecompilerCache = function(){
		return resolver('ida.clearDecompilerCache', arguments.length,0);
	}
	
	this.hexDump = function(x){
		return resolver('ida.hexDump', arguments.length,0, x);
	}
	
	this.hexstr = function(x){
		return resolver('ida.hexstr', arguments.length,0, x);
	}
	
	this.toBytes = function(x){
		return resolver('ida.toBytes', arguments.length,0, x);
	}

}

idaClass.prototype = {
	get isUp(){
		return resolver('ida.isUp.get', 0, this.hInst);
	},

	/*set Enabled(val){
		return resolver('list.Enabled.let', 1, this.hInst, val);
	},*/

	get loadedFile(){
		return resolver('ida.LoadedFile.get', 0, this.hInst);
	},
	
	get timeout(){
		return resolver('ida.timeout.get', 0, this.hInst);
	},
	
	set timeout(val){
		return resolver('ida.timeout.let', 1, this.hInst, val);
	}
}

var ida = new idaClass()

