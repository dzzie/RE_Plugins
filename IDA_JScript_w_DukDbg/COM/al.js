/*
	Sub clear()
	Sub addAddr(addr,txt)
	Sub showList()
	Sub hideList()
*/

function alClass(){



	this.clear = function(){
		return resolver('al.clear', arguments.length,0);
	}

    //txt is optional
	this.addAddr = function(addr,txt){
		if(txt === undefined) txt = '';
		return resolver('al.addAddr', 2 ,0, addr,txt);
	}

	this.showList = function(){
		return resolver('al.showList', arguments.length,0);
	}

	this.hideList = function(){
		return resolver('al.hideList', arguments.length,0);
	}

}

var al = new alClass()

