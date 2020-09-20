/*
    Property get value As long
	Property let value As long
	Property let max As long
	Property get max As long
	function inc(x)
	function clear()
*/

function pbClass(){

	this.hInst = 0
	
	this.inc = function(x){
		if(x==undefined) x = 1;
		this.value += x 
	}
	
	this.clear = function(){ this.value = 0 }

}

pbClass.prototype = {
	
	set value(val){
		return resolver('pb.value.let', 1, this.hInst,val);
	},
    
	get value(){
		return resolver('pb.value.get', 0, this.hInst);
	},
	
	set max(val){
		return resolver('pb.max.let', 1, this.hInst, val);
	},
	
	get max(){
		return resolver('pb.max.get', 0, this.hInst);
	}
}

var pb = new pbClass()

