/*
	property let ip(x as string)
	property get ip() as string
	property get response() as string
	Function ScanProcess(pidOrName) As Boolean
	Function ResolveExport(apiOrAddress) As Boolean
*/

function remoteClass(){

	this.ScanProcess = function(pidOrName){
		return resolver('remote.ScanProcess', arguments.length,0, pidOrName);
	}

	this.ResolveExport = function(apiOrAddress){
		return resolver('remote.ResolveExport', arguments.length,0, apiOrAddress);
	}

}

remoteClass.prototype = {
	set ip(val){
		return resolver('remote.ip.let', 1,0, val);
	},

	get ip(){
		return resolver('remote.ip.get', 0,0);
	},

	get response(){
		return resolver('remote.response.get', 0,0);
	}
}

var remote = new remoteClass()

